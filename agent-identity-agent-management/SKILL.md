---
name: agent-identity-agent-management
version: 2.0.0
description: "Create, inspect, configure, submit, and approve company-level Agents with GenAuth DataPolicy permission references through the Agent Identity CLI."
metadata:
  requires:
    bins: ["agent-identity"]
---

# Agent management and approval

Before acting, read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) completely.

Only company-level Agents are in scope. Personal Agent creation is unsupported.

## Safe workflow

1. Run `agent-identity auth status` and confirm the selected user pool.
2. Discover real permissions with `agent-identity permissions list`; use `permissions get --permission-id <id>` for details.
3. Present the exact Agent owner, application, audience, and full permission-ID set to the user. Never infer or silently append a permission.
4. Create a draft:

```bash
agent-identity agents create \
  --identifier <stable-id> \
  --display-name <name> \
  --description <purpose> \
  --owner-user-id <user-id> \
  --application-id <application-id> \
  --audience <https-audience> \
  --permission-id <policy-id>
```

5. Inspect with `agents get --agent-id <id>` and settings with `agents settings get --agent-id <id>`.
   If the permission draft must be corrected, or Agent creation reports
   `PARTIAL_AGENT_CREATE`, save it without recreating the Agent:

```bash
agent-identity agents capability update \
  --agent-id <id> \
  --audience <https-audience> \
  --permission-id <policy-id> \
  --version <current-draft-version>
```

   Use version `0` only when the first Capability draft was not created. On a
   conflict, inspect the Agent again and never guess the next version.

6. Submit the frozen capability version with `agents capability submit --agent-id <id> --version <version>`.
7. A different authorized administrator reviews `approvals get --approval-id <id>` and then, after explicit confirmation, runs `approvals approve --approval-id <id> --yes` or `approvals reject --approval-id <id> --yes` with the current version and a reason. Add `--settings` for a settings approval.

Keep owner/requester and approver as separate named profiles and run `auth
status` immediately before submit and decision writes. Capture the `agent_id`,
Capability draft `record_version`, approval ID, and approval version from JSON.
After the decision, fetch `agents get` again and confirm the active Capability;
do not reuse the submitted draft response as proof of activation.

For interruption recovery, use `agents list`, `agents get`, `agents settings
get`, `agents readiness`, and the appropriate `approvals list/get` before any
write. A pending request should be continued, not duplicated.

## Settings

Settings are Agent-level only. Prepare a complete JSON or YAML file and run:

```bash
agent-identity agents settings update --agent-id <id> --file <settings.json>
agent-identity agents settings submit --agent-id <id>
```

Always show configured and effective values. Treat `SILENT_IF_ALLOWED`, longer Token TTL, longer UserGrant TTL, broader redirect URIs, or disabled realtime decision as security-sensitive. Get explicit user confirmation before applying an expansion. Tightening may activate immediately, while expansion can require approval.

When using value flags instead of `--file`, `--version` is the existing
`DRAFT.record_version`, not the active settings version. Pass `0` whenever no
settings draft exists, including when an active settings version already
exists. If a draft exists, fetch it and pass that draft's `record_version`; do
not guess a later version after a conflict. The same
`expected_record_version` rule applies inside a settings file.

Never claim readiness only because approval succeeded. Verify the returned readiness blockers, active settings, active Capability, and an active local Credential.

Use the readiness blockers as the gate:

- Capability or settings blocker: return to the matching draft/approval state.
- `credential_required` as the only blocker: continue with first Credential
  creation; this is the expected bootstrap state.
- suspended/archived or an unknown blocker: stop and report it; do not try to
  repair it by broadening settings or recreating the Agent.

Use only `agents lifecycle pause`, `agents lifecycle resume`, and `agents
lifecycle archive`. Pause is reversible. Archive is irreversible and requires an explicit user
decision plus `--yes`; never infer deletion from a request to pause or disable
access.

All create payloads are company Agents. Do not add, infer, or expose a personal
Agent type even if an older Console or compatibility response mentions one.
