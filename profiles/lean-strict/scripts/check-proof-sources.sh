#!/usr/bin/env bash
set -euo pipefail

(( $# > 0 )) || { printf 'no proof sources supplied\n' >&2; exit 1; }
for source in "$@"; do
  [[ -f "$source" ]] || { printf 'missing proof source: %s\n' "$source" >&2; exit 1; }
done
reject() {
  local pattern="$1" message="$2" status=0
  shift 2
  rg -n "$pattern" -- "$@" || status=$?
  (( status == 1 )) && return 0
  printf '%s (scan status %s)\n' "$message" "$status" >&2
  exit 1
}
reject '\b(sorry|admit|axiom|native_decide|unsafe|partial|implemented_by|run_tac|sorryAx|ofReduceBool|extern)\b|@\[nolint' \
  'forbidden proof escape or unreadable source' "$@"
reject 'set_option[[:space:]]+(autoImplicit[[:space:]]+true|warningAsError[[:space:]]+false|linter\.[^[:space:]]+[[:space:]]+false)' \
  'forbidden Lean strictness relaxation or unreadable source' "$@"
