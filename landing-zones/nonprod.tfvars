# Check by ID, not name: the two app subscription names were swapped on 2026-11-04.
environment               = "nonprod"
subscription_id           = "99ebe116-0532-43e3-bcf3-7a0b2a77bbcc"
subscription_display_name = "gw-apps-nonprod"

address_space = ["10.0.4.0/22"]

budget_amount         = 20
budget_contact_emails = ["graemewales13@gmail.com"]

tags = {
  app             = "apps"
  env             = "nonprod"
  region          = "eastasia"
  criticality     = "low"
  confidentiality = "private"
  businessunit    = "shared"
  opsteam         = "platform"
  repo            = "https://github.com/gw-avm/platform-subscription-vending"
  deployed_by     = "terraform"
}
