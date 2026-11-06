variable "environment" {
  description = "Landing zone environment, used in resource names: nonprod or prod."
  type        = string

  validation {
    condition     = contains(["nonprod", "prod"], var.environment)
    error_message = "environment must be nonprod or prod."
  }
}

variable "location" {
  type    = string
  default = "eastasia"
}

variable "subscription_id" {
  description = "Existing subscription to vend. Pay-As-You-Go can't create subscriptions in code."
  type        = string
}

variable "subscription_display_name" {
  description = "Kept in code so the name can't drift from the ID again."
  type        = string
}

variable "management_group_id" {
  type    = string
  default = "online"
}

variable "hub_virtual_network_id" {
  type    = string
  default = "/subscriptions/ce882887-4b87-4377-bc63-076ec3c22a85/resourceGroups/rg-connectivity-hub-prod-eastasia-001/providers/Microsoft.Network/virtualNetworks/vnet-connectivity-hub-prod-eastasia-001"
}

variable "address_space" {
  description = "Spoke VNet range. Must not overlap the hub (10.0.0.0/22) or other spokes."
  type        = list(string)
}

variable "app_repository" {
  description = "GitHub repo that deploys into this landing zone. IDs from: gh api repos/<owner>/<name> (.owner.id, .id)."
  type = object({
    owner    = string
    owner_id = number
    name     = string
    repo_id  = number
  })
  default = {
    owner    = "gw-avm"
    owner_id = 351889910
    name     = "gw-webapp"
    repo_id  = 1437058694
  }
}

variable "postgres_private_dns_zone_id" {
  description = "The platform's central privatelink.postgres.database.azure.com zone."
  type        = string
  default     = "/subscriptions/ce882887-4b87-4377-bc63-076ec3c22a85/resourceGroups/rg-connectivity-dns-prod-eastasia-001/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
}

variable "budget_amount" {
  description = "Monthly budget in the billing currency (GBP)."
  type        = number
}

variable "budget_contact_emails" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}
