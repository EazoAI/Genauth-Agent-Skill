---
name: agent-identity-approve-agent
version: 2.0.0
description: "Review and decide Agent capability or Agent-level settings approvals with protected user-pool root administrator self-approval."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Approve or reject Agent changes

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-agent-management/SKILL.md`](../agent-identity-agent-management/SKILL.md) completely.

Fetch the approval detail and show requester, Agent, frozen before/after boundary, version, and readiness impact. Ordinary Owners/requesters cannot approve their own request. The current user-pool root administrator may approve, but not reject, their own request; GenAuth and Agent Identity validate this from signed actor context. Obtain an explicit decision before passing `--yes`; add `--settings` only for a settings approval.

Run approval commands with an explicit profile. Use a different authorized
administrator for ordinary requests. The requester profile may be reused only
when the operator states that it is the current user-pool root administrator;
never treat the profile name as proof. First verify the profile subject and
selected pool, then fetch the current request:

```bash
genauth-agent --profile <approver> approvals get --approval-id <id> --output json --non-interactive
```

For settings requests, add `--settings` to both get and decision commands.
Require a reason and the fetched approval version for approve or reject. If the
request changed or became terminal, stop and report it. If it belongs to the
same subject, proceed only for an approve decision that the server accepts as
the current user-pool root administrator; otherwise stop on
`SELF_APPROVAL_FORBIDDEN`. After a successful decision, fetch the
Agent/settings again and report activation and readiness separately.
