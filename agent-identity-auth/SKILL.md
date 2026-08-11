---
name: agent-identity-auth
version: 1.1.0
description: "Use for Agent Identity CLI login, logout, status, profile selection, and tenant administrator user-pool switching."
metadata:
  requires:
    bins: ["agent-identity"]
---

# Agent Identity authentication

Before acting, read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) completely.

## Intent mapping

- Check current identity: `agent-identity auth status`
- List profiles: `agent-identity config list-profiles`
- Select an existing profile: `agent-identity config use-profile --name <name>`
- User login: `agent-identity auth login --endpoint <genauth-origin> --user-pool-id <pool> --client-id <client>`
- Tenant administrator login: add `--admin`; a user pool is still mandatory.
- Switch administrator user pool: `agent-identity auth switch-user-pool --user-pool-id <pool>`
- Refresh an OIDC session: `agent-identity auth refresh`
- Logout: `agent-identity auth logout`

For multi-role work, always create named profiles with `--profile-name` and
address them using the global `--profile` flag. Recommended names are
`agent-owner`, `agent-approver`, `agent-admin`, and `agent-user-<label>`. Verify
each profile independently:

```bash
agent-identity --profile <name> auth status --output json --non-interactive
```

Do not use `config use-profile` inside automated multi-role flows: changing the
default makes actor confusion and accidental self-approval more likely.

Browser authorization is a human step. Return the printed GenAuth URL to the user and wait; do not attempt to fill credentials, collect passwords, or claim success before `auth status` succeeds.

When switching a user pool, rely on the CLI's server-side validation. A changed local file or profile display alone is not proof that the administrator can manage that pool.

Login completion evidence is the JSON status containing the expected login
type, subject identity, selected user-pool ID, and usable session. A returned
authorization URL or a successful browser page is only an intermediate state.
