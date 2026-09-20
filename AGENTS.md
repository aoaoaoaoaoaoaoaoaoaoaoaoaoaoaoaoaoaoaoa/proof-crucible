# Proof Crucible

This repository owns the Proof Crucible protocol, its reference validator,
the repository-local Codex skill, and campaign scaffolding. A campaign pins an
exact commit of this repository at `.crucible`; the campaign's Git history,
not this repository, owns its mathematical ledger.

Protocol 1 is frozen. A change that alters the validity or meaning of a
Protocol 1 event requires a new protocol directory and event version. Do not
silently widen its schema or reinterpret an existing field.

Run `scripts/check` after changing the validator, schema, skill, dashboard, or
template. Keep the Python implementation standard-library-only. The dashboard
is a read-only Git projection; it must not acquire mutable state.

The strict Lean profile is derived from the verification posture in
`/home/main/programming/projects/math`. Do not weaken it for convenience.
