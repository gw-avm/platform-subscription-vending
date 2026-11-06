output "subscription_id" {
  value = module.landing_zone.subscription_id
}

output "virtual_network_resource_ids" {
  value = module.landing_zone.virtual_network_resource_ids
}

output "deploy_identity_client_id" {
  value = module.landing_zone.umi_client_ids["deploy"]
}

# The app repo's backend settings.
output "app_state" {
  value = {
    resource_group_name  = "rg-apps-tfstate-${local.suffix}"
    storage_account_name = azapi_resource.app_state.name
    container_name       = azapi_resource.app_state_container.name
  }
}
