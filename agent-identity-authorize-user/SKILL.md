---
name: agent-identity-authorize-user
version: 1.1.0
description: "Create explicit or policy-allowed silent Agent user authorization and wait for the resulting UserGrant."
metadata:
  requires:
    bins: ["agent-identity"]
---

# Authorize a user

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-authorization-runtime/SKILL.md`](../agent-identity-authorization-runtime/SKILL.md) completely.

Normal users authorize only themselves through explicit consent. Administrators may name a target user; silent mode requires Agent policy, GenAuth eligibility, and explicit confirmation before `--yes`.

For an explicit same-workstation flow, prefer the CLI-managed loopback callback
and `--open-browser`. For a different workstation, also use the default
loopback request, return the user-pool-bound `authorization_url` to the target
human, and run `authorizations wait` on the requester's workstation. After the
browser records consent, the CLI completes the exchange through authenticated
PKCE-bound polling; no cross-device authorization-code handoff is needed. Use
a registered HTTPS callback only for an existing standard callback client. A
browser or CLI denial is terminal. Treat exit `6` as pending and never handle a
one-time code in chat, logs, files, or command history.

Before creation, show acting profile/login type, selected pool, Agent, target
subject, mode, audience, full DataPolicy set, and requested UserGrant TTL. After
creation, retain the authorization request ID and return only the GenAuth URL to
the target human. After waiting, match an active UserGrant by exact subject,
Agent, audience, and permission set; return its ID/version/expiry without any
Token or one-time secret.
