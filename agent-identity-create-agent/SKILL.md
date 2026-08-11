---
name: agent-identity-create-agent
version: 1.1.0
description: "Create a company Agent, select GenAuth DataPolicy references, inspect its draft, and submit the frozen capability for approval."
metadata:
  requires:
    bins: ["agent-identity"]
---

# Create a company Agent

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-agent-management/SKILL.md`](../agent-identity-agent-management/SKILL.md) completely.

Resolve the application, owner, audience, and every DataPolicy ID before creation. Only company Agents are supported. After creation, inspect the returned Agent and capability draft, submit its exact version, and report approval/readiness separately.

If creation returns `PARTIAL_AGENT_CREATE`, the Agent exists. Use the returned
`agent_id` and `agents capability update --version 0` to create the missing
draft; do not rerun Agent creation with the same identifier.

Before creation, print a confirmation boundary containing profile/subject,
user pool, identifier, owner, application, audience, and the complete resolved
DataPolicy list. After creation, return a checkpoint with Agent ID, Capability
draft version, submission approval ID/version, and current readiness blockers.
If any identifier or version is absent from JSON, stop instead of parsing prose
or guessing.
