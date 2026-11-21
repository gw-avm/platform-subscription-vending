# Sandbox landing zone: one shared subscription for learning-factory projects.
# Azure can't vend a subscription per project here, so each project gets what
# an AWS sandbox account gives it, scoped to its own resource group:
#
#   - rg-<project>-<env>-<region>-001, tagged project and expires-on
#   - a deploy identity with rights on that resource group only, trusting
#     pushes to main in the project's GitHub repo
#   - a monthly budget on that resource group
#   - optionally, a Terraform state container (Bicep and HCP state need none)
#
# Add a project: an entry in sandbox_projects. Close it: tear the project
# down, then remove the entry, which deletes its resource group and anything
# left in it.
#
# Everything here is empty for an app landing zone.

locals {
  sandbox_projects = local.sandbox ? var.sandbox_projects : {}

  sandbox_project_repos = {
    for k, p in local.sandbox_projects : k => {
      owner = p.repository_owner
      name  = coalesce(p.repository_name, k)
    }
  }

  sandbox_project_tags = {
    for k, p in local.sandbox_projects : k => merge(var.tags, {
      app          = k
      project      = k
      "expires-on" = p.expires_on
    })
  }

  # Shared groups. Identities sit outside the project groups so a project
  # can't delete its own identity along with its resources.
  sandbox_resource_groups = merge(
    { for k, v in {
      identity = {
        name = "rg-sandbox-identity-${local.suffix}"
        tags = var.tags
      }
      tfstate = {
        name = "rg-sandbox-tfstate-${local.suffix}"
        tags = var.tags
      }
    } : k => v if local.sandbox },
    {
      for k, p in local.sandbox_projects : "project-${k}" => {
        name = "rg-${k}-${local.suffix}"
        tags = local.sandbox_project_tags[k]
      }
    },
  )

  sandbox_identities = {
    for k, p in local.sandbox_projects : "project-${k}" => {
      name               = "id-${k}-deploy-${local.suffix}"
      resource_group_key = "identity"
      tags               = local.sandbox_project_tags[k]
      role_assignments = {
        contributor = {
          definition               = "Contributor"
          resource_group_scope_key = "project-${k}"
        }
        # Lets the project give its own resources access (managed identities,
        # AcrPull and so on) without being able to hand out admin rights.
        constrained_rbac_admin = {
          definition               = "/providers/Microsoft.Authorization/roleDefinitions/f58310d9-a9f6-439a-9e8d-f62e7b41a168" # Role Based Access Control Administrator
          resource_group_scope_key = "project-${k}"
          condition                = local.sandbox_assignable_roles_condition
          condition_version        = "2.0"
        }
      }
      # GitHub's default subject (project repos are personal, not in gw-avm,
      # so there's no org-wide immutable subject). GitHub Free has no
      # environments, so the trust is pushes and dispatches on main.
      federated_credentials_advanced = {
        main = {
          name               = "github-${local.sandbox_project_repos[k].owner}-${local.sandbox_project_repos[k].name}-main"
          subject_identifier = "repo:${local.sandbox_project_repos[k].owner}/${local.sandbox_project_repos[k].name}:ref:refs/heads/main"
          issuer_url         = "https://token.actions.githubusercontent.com"
        }
      }
    }
  }

  sandbox_project_budgets = {
    for k, p in local.sandbox_projects : "project-${k}" => merge(local.budget_defaults, {
      name               = "budget-${k}-${local.suffix}"
      amount             = p.budget_amount
      resource_group_key = "project-${k}"
    })
  }

  # Microsoft's "assign all roles except privileged administrator roles"
  # condition: Owner, User Access Administrator and RBAC Administrator.
  sandbox_privileged_role_ids = join(", ", [
    "8e3af657-a8ff-443c-a75c-2fe8c4bcb635", # Owner
    "18d7d88d-d35e-4fb5-a5c3-7773c20a72d9", # User Access Administrator
    "f58310d9-a9f6-439a-9e8d-f62e7b41a168", # Role Based Access Control Administrator
  ])

  sandbox_assignable_roles_condition = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {${local.sandbox_privileged_role_ids}}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {${local.sandbox_privileged_role_ids}}
     )
    )
  EOT

  sandbox_state_projects = { for k, p in local.sandbox_projects : k => p if p.terraform_state }

  # Registered once for the whole subscription, because project identities
  # can't. The module's default list includes retired services and misses
  # current ones (Container Apps), so this is a learning-project set. Add to
  # it when a project needs another.
  sandbox_resource_providers = {
    for rp in [
      "Microsoft.AlertsManagement",
      "Microsoft.ApiManagement",
      "Microsoft.App",
      "Microsoft.AppConfiguration",
      "Microsoft.Cache",
      "Microsoft.Cdn",
      "Microsoft.CognitiveServices",
      "Microsoft.Compute",
      "Microsoft.ContainerInstance",
      "Microsoft.ContainerRegistry",
      "Microsoft.ContainerService",
      "Microsoft.DataFactory",
      "Microsoft.DataProtection",
      "Microsoft.DBforMySQL",
      "Microsoft.DBforPostgreSQL",
      "Microsoft.DocumentDB",
      "Microsoft.EventGrid",
      "Microsoft.EventHub",
      "Microsoft.GuestConfiguration",
      "Microsoft.Insights",
      "Microsoft.KeyVault",
      "Microsoft.Logic",
      "Microsoft.MachineLearningServices",
      "Microsoft.ManagedIdentity",
      "Microsoft.Monitor",
      "Microsoft.Network",
      "Microsoft.OperationalInsights",
      "Microsoft.OperationsManagement",
      "Microsoft.PolicyInsights",
      "Microsoft.RecoveryServices",
      "Microsoft.Search",
      "Microsoft.Security",
      "Microsoft.ServiceBus",
      "Microsoft.SignalRService",
      "Microsoft.Sql",
      "Microsoft.Storage",
      "Microsoft.Web",
    ] : rp => toset([])
  }
}

# --- Project Terraform state ---------------------------------------------------
# One container per project in the shared state account (app-access.tf), and
# each project's identity can only reach its own container.

resource "azapi_resource" "sandbox_state_container" {
  for_each = local.sandbox_state_projects

  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01"
  name      = each.key
  parent_id = "${azapi_resource.app_state.id}/blobServices/default"

  body = {
    properties = {
      publicAccess = "None"
    }
  }

  depends_on = [azapi_update_resource.app_state_blob_service]
}

resource "azapi_resource" "sandbox_state_access" {
  for_each = local.sandbox_state_projects

  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${azapi_resource.sandbox_state_container[each.key].id}/deploy/state")
  parent_id = azapi_resource.sandbox_state_container[each.key].id

  body = {
    properties = {
      principalId      = module.landing_zone.umi_principal_ids["project-${each.key}"]
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe" # Storage Blob Data Contributor
    }
  }
}
