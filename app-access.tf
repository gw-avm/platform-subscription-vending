# What the app's deploy identity needs beyond Contributor: its own Terraform
# state, a limited right to assign roles, and a record in the platform's
# central PostgreSQL DNS zone.

locals {
  # The only roles the app may assign in its subscription.
  app_assignable_role_ids = [
    "7f951dda-4ed3-4680-a7ca-43fe172d538d", # AcrPull
    "8311e382-0749-4cb8-b61a-304f252e45ec", # AcrPush
    "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1", # Storage Blob Data Reader
    "ba92f5b4-2d11-453d-a403-e96b0029c9fe", # Storage Blob Data Contributor
    "9980e02c-c2be-4d73-94e8-173b1dc7cf3c", # Virtual Machine Contributor
    "358470bc-b998-42bd-ab17-a7e34c199c0f", # Container Apps Contributor
    "acdd72a7-3385-48ef-bd42-f606fba81ae7", # Reader
  ]

  # Microsoft's "constrain roles" condition: write and delete are allowed
  # only for the roles above.
  app_assignable_roles_condition = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(", ", local.app_assignable_role_ids)}}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(", ", local.app_assignable_role_ids)}}
     )
    )
  EOT
}

# --- App Terraform state -----------------------------------------------------
# Same hardening as the platform and vending state accounts: Entra ID only,
# no keys, ZRS, versioning and soft delete.

resource "azapi_resource" "app_state" {
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = "stgwapps${var.environment}tf001"
  parent_id = module.landing_zone.resource_group_resource_ids["tfstate"]
  location  = var.location
  tags      = var.tags

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_ZRS"
    }
    properties = {
      allowSharedKeyAccess         = false
      allowBlobPublicAccess        = false
      defaultToOAuthAuthentication = true
      minimumTlsVersion            = "TLS1_2"
      supportsHttpsTrafficOnly     = true
      publicNetworkAccess          = "Enabled" # GitHub-hosted runners reach it over the internet
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Azure creates the "default" blob service with the account, so this updates
# it rather than creating it.
resource "azapi_update_resource" "app_state_blob_service" {
  type        = "Microsoft.Storage/storageAccounts/blobServices@2023-05-01"
  resource_id = "${azapi_resource.app_state.id}/blobServices/default"

  body = {
    properties = {
      isVersioningEnabled = true
      deleteRetentionPolicy = {
        enabled = true
        days    = 7
      }
      containerDeleteRetentionPolicy = {
        enabled = true
        days    = 7
      }
    }
  }
}

resource "azapi_resource" "app_state_container" {
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01"
  name      = "tfstate"
  parent_id = "${azapi_resource.app_state.id}/blobServices/default"

  body = {
    properties = {
      publicAccess = "None"
    }
  }

  # Versioning and soft delete are on before the container exists.
  depends_on = [azapi_update_resource.app_state_blob_service]
}

# --- Role assignments outside the module ---------------------------------------
# The module only scopes role assignments inside the landing zone subscription
# and can't depend on the container, so these two are created directly.

locals {
  deploy_principal_id = module.landing_zone.umi_principal_ids["deploy"]
}

resource "azapi_resource" "deploy_state_access" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${azapi_resource.app_state_container.id}/deploy/state")
  parent_id = azapi_resource.app_state_container.id

  body = {
    properties = {
      principalId      = local.deploy_principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe" # Storage Blob Data Contributor
    }
  }
}

# The vending bootstrap lets the apply identity grant only this role on this
# one zone.
resource "azapi_resource" "deploy_dns_zone_access" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${var.postgres_private_dns_zone_id}/${var.subscription_id}/deploy")
  parent_id = var.postgres_private_dns_zone_id

  body = {
    properties = {
      principalId      = local.deploy_principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = "${split("/resourceGroups/", var.postgres_private_dns_zone_id)[0]}/providers/Microsoft.Authorization/roleDefinitions/b12aa53e-6015-4669-85d0-8515ebb3ae7f" # Private DNS Zone Contributor
    }
  }
}
