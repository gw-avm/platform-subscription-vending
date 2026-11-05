output "subscription_id" {
  value = module.landing_zone.subscription_id
}

output "virtual_network_resource_ids" {
  value = module.landing_zone.virtual_network_resource_ids
}

output "deploy_identity_client_id" {
  value = module.landing_zone.umi_client_ids["deploy"]
}
