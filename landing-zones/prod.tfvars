# The subscription ID comes from the SUBSCRIPTION_ID_PROD secret (check by ID, not name:
# the two app subscription names were swapped on 2026-11-04). Budget alerts go
# to the BUDGET_CONTACT_EMAIL secret.
environment               = "prod"
subscription_display_name = "gw-apps-prod"

address_space = ["10.0.8.0/22"]

budget_amount = 20

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
