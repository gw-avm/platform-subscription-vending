variable "app_landing_zone" {
  description = "true: the gw-webapp landing zone (spoke VNet, app identities, state, DNS access). false: the shared sandbox, with a resource group per entry in sandbox_projects."
  type        = bool
  default     = true
}

variable "sandbox_projects" {
  description = <<-EOT
    Sandbox projects, keyed by project slug (also its resource group, identity,
    budget and state container name). Sandbox only.
    - repository_owner / repository_name: the GitHub repo whose pushes and
      dispatches on main may deploy. Defaults: graemewales13 / the key.
    - expires_on: YYYY-MM-DD, the project's expires-on tag.
    - budget_amount: monthly budget for the resource group, in GBP.
    - terraform_state: true for a container in the shared state account. Leave
      false for Bicep, or Terraform with HCP state.
  EOT
  type = map(object({
    repository_owner = optional(string, "graemewales13")
    repository_name  = optional(string)
    expires_on       = string
    budget_amount    = optional(number, 10)
    terraform_state  = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.sandbox_projects) : can(regex("^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$", k))])
    error_message = "Project keys must be 3-40 lowercase letters, digits and hyphens, starting and ending with a letter or digit."
  }

  validation {
    condition     = alltrue([for p in values(var.sandbox_projects) : can(regex("^\\d{4}-\\d{2}-\\d{2}$", p.expires_on)) && can(formatdate("YYYY", "${p.expires_on}T00:00:00Z"))])
    error_message = "expires_on must be a date in the form YYYY-MM-DD."
  }

  validation {
    condition     = var.app_landing_zone == false || length(var.sandbox_projects) == 0
    error_message = "sandbox_projects is for the sandbox landing zone only."
  }
}

variable "workload" {
  description = "Workload name in resource names, e.g. budget-<workload>-<environment>-<region>-001."
  type        = string
  default     = "apps"
}

variable "environment" {
  description = "Landing zone environment, used in resource names: dev, nonprod or prod."
  type        = string

  validation {
    condition     = contains(["dev", "nonprod", "prod"], var.environment)
    error_message = "environment must be dev, nonprod or prod."
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
  description = "Spoke VNet range. Must not overlap the hub (10.0.0.0/22) or other spokes. App landing zones only."
  type        = list(string)
  default     = null

  validation {
    condition     = !var.app_landing_zone || var.address_space != null
    error_message = "App landing zones need an address_space."
  }
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
