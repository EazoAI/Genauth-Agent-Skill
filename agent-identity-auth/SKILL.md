---
name: agent-identity-auth
version: 2.0.1
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
- Tenant administrator login: `genauth-agent auth login --endpoint <genauth-origin> --profile-name <name>`
- The CLI discovers the dedicated OIDC client. Never ask for or add `--client-id`.
- Do not ask for a user pool before the first browser login. If GenAuth returns
  multiple manageable pools, show each returned name and ID (plus domain when
  present), ask the administrator to choose from that list, and retry with
  `--user-pool-id <pool>`.
- Switch administrator user pool: `genauth-agent auth select-user-pool --user-pool-id <pool>`
- Before switching, run `genauth-agent auth list-user-pools` and show the name,
  domain, and ID of every option, including which one is currently selected.
- Refresh an OIDC session: `genauth-agent auth refresh`
- Logout: `genauth-agent auth logout`

For multi-role work, always create named profiles with `--profile-name` and
address them using the global `--profile` flag. Recommended names are
`agent-owner`, `agent-approver`, and `agent-admin`. Every CLI profile is a
tenant-administrator profile. Verify each profile independently:

```bash
genauth-agent --profile <name> auth status --output json --non-interactive
```

Do not use `profiles use` inside automated multi-role flows: changing the
default makes actor confusion more likely. Even for the user-pool root
administrator self-approval exception, carry the profile explicitly and let
the server prove the role.

Browser authorization is a human step, but on the same workstation the Agent
must execute `auth login` itself. The CLI opens the GenAuth URL and remains
attached to the loopback callback. Keep waiting for that command, then verify
JSON `auth status` and continue automatically; do not ask the human to run the
command or reply after login. Return the printed URL only as a fallback when
local browser opening is unavailable or the login is happening on another
workstation. Never fill credentials, collect passwords, or claim success
before `auth status` succeeds.

When switching a user pool, rely on the CLI's server-side validation. A changed local file or profile display alone is not proof that the administrator can manage that pool.

Login completion evidence is the JSON status containing the expected login
type, subject identity, selected user-pool name and ID, and usable session. A returned
authorization URL or a successful browser page is only an intermediate state.
