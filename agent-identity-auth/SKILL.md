---
name: agent-identity-auth
version: 2.0.0
description: "Use for Agent Identity CLI login, logout, status, profile selection, and tenant administrator user-pool switching."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Agent Identity authentication

Before acting, read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) completely.

## Intent mapping

- Check current identity: `genauth-agent auth status`
- List profiles: `genauth-agent profiles list`
- Select an existing profile: `genauth-agent profiles use --name <name>`
- User login: `genauth-agent auth login --endpoint <genauth-origin> --user-pool-id <pool> --client-id <client>`
- Tenant administrator login: add `--admin`; a user pool is still mandatory.
- Switch administrator user pool: `genauth-agent auth select-user-pool --user-pool-id <pool>`
- Refresh an OIDC session: `genauth-agent auth refresh`
- Logout: `genauth-agent auth logout`

For multi-role work, always create named profiles with `--profile-name` and
address them using the global `--profile` flag. Recommended names are
`agent-owner`, `agent-approver`, `agent-admin`, and `agent-user-<label>`. Verify
each profile independently:

```bash
genauth-agent --profile <name> auth status --output json --non-interactive
```

Do not use `profiles use` inside automated multi-role flows: changing the
default makes actor confusion and accidental self-approval more likely.

Browser authorization is a human step. Return the printed GenAuth URL to the user and wait; do not attempt to fill credentials, collect passwords, or claim success before `auth status` succeeds.

When switching a user pool, rely on the CLI's server-side validation. A changed local file or profile display alone is not proof that the administrator can manage that pool.

Login completion evidence is the JSON status containing the expected login
type, subject identity, selected user-pool ID, and usable session. A returned
authorization URL or a successful browser page is only an intermediate state.
