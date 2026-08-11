---
name: agent-identity-user-journey
version: 2.0.0
description: "Run or resume the complete Agent Identity journey: user-pool login, company Agent creation and approval, settings, Credential, user authorization, Token, and fixed Provider call through GenAuth."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Complete Agent Identity user journey

Read these files completely before acting:

- [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md)
- [`../agent-identity-auth/SKILL.md`](../agent-identity-auth/SKILL.md)
- [`../agent-identity-agent-management/SKILL.md`](../agent-identity-agent-management/SKILL.md)
- [`../agent-identity-authorization-runtime/SKILL.md`](../agent-identity-authorization-runtime/SKILL.md)

This Skill is the end-to-end orchestrator. It may pause only for human login,
approval, explicit consent, or a material security choice. After a pause,
resume from server state using the shared recovery reference rather than
repeating completed writes.

## Required inputs

Resolve these non-secret values before the first write:

- GenAuth HTTPS origin; the CLI discovers its dedicated OIDC Client ID;
- requester/owner profile and either a different approver profile or a
  confirmed current user-pool root administrator self-approval path;
- company Agent identifier, display name, purpose, application ID, and owner;
- exact GenAuth DataPolicy IDs; the CLI derives ResourceServer audience from
  the selected Application;
- Agent settings: authorization mode, Token TTL, UserGrant maximum TTL,
  Credential TTL/rotation overlap, redirect URIs, and realtime-decision choice;
- authorization actor: administrator target user and explicit or
  policy-permitted silent mode;
- fixed Provider key, method, normalized path, and optional JSON body file.

Never infer a permission, target user, Provider, or security-sensitive setting.
Starter payloads are available at
[`examples/company-agent.json`](examples/company-agent.json) and
[`examples/agent-settings.json`](examples/agent-settings.json). Treat them as
schemas, not defaults: replace every placeholder and confirm all security
values. Administrator Agent creation must set `owner_user_id`.

## Phase 1: establish actor contexts

Create or select named administrator profiles. Do not ask for a Client ID or a
user pool before the first browser login:

```bash
genauth-agent auth login --profile-name agent-owner --endpoint <genauth-origin>
genauth-agent auth login --profile-name agent-approver --endpoint <genauth-origin>
```

The only CLI login type is `tenant_admin`. If multiple manageable pools are
returned, show each name and ID plus domain when present, then select the exact
ID corresponding to the user's choice and ensure every profile uses the same
named pool. Before a later switch, run `auth list-user-pools`; never ask the user
to choose from bare IDs. Use a different human/profile for ordinary approval. Only the current user-pool root
administrator may reuse the owner profile to approve their own request; the
server verifies that role and self-rejection remains forbidden. Verify every
profile with `--profile <name> auth status` and require the same selected pool.

Checkpoint: profile names, subject IDs, login types, and selected pool name and
ID.

## Phase 2: discover permissions and create the company Agent

With the owner profile, list and inspect real DataPolicy definitions:

```bash
genauth-agent --profile agent-owner permissions list --output json --non-interactive
genauth-agent --profile agent-owner permissions get --permission-id <id> --output json --non-interactive
```

Show the complete owner, application, and permission set. Do not ask the user
for audience. After user confirmation, create the Agent and inspect it:

```bash
genauth-agent --profile agent-owner agents create \
  --identifier <stable-id> \
  --display-name <display-name> \
  --description <purpose> \
  --owner-user-id <admin-only-owner-id> \
  --application-id <application-id> \
  --permission-id <policy-id> \
  --output json --non-interactive

genauth-agent --profile agent-owner agents get --agent-id <agent-id> --output json --non-interactive
```

Recover `PARTIAL_AGENT_CREATE` exactly as documented in the shared recovery
reference.

Checkpoint: Agent ID, CLI-resolved audience, and fetched Capability draft
`record_version`.

## Phase 3: submit and approve Capability

Submit the exact fetched draft version:

