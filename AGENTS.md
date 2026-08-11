# GenAuth Agent Identity Skill Instructions

- Skills orchestrate the `agent-identity` CLI and never call Agent Identity or
  GenAuth APIs directly.
- Keep `agent-identity-shared` as the mandatory trust-boundary and output
  contract for all composed Skills.
- Never instruct an agent to reveal, read back, or persist Keychain secrets,
  authorization codes, Client Secrets, or full Agent access tokens.
- Keep administrator and member user-pool selection explicit and preserve the
  no-self-approval rule.
- Every command shown in a Skill must be verified against the current CLI help
  before release.
