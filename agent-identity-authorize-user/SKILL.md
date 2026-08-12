---
name: agent-identity-authorize-user
version: 2.0.0
description: "Create explicit or policy-allowed silent Agent user authorization and wait for the resulting UserGrant."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Authorize a user

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-authorization-runtime/SKILL.md`](../agent-identity-authorization-runtime/SKILL.md) completely.

The CLI currently authenticates administrators only. An administrator may name
a target user; that target completes explicit consent in the GenAuth browser
without a CLI member profile. Silent mode requires Agent policy, GenAuth
eligibility, and explicit confirmation before `--yes`.

Administrator permission-catalog reads are not target-specific. A returned
`silent_grantable=false` is not, by itself, proof that every target user is
ineligible. Confirm the exact target, Agent, audience, permissions, TTL, and
effective `SILENT_IF_ALLOWED` setting, then use the silent create request as
the authoritative GenAuth eligibility decision. Stop on
`SILENT_AUTHORIZATION_NOT_ALLOWED`, `SUBJECT_INACTIVE`, or
`POLICY_DECISION_DENIED`; do not retry with another target or mode.

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
Token or one-time secret. An `ACTIVE` status is insufficient when `expires_at`
has passed; honor the `grants list` warning and never select that grant for a
runtime call. The CLI automatically removes local one-time authorization state
after every terminal result. Report `local_cleanup_required=true` as a local
secret-store repair condition without recreating the authorization request.
