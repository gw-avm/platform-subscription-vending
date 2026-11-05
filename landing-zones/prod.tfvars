# Check by ID, not name: the two app subscription names were swapped on 2026-11-04.
environment               = "prod"
subscription_id           = "89181bf2-9993-4138-8dd4-ccc27dc7250f"
subscription_display_name = "gw-apps-prod"

address_space = ["10.0.8.0/22"]

budget_amount         = 20
budget_contact_emails = ["graemewales13@gmail.com"]

tags = {
  app             = "apps"
  env             = "prod"
  region          = "eastasia"
  criticality     = "high"
  confidentiality = "private"
  businessunit    = "shared"
  opsteam         = "platform"
  repo            = "https://github.com/gw-avm/platform-subscription-vending"
  deployed_by     = "terraform"
}
