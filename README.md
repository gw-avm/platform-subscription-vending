# platform-subscription-vending

Subscription vending for the gw landing zones, using Microsoft's
[`avm-ptn-alz-sub-vending`](https://registry.terraform.io/modules/Azure/avm-ptn-alz-sub-vending/azure) module.

Each file in `landing-zones/` is one landing zone with its own state file
(`<name>.tfstate`). Vending:

- places the subscription in the `online` management group
- sets its display name and tags
- creates an empty spoke VNet peered to the hub (the app creates its own subnets)
- creates a monthly budget with email alerts at 50, 80 and 100%
- creates the app pipeline's managed identity with Contributor on the subscription

## Changing a landing zone

1. Branch (`feat/`, `fix/` or `docs/`), edit or add `landing-zones/<name>.tfvars`, open a PR.
2. CI validates and plans every landing zone.
3. Merge: CD plans again, then each apply waits for approval on `vending-prod-apply`.

A new subscription also needs adding to the vending bootstrap, so the apply
identity gets Owner on it.
