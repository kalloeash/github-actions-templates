# state-firewall-access

Temporarily allow the running job through the firewall of an Azure storage account that
denies public network access. Used by the terraform-plan and terraform-apply workflows:
`allow` runs before init, `remove` runs in a step that always executes. The two workflows
share this action so a fix to the firewall handling lands in both at once.

`allow` discovers the runner's public IP (two independent services, retried, validated as
an IPv4 address), adds it to the account firewall, and polls the data plane until the rule
is effective, because propagation takes seconds to minutes. The rule collection on a
storage account is one list that concurrent writers read-modify-write, so each poll
attempt re-adds the rule when a concurrent run clobbered it; presence is checked first
because adding a duplicate fails. `remove` deletes the rule with retries; removing an
absent rule is a no-op.

## Inputs

| Name | Default | Description |
|------|---------|-------------|
| `mode` | required | `allow` adds the rule and verifies it works; `remove` deletes it. |
| `storage-account` | required | Storage account whose firewall is changed. |
| `resource-group` | required | Resource group of the storage account. |
| `container` | empty | Blob container used to verify the rule is effective. Required in allow mode. |

## Requirements

- An authenticated az session, normally from azure/login with OIDC.
- Management-plane read and write on the storage account, for the network rules. Note
  that `Microsoft.Storage/storageAccounts/write` is a broad account-level permission, not
  a rule-only one; scope its role assignment to the single state storage account.
- Data-plane read on the container, for the verification probe.
- The IP travels from `allow` to `remove` in the `RUNNER_IP` environment variable, so
  both calls must run in the same job.

## Concurrency

Concurrent edits to one account's rule collection overwrite each other. The re-add loop
recovers the common case, but runs that open the firewall on the same account should not
race at all: chain plan jobs inside one workflow with `needs`, and give every workflow
that touches the account the same concurrency group. Changes made outside GitHub Actions
are outside that coordination entirely.
