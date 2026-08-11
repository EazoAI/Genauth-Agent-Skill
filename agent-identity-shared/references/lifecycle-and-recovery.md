# Lifecycle and recovery

Use this reference to choose the next command from observed server state. State
names not recognized by the installed CLI contract are a hard stop.

## Lifecycle map

| Resource | Normal progression | Recovery rule |
| --- | --- | --- |
| Agent | created/active -> suspended -> active, or archived | Suspend is reversible; archive is not. |
| Capability | draft -> submitted/pending -> active or rejected | Fetch the current draft and approval; never resubmit an unknown version. |
| Settings | effective plus optional draft -> pending -> effective or rejected | Draft `record_version` is independent of the active version. |
| Credential | active -> rotated or revoked/expired | A local Keychain ref is usable only while the server Credential is active. |
| AuthorizationRequest | pending -> consented -> approved, or denied/cancelled/expired | `CONSENTED` still requires requester exchange; only `APPROVED` with a UserGrant is complete. |
| UserGrant | active -> revoked/expired | Revoke with the current version; reacquisition requires a new authorization. |
| Token | active -> revoked/expired | Prefer short expiry and `providers call`; revoke by exact JTI. |

## Exit-code decision table

| Exit | Meaning | Required response |
| --- | --- | --- |
| 2 | invalid or ambiguous input | Correct the input; do not retry unchanged. |
| 3 | profile, session, or local credential unavailable | Restore the named profile/Keychain item, then re-run preflight. |
| 4 | forbidden or denied | Report the policy/actor denial; never change mode to bypass it. |
| 5 | state mismatch or not found | Re-fetch within the selected user pool and verify the resource ID. |
| 6 | pending | Preserve the request ID and poll only with the documented wait/get command. |
| 7 | retryable dependency | Retry reads at most twice; writes only with the same request/idempotency context. |
| 8 | optimistic concurrency conflict | Fetch current state and use the returned version; never increment locally. |
| 9 | internal/local safety failure | Stop; preserve non-secret request evidence and diagnose. |

## Stable recovery recipes

- `PARTIAL_AGENT_CREATE`: the Agent already exists. Read
  `error.remediation.agent_id`, inspect it, and create the missing Capability
  draft using `agents capability update --version 0`. Never repeat `agents
  create` with the same identifier.
- `AMBIGUOUS_PERMISSION_MERGE`: choose exactly one of file permissions,
  `--append-permission`, or `--replace-permissions`; present the resulting full
  set before retrying.
- `USER_POOL_SELECTION_REQUIRED` or `USER_POOL_NOT_MANAGEABLE`: select a real
  manageable pool by matching its returned name/domain to its ID. For an
  existing profile, run `auth list-user-pools` before `auth select-user-pool`;
  never ask the user to choose from bare IDs or edit profile storage directly.
- `FORBIDDEN_USER_AUTHORIZATION_MODE`: a member attempted another-user or
  silent authorization. Use self explicit authorization, or switch to a real
  administrator profile after confirming intent.
- `AUTHORIZATION_PENDING`: keep the authorization request ID and use
  `authorizations wait` or `authorizations get`. Do not create duplicates merely
  because the browser is still open.
- `AUTHORIZATION_DENIED`: terminal. Report the denial and do not silently retry
  with a different mode or broader permission set.
- `PKCE_NOT_FOUND` or `AUTHORIZATION_URL_NOT_FOUND`: the local one-time context
  cannot safely complete the request. Inspect/cancel the existing request and
  start a new explicit request only with user confirmation.
- `CREDENTIAL_NOT_FOUND` or `INVALID_CREDENTIAL_REFERENCE`: compare
  `credentials list --agent-id <id>` with the exact Keychain ref. Never request
  or reconstruct the Client Secret.
- `SECRET_STORE_UNAVAILABLE`: stop secret-producing operations. Repair the OS
  secret store and verify with `doctor`; do not fall back to files or stdout.
- `CONFIRMATION_REQUIRED`: show the exact target and impact, obtain explicit
  confirmation, then repeat with `--yes`. Confirmation never carries across a
  changed target or version.
- `CONFLICT`: re-fetch the affected resource and use its current server version.

## Safe resume order

After interruption, run read-only commands in this order:

1. `version`, `doctor`, and the named profile's `auth status`.
2. `agents get`, `agents settings get`, and `agents readiness`.
3. relevant `approvals get/list` if a change was submitted.
4. `credentials list` without reading Keychain secrets.
5. `authorizations get` and `grants list`.
6. `tokens list` and `audit list` when runtime evidence is needed.

Resume from observed state. Never rerun all writes from the beginning.
