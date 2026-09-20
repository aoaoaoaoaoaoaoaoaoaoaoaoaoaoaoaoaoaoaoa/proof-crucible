# Formal proof campaign

Initialize the pinned protocol distribution before all campaign work:

```console
git submodule update --init --recursive
.crucible/bin/crucible doctor
```

Read and follow `$proof-crucible`. The skill is pinned through `.crucible` and
exposed at `.agents/skills/proof-crucible`. Read `CAMPAIGN.md` for the objective
and mandatory first step, then ground through `.crucible/bin/crucible frontier`.
If the frontier is empty, the first ledger node is the obligation specified by
`CAMPAIGN.md`: its commit adds a public-safe source synopsis, a dedicated Lean
module containing the closed proposition, and exactly one obligation event.

## Lean

Read `.crucible/profiles/lean-strict/PROFILE.md` before proof work. The campaign
must keep that complete severity, environment-linter, source-policy, exact-type,
and transitive-axiom posture. `scripts/check.sh` is the canonical gate. Do not
weaken it, use proof apertures, or promote an informal claim merely because its
translation compiles.

## Sources

`references/` is the ignored local ad-fontes corpus. Before retrieving a work,
search its local catalogue and sidecars. Retain each lawful source once with an
exact artifact, same-stem neutral synopsis, digest, and catalogue entry. Never
force-add anything beneath `references/`.

Commit a public-safe source synopsis under `sources/` whenever a reference
enters the campaign's durable mathematical basis. It records citation, stable
identity, canonical public location, exact version/status, inspection basis,
neutral synopsis, hazards, and project use. It does not contain source bytes,
local paths or digests, private links, credentials, correspondence, or raw
model output.

## Git

Every ledger node is the squash commit that first adds one event. Existing
events are immutable. Open and merge an attempt before beginning material proof
work; close every merged attempt with a certificate or withdrawal. Strict
up-to-date required checks are the only lock.