```bash
genauth-agent --profile agent-owner agents capability submit --agent-id <agent-id> --version <draft-version> --output json --non-interactive
```

Switch actors. The approver must fetch the frozen request and compare requester,
Agent, audience, permission IDs, before/after boundary, and version:

```bash
genauth-agent --profile agent-approver approvals get --approval-id <approval-id> --output json --non-interactive
genauth-agent --profile agent-approver approvals approve --approval-id <approval-id> --version <approval-version> --reason <reason> --yes --output json --non-interactive
```

Use `approvals reject` only for an explicit rejection. Fetch the Agent again;
do not equate an approval response with an active Capability until current
state confirms it.

Checkpoint: approval ID/version and active Capability version.

## Phase 4: configure Agent-level settings

Fetch both effective settings and any draft. Present the exact effective change
and obtain confirmation for any expansion. Update with the fetched draft
version, submit, and have the separate approver decide it using `--settings`:

```bash
genauth-agent --profile agent-owner agents settings get --agent-id <agent-id> --output json --non-interactive
genauth-agent --profile agent-owner agents settings update --agent-id <agent-id> --file <complete-settings.json> --output json --non-interactive
genauth-agent --profile agent-owner agents settings submit --agent-id <agent-id> --output json --non-interactive
genauth-agent --profile agent-approver approvals get --settings --approval-id <approval-id> --output json --non-interactive
genauth-agent --profile agent-approver approvals approve --settings --approval-id <approval-id> --version <approval-version> --reason <reason> --yes --output json --non-interactive
```

Checkpoint: settings approval and effective settings version/values.

## Phase 5: create the Agent Credential

Read readiness. When active Capability/settings exist and the only blocker is
`credential_required`, create the first Credential:

```bash
genauth-agent --profile agent-owner agents readiness --agent-id <agent-id> --output json --non-interactive
genauth-agent --profile agent-owner credentials create --agent-id <agent-id> --output json --non-interactive
genauth-agent --profile agent-owner agents readiness --agent-id <agent-id> --output json --non-interactive
```

Retain only `credential_id`, `secret_ref`, and expiry. Require readiness without
blockers before continuing.

## Phase 6: authorize the user

Use an administrator profile. An explicit request may select `--user-id`;
silent mode additionally requires Agent policy, GenAuth eligibility, and a
fresh confirmation before `--yes`. The target human completes explicit consent
in the GenAuth browser and does not need a CLI member profile.

```bash
genauth-agent --profile <authorization-profile> authorizations create \
  --agent-id <agent-id> \
  --user-id <admin-only-target-user-id> \
  --audience <audience> \
  --permission-id <policy-id> \
  --mode explicit \
  --output json --non-interactive
```

For explicit mode, give only the returned `authorization_url` to the target
human, then wait on the requester's workstation:

```bash
genauth-agent --profile <authorization-profile> --timeout 10m authorizations wait --authorization-id <authorization-id> --output json --non-interactive
```

Exit `6` remains pending. Only `APPROVED` plus an active UserGrant completes
this phase.

Checkpoint: authorization request ID/status and active UserGrant ID/version.

## Phase 7: call the fixed Provider through GenAuth

Prefer the closed runtime call; it obtains the Agent Identity Token in-process:

```bash
genauth-agent --profile <runtime-profile> providers call \
  --credential <keychain-secret-ref> \
  --grant-id <user-grant-id> \
  --audience <audience> \
  --provider <fixed-provider-key> \
  --method <method> \
  --path <normalized-path> \
  --output json --non-interactive
```

Add `--body-file <json-file>` only when required. Never replace the Provider
key/path with a host or arbitrary URL. Use `tokens issue` only when the user
explicitly requests raw Token semantics; omit `--show-token` by default.

## Completion report

Return a redacted report containing actor/profile and user-pool confirmation,
Agent/Capability/settings status, approval IDs, readiness, Credential reference,
UserGrant scope/expiry, and Provider result/request ID. Never include session
Tokens, Client Secrets, PKCE values, authorization codes, or access Tokens.
