---
name: agent-identity-authorization-runtime
version: 2.0.0
description: "Manage Agent Credentials, explicit or silent user authorization, UserGrants, short-lived Agent Tokens, and GenAuth Provider calls through the Agent Identity CLI."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Authorization and runtime

Before acting, read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) completely.

## Credential

Create only after the Agent capability and effective settings are active. At
this point readiness is expected to report only `credential_required`; the new
Credential is what removes that final blocker. Do not wait for readiness to be
fully ready before creating the first Credential:

```bash
genauth-agent credentials create --agent-id <agent-id>
```

The returned `secret_ref` is safe to retain; the secret itself is not. Rotation and revocation affect running workloads. Show the exact `agent_id/credential_id` and impact, then obtain confirmation before:

```bash
genauth-agent credentials rotate --agent-id <agent-id> --credential-id <credential-id> --yes
genauth-agent credentials revoke --agent-id <agent-id> --credential-id <credential-id> --yes
```

After create or rotate, verify `credentials list --agent-id <agent-id>` and
retain only `credential_id`, `secret_ref`, status, and expiry. Never test a
Credential by reading its Keychain value; use readiness or a closed Provider
call.

## User authorization

The CLI currently authenticates tenant administrators only. Explicit
authorization may specify `--user-id`; the target user completes consent in the
GenAuth browser without a CLI member profile. Silent authorization is
security-sensitive: show target user, audience, all permission IDs, and TTL,
obtain explicit confirmation, then request `--mode silent --yes`. A denial must
not be downgraded automatically to explicit mode.

```bash
genauth-agent authorizations create \
  --agent-id <agent-id> \
  --user-id <admin-only-target> \
  --audience <audience> \
  --permission-id <policy-id> \
  --mode explicit

genauth-agent --timeout 10m authorizations wait --authorization-id <request-id>
```

Omitting `--redirect-uri` creates a random registered loopback callback and is
safe for both same- and different-workstation flows. On the same workstation,
`authorizations create --open-browser` opens the page and waits. On a different
workstation, return the URL to the target human and run `authorizations wait` on
the requester's workstation. After consent, the requester proves possession of
the PKCE verifier and completes the exchange by authenticated polling; the
target browser receives only a completion page and never needs to connect to
its own loopback port.

The returned `authorization_url` is bound to both the request and selected user pool. Give it only to the target human. GenAuth performs login and renders the exact Agent, audience, permission list, and expiry. Do not open, approve, or deny the page on the human's behalf.

Capture the authorization request ID from the returned `data`, not from URL
text. On resume, fetch it with `authorizations get --authorization-id <id>`.
After completion, fetch `grants list` and match exact subject,
Agent, audience, permission set, status, and expiry before retaining the grant
ID. Never pick the newest grant merely by list order.

Use a custom HTTPS callback only when that exact URI is registered in the Agent
settings and an existing client integration requires a standard authorization
code callback. In that case, deliver the callback code to the original
requester without chat, logs, command history, or files, then exchange it
through stdin. The CLI retrieves the PKCE verifier from the OS secret store and
deletes all local one-time values after success:

```bash
printf '%s' "$ONE_TIME_CODE" | genauth-agent authorizations exchange \
  --authorization-id <request-id> \
  --code-stdin
```

For a same-user terminal-only flow, `authorizations consent` stores the code in the OS secret store and `authorizations exchange` consumes it without printing it. `--show-code` is only for an explicitly requested secure cross-device handoff.

If the human declines outside the browser page, only the target user's profile may record the terminal decision, and it requires confirmation:

```bash
genauth-agent authorizations deny \
  --authorization-id <request-id> \
  --reason <reason> \
  --yes
```

Exit `6` means the request remains pending. A raw `CONSENTED` status is not
complete, but `authorizations wait` automatically performs the PKCE-bound
requester exchange without requiring a callback code. Only `APPROVED` plus an
active UserGrant completes authorization. Never retry a denial as silent or
explicit authorization automatically.

Before revoking a UserGrant, show Agent, subject, audience, permissions, current version, and reason. Revocation invalidates subsequent introspection via the UserGrant epoch.
Run `grants revoke --grant-id <grant-id> --version <current-version>
--reason <reason> --yes` only after that confirmation. The server resolves the
Agent inside the selected user pool; do not ask for or pass an Agent ID.

## Runtime

Prefer the closed Provider flow:

```bash
genauth-agent providers call \
  --credential keychain://genauth-agent/credential/<credential-id> \
  --grant-id <user-grant-id> \
  --audience <audience> \
  --provider <provider-key> \
  --method GET \
  --path /resource/path
```

Never add `--url`, `--host`, custom Authorization, Cookie, `X-GenAuth-*`, or an arbitrary upstream. The Agent Token is issued by Agent Identity, sent only to GenAuth, checked against current epochs/DataPolicy state, and forwarded to a fixed deployed Provider ref.

Use `tokens issue` only when a caller explicitly needs the atomic Token operation. Omit `--show-token` by default. Never paste the resulting Token into another host or persist it.

When a program truly needs the raw Token, prefer `tokens issue --exec <program>
--exec-arg <arg>` so the Token exists only in the child process environment.
Use `--show-token` only after the user explicitly accepts terminal, shell
history, logging, and screen-recording exposure.

Use `tokens list --agent-id <id>` for lifecycle metadata and `tokens revoke ... --yes` for an explicitly confirmed JTI revocation. Administrators revoke by JTI without an Agent ID; users also provide their owned Agent ID. `tokens inspect --token-stdin` only decodes local header/claims and deliberately reports `signature_verified: false`; it is never authorization evidence.
