# GenAuth Agent Identity Skill Instructions

- Skills orchestrate the `genauth-agent` CLI and never call Agent Identity or
  GenAuth APIs directly.
- Keep `agent-identity-shared` as the mandatory trust-boundary and output
  contract for all composed Skills.
- Never instruct an agent to reveal, read back, or persist Keychain secrets,
  authorization codes, Client Secrets, or full Agent access tokens.
- Keep administrator user-pool selection explicit. CLI member login is
  temporarily unavailable; target users complete explicit consent in the
  GenAuth browser. Preserve separation of duties for ordinary requesters; only the current user-pool
  root administrator may approve their own request through server-verified
  identity context, and self-rejection remains forbidden.
- Every command shown in a Skill must be verified against the current CLI help
  before release.
