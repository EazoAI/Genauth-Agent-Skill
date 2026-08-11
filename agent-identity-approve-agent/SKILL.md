---
name: agent-identity-approve-agent
version: 2.0.0
description: "Review and decide Agent capability or Agent-level settings approvals with self-approval protection."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Approve or reject Agent changes

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-agent-management/SKILL.md`](../agent-identity-agent-management/SKILL.md) completely.

Fetch the approval detail and show requester, Agent, frozen before/after boundary, version, and readiness impact. The Owner/requester cannot approve their own request. Obtain an explicit decision before passing `--yes`; add `--settings` only for a settings approval.

Run approval commands with an explicit approver profile. First verify the
profile subject and selected pool, then fetch the current request:

```bash
genauth-agent --profile <approver> approvals get --approval-id <id> --output json --non-interactive
```

For settings requests, add `--settings` to both get and decision commands.
Require a reason and the fetched approval version for approve or reject. If the
request changed, became terminal, or belongs to the same subject, stop and
report it. After a successful decision, fetch the Agent/settings again and
report activation and readiness separately.
