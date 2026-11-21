# Shared sandbox for learning-factory projects: one resource group, deploy
# identity and budget per project (see sandbox.tf). No network: the sandbox
# guardrails deny peering to the hub.
app_landing_zone          = false
workload                  = "sandbox"
environment               = "dev"
subscription_id           = "8d9fcd1d-99d7-4dbf-b0ad-d35d19fae8fa"
subscription_display_name = "gw-sandbox"
management_group_id       = "sandbox"

# The whole subscription. Each project also has its own budget.
budget_amount         = 20
budget_contact_emails = ["graemewales13@gmail.com"]

tags = {
  app             = "sandbox"
  env             = "dev"
  region          = "eastasia"
  criticality     = "low"
  confidentiality = "private"
  businessunit    = "shared"
  opsteam         = "platform"
  repo            = "https://github.com/gw-avm/platform-subscription-vending"
  deployed_by     = "terraform"
}

# Add a project with an entry here; remove it (after the project's teardown)
# to delete its resource group, identity and budget. Example:
#
#   my-project = {
#     expires_on      = "2027-02-19"
#     budget_amount   = 10    # optional, GBP a month
#     terraform_state = true  # optional, false for Bicep or HCP state
#   }
sandbox_projects = {}
