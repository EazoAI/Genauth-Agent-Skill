---
name: agent-identity-create-agent
version: 2.0.0
description: "Create a company Agent, select GenAuth DataPolicy references, inspect its draft, and submit the frozen capability for approval."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Create a company Agent

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-agent-management/SKILL.md`](../agent-identity-agent-management/SKILL.md) completely.

Resolve the application, owner, and every DataPolicy ID before creation. Do not
ask the user for an audience: the CLI derives it from the selected GenAuth
Application and the server verifies that binding. Only company Agents are
supported. After creation, inspect the returned Agent and capability draft,
submit its exact version, and report approval/readiness separately.

If creation returns `PARTIAL_AGENT_CREATE`, the Agent exists. Use the returned
`agent_id` and `agents capability update --version 0` to create the missing
draft; do not rerun Agent creation with the same identifier.

Before creation, print a confirmation boundary containing profile/subject,
user pool, identifier, owner, application, and the complete resolved DataPolicy
list. After creation, return the CLI-resolved audience as audit information in
the checkpoint together with Agent ID, Capability draft version, submission
approval ID/version, and current readiness blockers. Never turn audience into
a user input or infer it from prose.
If any identifier or version is absent from JSON, stop instead of parsing prose
or guessing.
