# Automation and handoff contract

This reference applies to every multi-command Agent Identity workflow.

## Actor profiles

Use a separate named CLI profile for each human role:

- `agent-owner`: creates and submits the company Agent.
- `agent-approver`: reviews and decides capability or settings requests.
- `agent-admin`: performs administrator-only target-user or silent authorization.

Every CLI profile is currently authenticated as a tenant administrator. Target
users complete explicit authorization in the GenAuth browser; do not create or
request a CLI member-login profile.

One person may hold several business roles, but the owner/requester cannot be
the approver for their own request. Before each write, run:

```bash
genauth-agent --profile <profile> auth status --output json --non-interactive
```

Verify `login_type`, subject identity, `selected_user_pool_name`, and
`selected_user_pool_id`. All actors
participating in one journey must intentionally select the same user pool.
Never switch the global default profile merely to save typing in an automated
workflow.

## JSON envelope

Every non-browser command must return one JSON object shaped as:

```json
{
  "api_version": "genauth-agent.cli/v1",
  "kind": "ResourceKind",
  "data": {},
  "request_id": "optional-server-request-id",
  "warnings": []
}
```

The `version` command must additionally report
`data.command_contract=genauth-agent.commands/v2`. Failures use `error.code` and can include `error.remediation`. Read identifiers
only from `data` or `error.remediation`; never scrape human text. Treat a
missing field, unexpected `kind`, incompatible `api_version`, or an incompatible
command contract as a stop.

## Checkpoint ledger

Keep a redacted, process-local checkpoint ledger while the journey is active:

| Step | Retain | Never retain |
| --- | --- | --- |
| Login | profile name, login type, subject ID, user-pool name and ID | session Token |
| Agent create | Agent ID, identifier | hidden server credentials |
| Capability | draft/active record version, audience, permission IDs | inferred version |
| Approval | approval ID, approval version, requester ID, type | approval links containing secrets |
| Settings | draft/active record version, effective values | guessed defaults |
| Credential | credential ID, `keychain://` secret reference, expiry | Client Secret |
| Authorization | authorization request ID, URL for the target human, status | PKCE verifier, authorization code |
| UserGrant | grant ID, subject, audience, permissions, version, expiry | raw consent code |
| Token | JTI and expiry only when returned as metadata | full access Token |
| Provider call | request ID, HTTP/result classification | Authorization header |

The ledger is a resume aid, not authority. Re-fetch current server state before
every mutating command and replace stale versions with the fetched version.

## Human handoffs

Every handoff must state:

1. the acting profile and role;
2. the selected user pool;
3. the exact non-secret resource ID;
4. the decision required from the human;
5. how success will be verified.

For explicit authorization, send only the returned `authorization_url` to the
target user. For approval, have the approver fetch the request using their own
profile; do not ask them to trust a requester-provided summary.

## Completion evidence

Do not report the overall journey as complete until all of these are true:

- Agent Capability is active.
- effective Agent settings are known and acceptable.
- Agent readiness has no blocker after an active Credential exists.
- an active UserGrant matches the subject, audience, and permission set.
- `providers call` returned a Provider response, or the user explicitly requested
  only Token issuance and that operation succeeded.

Report each condition separately. Approval success alone is not runtime
readiness, and Token issuance alone is not Provider success.
