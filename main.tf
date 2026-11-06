locals {
  # CAF: <type>-<workload>-<component>-<environment>-<region>-<###>
  suffix = "${var.environment}-${var.location}-001"
}

module "landing_zone" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = "0.3.4"

  location         = var.location
  enable_telemetry = false

  # Existing subscription: move it into its management group and keep its
  # display name and tags in code.
  subscription_id                                   = var.subscription_id
  subscription_management_group_association_enabled = true
  subscription_management_group_id                  = var.management_group_id
  subscription_update_existing                      = true
  subscription_display_name                         = var.subscription_display_name
  subscription_tags                                 = var.tags

  resource_group_creation_enabled = true
  resource_groups = {
    network = {
      name = "rg-apps-network-${local.suffix}"
      tags = var.tags
    }
    identity = {
      name = "rg-apps-identity-${local.suffix}"
      tags = var.tags
    }
    tfstate = {
      name = "rg-apps-tfstate-${local.suffix}"
      tags = var.tags
    }
  }

  # Vending creates the empty spoke and its hub peering; the app repo creates
  # subnets (each with an NSG, which policy requires on landingzones).
  virtual_network_enabled = true
  virtual_networks = {
    spoke = {
      name               = "vnet-apps-${local.suffix}"
      address_space      = var.address_space
      resource_group_key = "network"
      tags               = var.tags

      hub_network_resource_id  = var.hub_virtual_network_id
      hub_peering_enabled      = true
      hub_peering_name_tohub   = "peer-vnet-apps-${local.suffix}-to-hub"
      hub_peering_name_fromhub = "peer-hub-to-vnet-apps-${local.suffix}"
      # The hub has no VPN/ExpressRoute gateway, so neither side may use one.
      hub_peering_options_tohub = {
        use_remote_gateways = false
      }
      hub_peering_options_fromhub = {
        allow_gateway_transit = false
      }
    }
  }

  # Alerts only: Pay-As-You-Go budgets can't stop spending.
  budget_enabled = true
  budgets = {
    monthly = {
      name              = "budget-apps-${local.suffix}"
      amount            = var.budget_amount
      time_grain        = "Monthly"
      time_period_start = "2026-11-01T00:00:00Z"
      time_period_end   = "2031-10-31T00:00:00Z"
      notifications = {
        for threshold in [50, 80, 100] : "actual_${threshold}" => {
          enabled        = true
          operator       = "GreaterThanOrEqualTo"
          threshold      = threshold
          threshold_type = "Actual"
          contact_emails = var.budget_contact_emails
        }
      }
    }
  }

  # The app pipeline's identity. It only trusts jobs in the app repo's GitHub
  # environment of the same name, so nonprod runs can't log in to prod.
  umi_enabled = true
  user_managed_identities = {
    deploy = {
      name               = "id-apps-deploy-${local.suffix}"
      resource_group_key = "identity"
      tags               = var.tags
      role_assignments = {
        subscription_contributor = {
          definition = "Contributor"
        }
        # Contributor can't create role assignments, and the app needs a few
        # (AcrPull for the container app, blob access for the VM). This lets
        # it grant only the roles in local.app_assignable_role_ids.
        subscription_constrained_rbac_admin = {
          definition        = "/providers/Microsoft.Authorization/roleDefinitions/f58310d9-a9f6-439a-9e8d-f62e7b41a168" # Role Based Access Control Administrator
          condition         = local.app_assignable_roles_condition
          condition_version = "2.0"
        }
      }
      # "advanced" because GitHub issues immutable subjects (owner and repo IDs
      # as well as names), which the module's GitHub option doesn't build.
      federated_credentials_advanced = {
        app = {
          name               = "github-${var.app_repository.owner}-${var.app_repository.name}-${var.environment}"
          subject_identifier = "repo:${var.app_repository.owner}@${var.app_repository.owner_id}/${var.app_repository.name}@${var.app_repository.repo_id}:environment:${var.environment}"
          issuer_url         = "https://token.actions.githubusercontent.com"
        }
      }
    }

    # Read-only identity for plans on pull requests, the same split as the
    # platform and vending pipelines. Trusts the app repo's <env>-plan
    # environment, which (unlike <env>) any branch can use.
    plan = {
      name               = "id-apps-plan-${local.suffix}"
      resource_group_key = "identity"
      tags               = var.tags
      role_assignments = {
        subscription_reader = {
          definition = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader
        }
      }
      federated_credentials_advanced = {
        app = {
          name               = "github-${var.app_repository.owner}-${var.app_repository.name}-${var.environment}-plan"
          subject_identifier = "repo:${var.app_repository.owner}@${var.app_repository.owner_id}/${var.app_repository.name}@${var.app_repository.repo_id}:environment:${var.environment}-plan"
          issuer_url         = "https://token.actions.githubusercontent.com"
        }
      }
    }
  }
}
