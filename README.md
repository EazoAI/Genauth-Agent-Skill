# Agent Identity Skills

These Skills wrap the `agent-identity` CLI and therefore use GenAuth as the only public ingress.

- `agent-identity-auth`: login, profiles, and user-pool context.
- `agent-identity-agent-management`: DataPolicy discovery, company Agent lifecycle, settings, and approvals.
- `agent-identity-authorization-runtime`: Credential, UserGrant, Token, and Provider calls.
- `agent-identity-shared`: mandatory common JSON, exit-code, trust-boundary, and secret-safety rules.
- `agent-identity-user-journey`: end-to-end multi-role orchestration from login to a Provider call.
- `agent-identity-setup`: CLI, server-contract, profile, and local Skill installation checks.

User-intent entrypoints compose those domain Skills:

- `agent-identity-login`
- `agent-identity-create-agent`
- `agent-identity-approve-agent`
- `agent-identity-authorize-user`
- `agent-identity-call-provider`
- `agent-identity-revoke-access`
- `agent-identity-diagnose`

The intent Skills are deliberately small entrypoints. They must compose the
domain Skills instead of duplicating trust-boundary rules. For a complete first
run, use `agent-identity-user-journey`; for a broken or unknown environment, use
`agent-identity-setup` and then `agent-identity-diagnose`.

## Release verification

Run the executable contract check against the CLI that will be distributed
with these Skills:

```bash
AGENT_IDENTITY_CLI=/path/to/agent-identity ./scripts/verify-cli-contract.sh
```

The check validates the public CLI API/server contract, every command used by
the Skills, and the security-sensitive flags on write operations. It does not
log in or mutate remote state.

Install or package these directories only after the matching CLI version is present on `PATH`.

The Skill directories live at this repository root. Local Codex installation
uses one symbolic link per `agent-identity-*` directory under
`/Users/lucsun-authing/.codex/skills`; the links must point here, not to the
Agent Identity service repository.

Explicit authorization uses a GenAuth-hosted login and consent page. The target
user never talks to Agent Identity directly. Default CLI loopback requests are
completed by the authenticated requester through PKCE-bound polling, including
cross-device consent; registered standard callbacks may still receive a
one-time code. Denial records a terminal audited decision.
