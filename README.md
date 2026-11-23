# platform-subscription-vending

Subscription vending for the gw landing zones, using Microsoft's
[`avm-ptn-alz-sub-vending`](https://registry.terraform.io/modules/Azure/avm-ptn-alz-sub-vending/azure) module.

Each file in `landing-zones/` is one landing zone with its own state file
(`<name>.tfstate`). For an app landing zone (`nonprod`, `prod`), vending:

- places the subscription in the `online` management group
- sets its display name and tags
- creates an empty spoke VNet peered to the hub (the app creates its own subnets)
- creates a monthly budget with email alerts at 50, 80 and 100%
- creates the app pipeline's managed identity with Contributor on the subscription

## Sandbox

`sandbox` is one shared subscription (`gw-sandbox`, in the `sandbox` management
group) for learning-factory projects. Azure can't give each project its own
subscription here, so each project gets the equivalent of an AWS sandbox
account, scoped to a resource group:

| | Per project | Shared |
|---|---|---|
| Resource group | `rg-<project>-dev-eastasia-001`, tagged `project` and `expires-on` | `rg-sandbox-identity-…`, `rg-sandbox-tfstate-…` |
| Identity | `id-<project>-deploy-…`: Contributor on its resource group, plus RBAC Administrator for any role except Owner, User Access Administrator and RBAC Administrator. Trusts `repo:<owner>/<repo>:ref:refs/heads/main` | |
| Budget | Monthly on the resource group (default £10) | £20 on the subscription |
| Terraform state | Optional container in `stgwsandboxdevtf001` (`terraform_state = true`) | The storage account |
| Resource providers | | A common set, registered once (`sandbox.tf`) |

There's no network: the sandbox guardrails deny peering to the hub.

To **add a project**, add an entry to `sandbox_projects` in
`landing-zones/sandbox.tfvars` and open a PR. After the apply, the
`sandbox_projects` output gives the project repo its resource group, client ID
and backend. Repos default to `graemewales13/<project>`.

To **close a project**, run its teardown first, then remove its entry. The
apply deletes its resource group (with anything left in it), identity, budget
and state container.

Projects share the subscription, so anything at subscription scope (policy,
quotas, Defender, provider registration) is shared too. Projects must stay
inside their resource group.

## Changing a landing zone

1. Branch (`feat/`, `fix/` or `docs/`), edit or add `landing-zones/<name>.tfvars`, open a PR.
2. CI validates and plans every landing zone.
3. Merge: CD plans again, then each apply waits for approval on `vending-prod-apply`.

Subscription IDs and the budget email are repository secrets, not files, so
they're masked in this public repo's logs: `SUBSCRIPTION_ID_<NAME>` for each
landing zone (e.g. `SUBSCRIPTION_ID_PROD`), `SUBSCRIPTION_ID_CONNECTIVITY` (the
hub and DNS zones), `BUDGET_CONTACT_EMAIL`, the `AZURE_*` sign-in IDs, and
`PLAN_ENCRYPTION_KEY` (saved plans are published encrypted). A new landing
zone needs its `SUBSCRIPTION_ID_<NAME>` secret before its first plan.

A new subscription also needs adding to the vending bootstrap, so the apply
identity gets Owner on it, and Management Group Contributor on its management
group if that's a new one.
