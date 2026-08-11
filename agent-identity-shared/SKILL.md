---
name: agent-identity-shared
version: 2.0.0
description: "Agent Identity CLI shared authentication, selected user-pool context, JSON contract, errors, and secret-safety rules. Read before any other agent-identity skill."
metadata:
  requires:
    bins: ["agent-identity"]
  cliHelp: "agent-identity --help"
---

# Agent Identity shared rules

Use `agent-identity` only. The CLI sends every request to the configured GenAuth endpoint; never call Agent Identity internal routes, a Provider host, a database, EAK Delegation, or Token Vault directly.

For any workflow with more than one command, also read
[`references/automation-contract.md`](references/automation-contract.md). For
state recovery, approval, authorization, or diagnosis, read
[`references/lifecycle-and-recovery.md`](references/lifecycle-and-recovery.md).

## Compatibility preflight

Before a first run or after an upgrade, execute:

```bash
agent-identity version --output json --non-interactive
agent-identity doctor --output json --non-interactive
```

Require `api_version` to be `agent-identity.cli/v1`, `command_contract` to be
`agent-identity.commands/v2`, and `server_contract` to be
`genauth-agent-identity-v1`. An unknown contract is a hard stop; do not guess
renamed commands, fields, or flags. `doctor` is read-only and proves local profile,
selected user pool, secret-store access, and GenAuth reachability, but it does
not prove that an Agent is runtime-ready.

## Mandatory preflight

Run:

```bash
agent-identity auth status
```

If it returns exit `3`, ask the user to complete one of these flows themselves:

```bash
agent-identity auth login --endpoint <genauth-origin> --user-pool-id <pool> --client-id <oidc-client>
agent-identity auth login --admin --endpoint <genauth-origin> --user-pool-id <pool> --client-id <oidc-client>
```

Do not request, accept, or type a password. An existing session may be imported only through stdin with `--session-token-stdin`; never put a session Token on the command line.

Both users and tenant administrators must have a selected user pool. To change an administrator context, use `auth select-user-pool`; never edit the local profile file directly.

## Machine contract

- For every automated, non-browser invocation, add the persistent flags
  `--output json --non-interactive`. Browser login is the only exception; it
  must remain an explicit human interaction.
- Read only JSON stdout fields: `api_version`, `kind`, `data`, `request_id`, `warnings`, and `error.code`.
- Never parse table text or debug logs.
- Exit codes: `2` invalid input, `3` login/session, `4` denied, `5` state/not found, `6` pending, `7` retryable dependency, `8` conflict, `9` internal.
- On `6`, report pending state; do not treat it as approval or authorization success.
- On `7`, retry reads at most twice with backoff. Retry writes only when the same idempotency key is retained by the CLI workflow.
- On unknown statuses or fields required for a safety decision, stop and suggest upgrading the CLI.
- Carry `--profile <name>` on every multi-actor command. Do not rely on the
  mutable default profile when requester, approver, administrator, and target
  user are different humans.
- After every write, record only non-secret checkpoint identifiers and versions
  from JSON `data`, plus the top-level `request_id`. Re-read the resource before
  the next write; never derive a version by incrementing locally.

## Secret rules

- Never run with shell tracing.
- Never read or print values behind `keychain://` references.
- Never cache an Agent access Token in a file, memory note, Skill output, or environment beyond a single child process.
- `credentials create` and `rotate` store the one-time secret in the OS secret store. Report only `credential_id`, `secret_ref`, and expiry.
- `tokens issue` must omit `--show-token` unless the user explicitly asks for the raw Token and understands the exposure.
- Prefer `providers call`; it gets a Token in-process and sends it only back to GenAuth.
- `auth logout` first revokes the GenAuth OIDC session. If remote revocation
  fails, report the failure and retain the local profile so the user can retry;
  never claim logout from local-file deletion alone.

## Trust boundaries

- Permission IDs are GenAuth DataPolicy references. Do not rename them to OAuth scopes.
- Agent Identity stores snapshots but GenAuth remains authoritative for current user, user-pool, and DataPolicy state.
- Owner is not an approver and can never self-approve.
- Skills may skip a local prompt only after user confirmation; they cannot bypass server approval, silent-authorization policy, or revocation checks.
