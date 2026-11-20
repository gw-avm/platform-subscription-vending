output "subscription_id" {
  value = module.landing_zone.subscription_id
}

output "virtual_network_resource_ids" {
  value = module.landing_zone.virtual_network_resource_ids
}

# The rest are null for a sandbox, which has no app identities or state.

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
    storage_account_name = azapi_resource.app_state[0].name
    container_name       = azapi_resource.app_state_container[0].name
  } : null
}
