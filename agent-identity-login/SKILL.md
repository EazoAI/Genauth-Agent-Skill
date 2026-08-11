---
name: agent-identity-login
version: 2.0.0
description: "Authenticate an Agent Identity CLI user or tenant administrator and select the required GenAuth user pool."
metadata:
  requires:
    bins: ["agent-identity"]
---

# Login and user-pool context

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-auth/SKILL.md`](../agent-identity-auth/SKILL.md) completely, then follow the matching login/profile workflow.

Success requires `agent-identity auth status` to confirm the identity type and selected user pool. A printed browser URL, edited profile file, or locally stored session alone is not proof of login.

Ask for a role-specific profile name before login. For a journey involving
approval, create distinct owner and approver profiles and show a compact status
summary for both without revealing session data. If the profile exists, inspect
it first and refresh or switch its validated user pool instead of overwriting it
blindly.
