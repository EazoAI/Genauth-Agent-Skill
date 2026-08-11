---
name: agent-identity-call-provider
version: 2.0.0
description: "Call an approved fixed Provider route through GenAuth using an in-memory Agent Identity Token."
metadata:
  requires:
    bins: ["genauth-agent"]
---

# Call a Provider

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md) and [`../agent-identity-authorization-runtime/SKILL.md`](../agent-identity-authorization-runtime/SKILL.md) completely.

Use `genauth-agent providers call` with a keychain Credential ref, active UserGrant, exact audience, fixed Provider key, method, and normalized path. Never accept an arbitrary host, URL, caller Authorization/Cookie, or trusted GenAuth header. Report gateway, decision, and Provider errors as separate layers.

Before calling, verify Agent readiness, server-active Credential metadata, and
the exact UserGrant match. Do not read the Keychain secret or issue a visible
Token as a preflight. Validate that the path begins with one `/`, contains no
dot-segment traversal, and that a request body comes from an explicit JSON file.
Return `kind`, request ID, Provider status/result, and a layer classification;
never include generated authorization headers.
