output "subscription_id" {
  value = module.landing_zone.subscription_id
}

output "virtual_network_resource_ids" {
  value = module.landing_zone.virtual_network_resource_ids
}

# --- App landing zone (null for a sandbox) -------------------------------------

output "deploy_identity_client_id" {
  value = var.app_landing_zone ? module.landing_zone.umi_client_ids["deploy"] : null
}

output "plan_identity_client_id" {
  value = var.app_landing_zone ? module.landing_zone.umi_client_ids["plan"] : null
}

# The app repo's backend settings.
output "app_state" {
  value = var.app_landing_zone ? {
    resource_group_name  = "rg-apps-tfstate-${local.suffix}"
    storage_account_name = azapi_resource.app_state.name
    container_name       = azapi_resource.app_state_container[0].name
  } : null
}

# --- Sandbox projects ----------------------------------------------------------
# What a project repo needs: where to deploy, the client ID for azure/login
# (with the tenant and this subscription ID), and its backend if it has one.

output "sandbox_projects" {
  value = {
    for k, p in local.sandbox_projects : k => {
      repository          = "${local.sandbox_project_repos[k].owner}/${local.sandbox_project_repos[k].name}"
      resource_group_name = "rg-${k}-${local.suffix}"
      client_id           = module.landing_zone.umi_client_ids["project-${k}"]
      expires_on          = p.expires_on
      terraform_state = p.terraform_state ? {
        resource_group_name  = "rg-sandbox-tfstate-${local.suffix}"
        storage_account_name = azapi_resource.app_state.name
        container_name       = azapi_resource.sandbox_state_container[k].name
        key                  = "${k}.tfstate"
      } : null
    }
  }
}
