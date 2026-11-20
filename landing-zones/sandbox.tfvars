# Sandbox: placement, name, tags and budget only. No spoke, app identities or
# state; the sandbox guardrails deny peering to the hub.
app_landing_zone          = false
workload                  = "sandbox"
environment               = "dev"
subscription_id           = "8d9fcd1d-99d7-4dbf-b0ad-d35d19fae8fa"
subscription_display_name = "gw-sandbox"
management_group_id       = "sandbox"

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
