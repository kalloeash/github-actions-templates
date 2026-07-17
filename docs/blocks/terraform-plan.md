# terraform-plan

Initialize a root configuration and produce a Terraform plan. Read-only by default: the
state lock stays off because a speculative plan on a pull request only reads state, and
locking would make parallel pull-request plans queue behind each other for nothing. The
plan output lands in the job step summary. When `artifact-name` is set the binary plan
file is uploaded, so [terraform-apply](terraform-apply.md) can apply exactly what was
reviewed. The Azure inputs are optional: when set, the job logs in with OIDC workload
identity federation, no stored secrets, and can hold open a just-in-time firewall rule on
the state storage account for the duration of the job.

## Usage

A plan gate on pull requests, local or credential-free configurations:

```yaml
name: pr
on:
  pull_request:

permissions:
  contents: read

jobs:
  plan:
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-plan.yml@v0
    with:
      working-directory: infra
```

A plan against Azure remote state with OIDC, including the firewall inputs for a state
storage account that denies public network access. The identifiers are repository
variables, not secrets; none of them is sensitive. The `if` keeps the job off pull
requests from forks, which never receive an OIDC token:

```yaml
name: pr
on:
  pull_request:

permissions:
  contents: read

jobs:
  plan:
    if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository
    permissions:
      contents: read
      id-token: write
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-plan.yml@v0
    with:
      working-directory: infra
      backend-config: backend.hcl
      azure-client-id: ${{ vars.AZURE_PLAN_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      state-storage-account: ${{ vars.STATE_STORAGE_ACCOUNT }}
      state-resource-group: ${{ vars.STATE_RESOURCE_GROUP }}
```

Two root configurations that share one state storage account must chain their plan jobs
with `needs:`. The firewall rule is a single list on the account, and concurrent edits
overwrite each other:

```yaml
jobs:
  plan-infra:
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-plan.yml@v0
    with:
      working-directory: infra
      # azure and state inputs as above
  plan-aks:
    needs: plan-infra
    uses: kalloeash/github-actions-templates/.github/workflows/terraform-plan.yml@v0
    with:
      working-directory: aks
      # azure and state inputs as above
```

## Azure OIDC prerequisites

The identity the job logs in as is plain Terraform, created once per consuming
repository. A user-assigned managed identity carries no client secret at all; the
federated credential ties it to pull request runs of one repository and nothing else:

```hcl
resource "azurerm_user_assigned_identity" "github_plan" {
  name                = "id-github-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_federated_identity_credential" "github_plan_pr" {
  name                = "github-pull-request"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.github_plan.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:OWNER/REPO:pull_request"
}

# principal_type skips the directory replication check, which otherwise fails
# assignments created right after the identity.
resource "azurerm_role_assignment" "github_plan_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.github_plan.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_plan_state_reader" {
  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.github_plan.principal_id
  principal_type       = "ServicePrincipal"
}
```

A read-only plan runs with `Reader` plus `Storage Blob Data Reader`; the identity cannot
take the state lock, cannot write state, and cannot change infrastructure. When the
firewall inputs are used, the identity also needs one management-plane write on the
storage account itself, because network rules are a property of the account. Scope it to
that single resource:

```hcl
resource "azurerm_role_definition" "state_firewall" {
  name  = "state-firewall-rule-writer"
  scope = azurerm_storage_account.tfstate.id
  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/write",
    ]
  }
  assignable_scopes = [azurerm_storage_account.tfstate.id]
}

resource "azurerm_role_assignment" "github_plan_state_firewall" {
  scope              = azurerm_storage_account.tfstate.id
  role_definition_id = azurerm_role_definition.state_firewall.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.github_plan.principal_id
  principal_type     = "ServicePrincipal"
}
```

Azure rejects concurrent federated credential writes on one identity; when an identity
gets more than one credential, chain them with `depends_on`. Role assignments can take a
few minutes to become effective, so the first workflow run after creating them may need
one retry.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `working-directory` | `.` | Root configuration directory to plan. |
| `terraform-version` | `1.15.8` | Terraform version passed to setup-terraform. Pinned in the block, bumped centrally; override to match your project. |
| `backend-config` | empty | Backend config file passed to `init`, relative to `working-directory`. Empty skips the flag. |
| `lock` | `false` | Take the state lock during plan. A speculative plan only reads state; turn it on when the plan feeds an apply that must not race another writer. |
| `artifact-name` | empty | When set, the plan is saved with `-out` and uploaded as an artifact under this name for terraform-apply. |
| `artifact-retention-days` | `1` | Retention for the plan artifact. Short by default because plan files can contain sensitive values in clear text. |
| `azure-client-id` | empty | Client id of the Azure identity for the OIDC login. Set all three azure inputs together or not at all. |
| `azure-tenant-id` | empty | Tenant id for the OIDC login. |
| `azure-subscription-id` | empty | Subscription id for the OIDC login. |
| `state-storage-account` | empty | State storage account whose firewall denies GitHub runners. The job allows its own IP before init and removes it afterwards. Needs the azure inputs and `state-resource-group`. |
| `state-resource-group` | empty | Resource group of the state storage account. Required with `state-storage-account`. |
| `state-container` | `tfstate` | Blob container holding the state, used to verify the firewall rule is effective before init runs. |

## Outputs

| Name | Description |
|------|-------------|
| `changes` | Whether the plan contains changes, `"true"` or `"false"`. A deploy workflow can skip its apply job when the merge changed nothing. |

## Permissions

Inherits the caller's `GITHUB_TOKEN`. Grant `contents: read`; add `id-token: write` on the
calling job when the azure inputs are set, because the OIDC login mints a token. The block
declares no fixed permissions because a called workflow that requests more than the caller
granted fails the run at startup.

## Notes

- The plan runs with `-detailed-exitcode`: exit 0 is a clean plan with no changes, exit 2
  a clean plan with changes, anything else a failure. Both clean outcomes pass the job and
  set the `changes` output.
- Pull requests from forks never receive an OIDC token, even with `id-token: write`.
  Guard the job as in the example above; fork contributors still get the credential-free
  [terraform-format-validate-lint](terraform-format-validate-lint.md) gate.
- The firewall rule is added before init and removed in a step that always runs, and the
  job polls the data plane until the rule is effective, because propagation takes seconds
  to minutes. If the runner is killed hard the removal can be skipped; a firewall managed
  by the consumer's own Terraform shows the leaked rule as drift on the next plan.
- Azure IP network rules do not apply to traffic from the same Azure region as the
  storage account, and GitHub-hosted runners run in Azure. Runners are hosted in other
  regions than most accounts, so the rule works, but a persistent 403 after the polling
  window is this limitation showing up.
- The plan artifact is the exact binary plan. Treat it like state: it can contain
  sensitive values in clear text, which is why retention defaults to one day.
- `terraform_wrapper` is off because the block reads the plan's stdout and exit code
  itself.
