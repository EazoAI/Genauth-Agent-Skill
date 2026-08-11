---
name: agent-identity-diagnose
version: 2.0.0
description: "Diagnose Agent Identity CLI profile, user-pool context, readiness, authorization, Token, gateway, and Provider failures without mutating state."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Diagnose Agent Identity

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) completely.

Start with `version`, `doctor`, and the named profile's `auth status`. Read the
shared lifecycle/recovery reference, then follow the first failing layer below.
Do not rotate, revoke, approve, resubmit, retry a write, or edit configuration
while diagnosing.

## Read-only decision tree

1. **CLI contract**

   ```bash
   genauth-agent version --output json --non-interactive
   genauth-agent --profile <profile> doctor --output json --non-interactive
   ```

   Stop on an API/server-contract mismatch. `SECRET_STORE_UNAVAILABLE` is local;
   GenAuth reachability failure is transport/gateway. Do not collapse them.

2. **Identity and user-pool context**

   ```bash
   genauth-agent profiles list --output json --non-interactive
   genauth-agent --profile <profile> auth status --output json --non-interactive
   ```

   Compare expected login type, subject, and pool. A not-found resource in the
   wrong pool is a context failure, not proof that it was deleted.

3. **Agent, Capability, settings, and readiness**

   ```bash
   genauth-agent --profile <profile> agents get --agent-id <id> --output json --non-interactive
   genauth-agent --profile <profile> agents settings get --agent-id <id> --output json --non-interactive
   genauth-agent --profile <profile> agents readiness --agent-id <id> --output json --non-interactive
   ```

   Classify draft/pending/rejected/inactive Capability or settings separately
   from suspension/archive. If pending, inspect the exact approval with
   `approvals get`; do not decide it during diagnosis.

4. **Credential**

   ```bash
   genauth-agent --profile <profile> credentials list --agent-id <id> --output json --non-interactive
   ```

   Compare server-active Credential IDs with the caller's non-secret
   `keychain://` reference. Never open Keychain material. Missing local and
   revoked/expired server credentials are distinct failures.

5. **Authorization request and UserGrant**

   ```bash
   genauth-agent --profile <profile> authorizations get --authorization-id <id> --output json --non-interactive
   genauth-agent --profile <profile> grants list --output json --non-interactive
   ```

   `PENDING` means human action or polling remains; `CONSENTED` means requester
   exchange remains; denial/cancellation/expiry is terminal. For a UserGrant,
   match subject, Agent, audience, permission set, status, version, and expiry.

6. **Token lifecycle**

   ```bash
   genauth-agent --profile <profile> tokens list --agent-id <owned-agent-id> --output json --non-interactive
   ```

   Use returned metadata for expiry/revocation. `tokens inspect --token-stdin`
   may decode a user-supplied Token, but `signature_verified: false` means it is
   not authorization evidence. Never ask the user to paste a Token into chat.

7. **GenAuth decision and fixed Provider**

   Inspect the failed `providers call` error envelope and `request_id`. Classify it as
   GenAuth ingress/transport, Agent Identity Token/signing, current DataPolicy
   decision, fixed Provider routing, or Provider upstream response. Do not test
   an arbitrary Provider URL or add trusted headers.

8. **Audit correlation**

   ```bash
   genauth-agent --profile <profile> audit list --agent-id <id> --output json --non-interactive
   ```

   Correlate action, actor, resource, timestamp, CLI `request_id`, and any
   caller-provided correlation ID. Report observed evidence and the first failing
   layer; recommend a repair separately without executing it.

## Diagnostic report

Return: CLI/server contract, profile role and pool, Agent/readiness state,
Credential metadata state, authorization/UserGrant state, Token metadata state,
first failing layer, request/correlation IDs, and a non-mutating next check.
Redact all session, Credential, PKCE, authorization-code, and Token material.
