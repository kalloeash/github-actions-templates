# terraform-apply

Apply the exact plan that [terraform-plan](terraform-plan.md) saved. The job binds to a
caller-owned GitHub environment, so the consumer decides who approves an apply and from
which branch; the block carries no policy of its own. Locking stays on, with a timeout
instead of an immediate failure when another operation holds the lock, because an apply
is the one writer the lock exists for. The Azure and state firewall inputs work the same
way as in terraform-plan.

## Usage

A deploy workflow on pushes to main: a fresh plan, then a gated apply of that exact plan.
The apply job starts only after the environment's protection rules pass, and only when
the plan found changes, so a merge that changes nothing never wakes the reviewer:

```yaml
name: deploy
on:
  push:
    branches: [main]

permissions:
  contents: read

# Applies must run in merge order, never concurrently against one state.
concurrency:
  group: deploy-infra
  cancel-in-progress: false

jobs:
  plan:
    permissions:
      contents: read
      id-token: write
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-plan.yml@v0
    with:
      working-directory: infra
      backend-config: backend.hcl
      artifact-name: infra-plan
      lock: true
      azure-client-id: ${{ vars.AZURE_PLAN_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      state-storage-account: ${{ vars.STATE_STORAGE_ACCOUNT }}
      state-resource-group: ${{ vars.STATE_RESOURCE_GROUP }}

  apply:
    needs: plan
    if: needs.plan.outputs.changes == 'true'
    permissions:
      contents: read
      id-token: write
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-apply.yml@v0
    with:
      working-directory: infra
      backend-config: backend.hcl
      artifact-name: infra-plan
      environment: azure
      azure-client-id: ${{ vars.AZURE_APPLY_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      state-storage-account: ${{ vars.STATE_STORAGE_ACCOUNT }}
      state-resource-group: ${{ vars.STATE_RESOURCE_GROUP }}
```

The environment (here `azure`) is configured in the consuming repository: required
reviewers, and a deployment branch policy restricted to `main`. Required reviewers are
available for public repositories on every plan; private repositories need GitHub
Enterprise for them.

## Azure OIDC prerequisites

Same shape as in [terraform-plan](terraform-plan.md), with two differences for the apply
identity. The federated credential subject names the environment instead of pull
requests, so Azure only issues a token to jobs that passed the environment gate, and the
roles allow writing:

```hcl
resource "azurerm_federated_identity_credential" "github_apply_environment" {
  name                = "github-environment-azure"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.github_apply.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:OWNER/REPO:environment:azure"
}
```

The apply identity holds `Contributor` on the scope it manages and
`Storage Blob Data Contributor` on the state container, plus the same single-account
firewall role when the firewall inputs are used.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `working-directory` | `.` | Root configuration directory to apply. Must match the plan. |
| `terraform-version` | `1.15.8` | Terraform version passed to setup-terraform. Use the version that produced the plan. |
| `backend-config` | empty | Backend config file passed to `init`, relative to `working-directory`. Empty skips the flag. |
| `artifact-name` | required | Name of the plan artifact uploaded by terraform-plan in the same run. |
| `environment` | required | GitHub environment the apply job binds to. The consumer owns the environment and its protection rules. |
| `lock-timeout` | `300s` | How long the apply waits for a busy state lock before failing. |
| `azure-client-id` | empty | Client id of the Azure identity for the OIDC login. Set all three azure inputs together or not at all. |
| `azure-tenant-id` | empty | Tenant id for the OIDC login. |
| `azure-subscription-id` | empty | Subscription id for the OIDC login. |
| `state-storage-account` | empty | State storage account whose firewall denies GitHub runners. The job allows its own IP before init and removes it afterwards. Needs the azure inputs and `state-resource-group`. |
| `state-resource-group` | empty | Resource group of the state storage account. Required with `state-storage-account`. |
| `state-container` | `tfstate` | Blob container holding the state, used to verify the firewall rule is effective before init runs. |

## Permissions

Inherits the caller's `GITHUB_TOKEN`. Grant `contents: read`; add `id-token: write` on the
calling job when the azure inputs are set, because the OIDC login mints a token. The block
declares no fixed permissions because a called workflow that requests more than the caller
granted fails the run at startup.

## Notes

- The job applies the saved binary plan, so what was reviewed is what runs; Terraform
  refuses a plan whose state has moved since it was created. Pass the artifact from the
  plan job of the same workflow run, as in the example.
- Terraform validates a saved plan against the configuration and provider versions that
  produced it. Keep `working-directory`, `backend-config`, and `terraform-version`
  identical between the plan and apply calls.
- Referencing an environment that does not exist yet creates it without protection
  rules. Configure the environment before the first real deploy, and verify the settings
  landed rather than trusting the save button.
- The state lock stays on and `lock-timeout` makes queued applies wait instead of
  failing; pair it with the caller-level `concurrency` group shown above so applies run
  in merge order.
- The firewall handling, the fork limitation, and the same-region caveat are the same as
  in [terraform-plan](terraform-plan.md); the notes there apply unchanged.
