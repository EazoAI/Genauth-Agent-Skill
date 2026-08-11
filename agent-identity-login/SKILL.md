---
name: agent-identity-login
version: 2.0.0
description: "Authenticate the Agent Identity CLI tenant administrator through GenAuth browser login and select a manageable user pool."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Login and user-pool context

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-auth/SKILL.md`](../agent-identity-auth/SKILL.md) completely, then follow the matching login/profile workflow.

The CLI currently supports tenant-administrator login only. Do not ask whether
the user is a member or administrator, and do not ask for a Client ID or user
pool before starting browser login. Start with:

```bash
genauth-agent auth login --endpoint <genauth-origin> --profile-name <profile>
```

GenAuth discovers the dedicated root-user-pool OIDC client from the endpoint.
After authentication, the CLI auto-selects the only manageable user pool. If
it returns `USER_POOL_SELECTION_REQUIRED`, show each returned manageable pool's
name and ID (plus domain when present), ask the administrator to choose one,
then repeat with
`--user-pool-id <pool>`. The pool identifies the post-login management context;
it is not an OIDC login credential.

For a later switch, first run `auth list-user-pools`, present each returned name,
domain, and ID and mark the current selection. Never ask the user to choose from
bare IDs or reuse a pool ID from another endpoint or profile.

Success requires `genauth-agent auth status` to confirm
`login_type=tenant_admin` and the selected user pool. A printed browser URL,
edited profile file, or locally stored session alone is not proof of login.

Ask for a role-specific profile name before login. For ordinary journeys
involving approval, create distinct owner and approver profiles. A confirmed
current user-pool root administrator may reuse the owner profile for an approve
decision, but not a reject decision. Show a compact status summary for every
profile without revealing session data. If the profile exists, inspect
it first and refresh or switch its validated user pool instead of overwriting it
blindly.
