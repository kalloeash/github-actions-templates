# terraform-plan

Initialize a root configuration and produce a Terraform plan. Read-only by default: the
state lock stays off because a speculative plan on a pull request only reads state, and
locking would make parallel pull-request plans queue behind each other for nothing. The
plan output lands in the job step summary. When `artifact-name` is set the binary plan
file is uploaded together with a metadata file binding it to the commit, so
[terraform-apply](terraform-apply.md) can verify it applies exactly what was reviewed.
The Azure inputs are optional: when set, the job logs in with OIDC workload identity
federation, no stored secrets.

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

A plan against Azure remote state with OIDC, with variable values that live outside the
repository. The identifiers are repository variables, not secrets; none of them is
sensitive. The `if` keeps the job off pull requests from forks, which never receive an
OIDC token:

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
      variables: |
        subscription_id = "${{ vars.AZURE_SUBSCRIPTION_ID }}"
        alert_emails    = ["${{ vars.ALERT_EMAIL }}"]
      azure-client-id: ${{ vars.AZURE_PLAN_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

## Network access to remote state

This block never changes network rules. The state backend must be reachable from the
runner, and that is a deliberate design decision with exactly two sound configurations:

- Identity-first, the posture for GitHub-hosted runners. The state storage account
  allows public network access, and security is carried by the identity layer: Entra-only
  authentication with shared keys disabled, role assignments scoped to the state
  container, TLS-only, versioning, soft delete, and logging. This is the configuration
  Microsoft's own Terraform state tutorial and OIDC reference sample run with hosted
  runners. IaC scanners flag the open network path; suppress that finding with a
  documented risk acceptance, not silently.
- Network-restricted, the posture when a runner can live inside the network. A private
  endpoint on the storage account, reached by GitHub's VNet-injected hosted runners
  (Team and Enterprise organizations, larger runners) or by a self-hosted runner behind
  fixed egress. Do not use self-hosted runners on public repositories; a fork pull
  request can execute code on them.

Patterns that mutate the account firewall per job, adding the runner's IP and removing
it afterwards, exist in the wild. This catalog deliberately does not ship one: the rule
collection is a single list updated by read-modify-write with no transactional safety,
so concurrent runs corrupt each other's access in ways retries can narrow but never
close, and no first-party guidance endorses the pattern.

## Security model

Running a credentialed plan on repository code is a trust decision, not a detail. Read
this section before wiring the Azure inputs.

- A plan executes the configuration: providers, modules, and data sources run code and
  make authenticated reads during planning. Anyone who can get Terraform changes into a
  branch of the repository can exercise the plan identity. Fork pull requests never
  receive an OIDC token, but same-repository branches do, so branch permissions and a
  reviewed lockfile are part of the security boundary, and the plan identity must stay
  least-privilege.
- The roles below are strictly read-only, at the infrastructure layer and at the state
  layer, so a leaked or misused plan token cannot change anything or take the state
  lock.
- The plan output is visible to everyone who can read the repository, in the job log and
  in the step summary. Terraform masks values marked `sensitive`, nothing else. On a
  public repository that audience is everyone; set `write-step-summary` to false to keep
  the output off the summary page, and keep genuinely secret values out of plans
  entirely.
- A saved plan can contain sensitive values and a copy of state in clear text, and
  artifacts of a public repository are downloadable by anyone. The block therefore
  refuses artifact mode on a public repository unless
  `allow-artifact-on-public-repo: true` states that the plan is safe to publish.
- The `variables` input is for non-secret values only. Anything passed there flows into
  workflow inputs, plan output, saved plans, logs, and state.

## Azure OIDC prerequisites

The identity the job logs in as is plain Terraform, created once per consuming
repository. A user-assigned managed identity carries no client secret at all; the
federated credential ties it to pull request runs of one repository and nothing else:

```hcl
data "azurerm_subscription" "current" {}

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
take the state lock, cannot write state, and cannot change infrastructure.

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
| `variables` | empty | Newline-separated variable assignments in tfvars syntax, written to an auto-loaded tfvars file before planning. Non-secret values only. |
| `lock` | `false` | Take the state lock during plan. A speculative plan only reads state. Locking needs write access on the state blob, which the read-only plan identity above does not have. |
| `artifact-name` | empty | When set, the plan is saved with `-out` and uploaded as an artifact under this name for terraform-apply, together with its metadata file. |
| `artifact-retention-days` | `1` | Retention for the plan artifact. Short by default because plan files can contain sensitive values in clear text. |
| `allow-artifact-on-public-repo` | `false` | Artifacts of a public repository are downloadable by anyone. Setting this true accepts that exposure for the saved plan. |
| `write-step-summary` | `true` | Write the plan output to the job step summary. The output is also in the job log. |
| `azure-client-id` | empty | Client id of the Azure identity for the OIDC login. Set all three azure inputs together or not at all. |
| `azure-tenant-id` | empty | Tenant id for the OIDC login. |
| `azure-subscription-id` | empty | Subscription id for the OIDC login. |

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
- A deploy pipeline does not need `lock: true` on its plan: the apply refuses a saved
  plan whose state moved after planning, and the deploy workflow's concurrency group
  keeps applies in merge order. Enable the lock only with an identity that holds
  `Storage Blob Data Contributor` on the state container.
- A scheduled call of this block doubles as drift detection: a plan that suddenly shows
  changes nobody made is drift, surfaced weekly instead of at the next human plan.
- `terraform_wrapper` is off because the block reads the plan's stdout and exit code
  itself.
