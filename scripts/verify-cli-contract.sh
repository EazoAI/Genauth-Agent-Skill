#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(CDPATH= cd -- "$script_dir/.." && pwd)"
cli="${AGENT_IDENTITY_CLI:-}"

if [ -z "$cli" ]; then
  cli="$(command -v agent-identity || true)"
fi
if [ -z "$cli" ] || [ ! -x "$cli" ]; then
  echo "FAIL: set AGENT_IDENTITY_CLI to an executable agent-identity binary" >&2
  exit 1
fi

failures=0
checks=0

pass() {
  checks=$((checks + 1))
  printf 'OK   %s\n' "$1"
}

fail() {
  checks=$((checks + 1))
  failures=$((failures + 1))
  printf 'FAIL %s\n' "$1" >&2
}

command_help() {
  command_text="$1"
  # All manifest entries are fixed trusted words maintained in this repository.
  # shellcheck disable=SC2086
  "$cli" $command_text --help 2>&1
}

check_command() {
  command_text="$1"
  if command_help "$command_text" >/dev/null; then
    pass "command: $command_text"
  else
    fail "missing command: $command_text"
  fi
}

check_flag() {
  command_text="$1"
  flag="$2"
  if command_help "$command_text" | grep -Fq -- "$flag"; then
    pass "flag: $command_text $flag"
  else
    fail "missing flag: $command_text $flag"
  fi
}

version_json="$("$cli" version --output json --non-interactive 2>/dev/null || true)"
if printf '%s' "$version_json" | grep -Fq '"api_version":"agent-identity.cli/v1"'; then
  pass "CLI API version agent-identity.cli/v1"
else
  fail "CLI API version is not agent-identity.cli/v1"
fi
if printf '%s' "$version_json" | grep -Fq '"server_contract":"genauth-agent-identity-v1"'; then
  pass "server contract genauth-agent-identity-v1"
else
  fail "server contract is not genauth-agent-identity-v1"
fi

commands='version
doctor
config list-profiles
config use-profile
auth status
auth login
auth refresh
auth logout
auth switch-user-pool
permissions list
permissions get
agents create
agents list
agents get
agents capability update
agents submit
agents readiness
agents settings get
agents settings update
agents settings submit
agents suspend
agents resume
agents delete
approvals list
approvals get
approvals approve
approvals reject
credentials create
credentials list
credentials rotate
credentials revoke
authorizations create
authorizations get
authorizations wait
authorizations consent
authorizations exchange
authorizations deny
authorizations cancel
authorizations list-grants
authorizations revoke
tokens issue
tokens list
tokens inspect
tokens revoke
api call
audit list'

while IFS= read -r command_text; do
  [ -n "$command_text" ] && check_command "$command_text"
done <<EOF
$commands
EOF

flag_contracts='auth login|--admin
auth login|--profile-name
auth login|--user-pool-id
agents create|--owner-user-id
agents create|--application-id
agents create|--permission-id
agents capability update|--version
agents submit|--version
agents settings update|--version
approvals approve|--version
approvals approve|--yes
approvals reject|--reason
approvals reject|--yes
credentials create|--store-keychain
credentials rotate|--yes
credentials revoke|--yes
authorizations create|--user-id
authorizations create|--mode
authorizations create|--yes
authorizations wait|--authorization-id
authorizations revoke|--version
authorizations revoke|--reason
authorizations revoke|--yes
tokens issue|--exec
tokens issue|--show-token
tokens revoke|--jti
tokens revoke|--reason
tokens revoke|--yes
api call|--credential
api call|--grant-id
api call|--provider
api call|--path'

while IFS='|' read -r command_text flag; do
  [ -n "$command_text" ] && check_flag "$command_text" "$flag"
done <<EOF
$flag_contracts
EOF

for skill_file in "$repo_dir"/agent-identity-*/SKILL.md; do
  skill_dir="$(basename "$(dirname "$skill_file")")"
  declared_name="$(sed -n 's/^name: //p' "$skill_file" | head -n 1)"
  if [ "$declared_name" = "$skill_dir" ]; then
    pass "skill metadata: $skill_dir"
  else
    fail "skill metadata mismatch: $skill_dir declares $declared_name"
  fi
done

if rg -n '(^|[[:space:]])curl[[:space:]]|/api/v3/agent-identity|/api/v3/agent-runtime' \
  "$repo_dir"/agent-identity-* --glob 'SKILL.md' >/dev/null; then
  fail "a Skill contains a direct API invocation or route"
else
  pass "Skills contain no direct Agent Identity/Runtime API invocation"
fi

if [ "$failures" -ne 0 ]; then
  printf 'SUMMARY checks=%s failures=%s\n' "$checks" "$failures" >&2
  exit 1
fi

printf 'SUMMARY checks=%s failures=0\n' "$checks"
