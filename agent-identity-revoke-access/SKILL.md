---
name: agent-identity-revoke-access
version: 2.0.0
description: "Revoke an Agent Credential, UserGrant, or Token JTI after showing its exact target and runtime impact."
metadata:
  requires:
    bins: ["agent-identity"]
---

# Revoke Agent access

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-authorization-runtime/SKILL.md`](../agent-identity-authorization-runtime/SKILL.md) completely.

Identify exactly one Credential, UserGrant, or Token JTI; fetch its current state; explain the blast radius; obtain a reason and explicit confirmation; then pass `--yes` to the corresponding revoke command. Never substitute Agent archive for a narrower revocation request.

Use this target-specific sequence:

- Credential: `credentials list --agent-id <agent-id>`, then `credentials revoke
  --agent-id <agent-id> --credential-id <id> --yes`.
- UserGrant: `grants list`, match exact subject/audience/scope,
  then `grants revoke --grant-id <id> --version <current-version>
  --reason <reason> --yes`.
- Token: `tokens list --agent-id <owned-agent-id>` when required by the actor,
  then `tokens revoke --jti <jti> --reason <reason> --yes` and include
  `--agent-id` for a member-owned Agent.

After revocation, re-fetch metadata and audit events. Report whether the server
revocation succeeded and whether any local Credential reference was removed as
separate facts. Do not broaden a single-resource request into revoking all
grants, rotating credentials, suspending, or archiving the Agent.
