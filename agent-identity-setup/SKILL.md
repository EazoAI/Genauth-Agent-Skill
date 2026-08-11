---
name: agent-identity-setup
version: 1.0.0
description: "Verify Agent Identity CLI installation, CLI/server contract compatibility, local Skill links, profile context, user-pool selection, and OS secret-store readiness without mutating remote resources."
metadata:
  requires:
    bins: ["agent-identity"]
---

# Set up and verify Agent Identity tooling

Read [`../agent-identity-shared/SKILL.md`](../agent-identity-shared/SKILL.md)
completely. This Skill is read-only except for an explicitly requested login,
profile selection, or local Skill installation.

## Verify the CLI contract

```bash
command -v agent-identity
agent-identity version --output json --non-interactive
agent-identity --help
```

Require API `agent-identity.cli/v1` and server contract
`genauth-agent-identity-v1`. Do not use `agent-identity --version`; the supported
interface is the `version` subcommand.

When working from the source repository, run its companion check:

```bash
AGENT_IDENTITY_CLI="$(command -v agent-identity)" ./scripts/verify-cli-contract.sh
```

## Verify profiles and local prerequisites

```bash
agent-identity config list-profiles --output json --non-interactive
agent-identity --profile <name> auth status --output json --non-interactive
agent-identity --profile <name> doctor --output json --non-interactive
```

Check that the selected profile has the intended login type, subject, GenAuth
HTTPS endpoint, and selected user pool. `doctor` must report the OS secret store
as available and GenAuth as reachable. Never inspect profile files or Keychain
values to prove authentication.

## Verify local Skill installation

Each `agent-identity-*` entry installed under the agent's Skill directory must
be a link or package pointing to the matching directory in this repository.
Do not copy only the thin intent Skills: composed domain Skills and the shared
references are mandatory. After adding or updating Skills, start a fresh agent
session so Skill discovery is reloaded, then invoke `agent-identity-user-journey`
for an end-to-end test.
