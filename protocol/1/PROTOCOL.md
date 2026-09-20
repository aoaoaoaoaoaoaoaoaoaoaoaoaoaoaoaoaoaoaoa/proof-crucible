# Proof Crucible Protocol 1

## Authority

The protected default branch is the sole campaign record. Ledger events are
append-only files whose introducing commits are graph nodes. Filesystem state,
GitHub pull requests, CI records, local databases, dashboards, and model
transcripts are not authorities.

Git is tamper-evident rather than absolutely immutable. A conforming host blocks
default-branch force pushes and deletion, requires a linear history and strict
status checks, and admits campaign changes through squash-merged pull requests.

## Names

- **campaign**: one repository and mathematical objective;
- **obligation**: an exact proposition represented by a closed Lean term of
  type `Prop`, not yet settled;
- **attempt**: the exclusive live work claim on one obligation;
- **certificate**: a Lean theorem whose type proves or refutes an obligation;
- **withdrawal**: an attempt closed without a mathematical result;
- **node**: the commit that first adds exactly one event file.

Only a certificate is a result. Mathematical information recovered from a
failed search must become an obligation and certificate; withdrawal prose does
not establish it.

## Storage

Events live directly under the campaign-configured ledger directory, normally
`ledger/events/`, as UTF-8 JSON files. Each event:

1. conforms exactly to `event.schema.json`, which is normative for event syntax;
2. is added by a commit that adds no other event;
3. is never modified, renamed, copied, or deleted;
4. refers to earlier nodes by their full 40- or 64-hexadecimal commit IDs;
5. uses committed, repository-relative paths for every source synopsis.

The filename is lowercase kebab-case ending in `.json`. No subdirectories are
allowed beneath the ledger directory. The node ID is derived from Git and never
appears inside its event. All graph
references point backward, so a conforming history is acyclic by construction.
Ordinary maintenance commits are not nodes. The reference validator owns Git,
repository, and state-transition laws not expressible in JSON Schema.

## Events

### Obligation

An obligation records the informal statement beside its formal owner:

```json
{
  "protocol": 1,
  "kind": "obligation",
  "title": "Degree-five four-variable Hessian case",
  "statement": "The normalized degree-five case has a polynomial inverse.",
  "module": "Hessian.Obligations.DegreeFive",
  "proposition": "Hessian.degreeFiveConjecture",
  "formalization": "Hessian/Obligations/DegreeFive.lean",
  "requires": [],
  "sources": ["sources/example.md"]
}
```

The obligation commit adds or changes `formalization`, a dedicated Lean source
owning the proposition and any campaign definitions needed to state it. That
file becomes immutable after the obligation node; semantic corrections use a
new file and obligation rather than changing history. `requires` contains only
prior certificate nodes. An obligation is ready when it is unsettled and has no
active attempt.

### Attempt

```json
{
  "protocol": 1,
  "kind": "attempt",
  "target": "0123456789abcdef0123456789abcdef01234567",
  "approach": "Reduce the inverse construction to the bounded normal form.",
  "informed_by": []
}
```

The target must be a ready obligation. At most one live attempt may target an
obligation. An attempt remains live until a certificate or withdrawal closes
it. Protocol 1 has no clocks, leases, or heartbeats.

### Certificate

```json
{
  "protocol": 1,
  "kind": "certificate",
  "target": "0123456789abcdef0123456789abcdef01234567",
  "attempt": "89abcdef0123456789abcdef0123456789abcdef",
  "polarity": "proves",
  "module": "Hessian.Results.DegreeFive",
  "theorem": "Hessian.degreeFiveConjecture_proved",
  "proof": "Hessian/Results/DegreeFive.lean",
  "requires": [],
  "summary": "The reduction discharges the remaining inversion case."
}
```

`polarity` is `proves` or `refutes`. The theorem's type must be definitionally
equal to the target proposition or its negation. The named attempt must be the
target's live attempt. The certificate commit adds or changes `proof`, and the
campaign's reviewed axiom snapshot must contain the named theorem. `requires`
contains only prior certificate nodes. The certificate settles the obligation
and closes the attempt.

### Withdrawal

```json
{
  "protocol": 1,
  "kind": "withdrawal",
  "attempt": "89abcdef0123456789abcdef0123456789abcdef",
  "reason": "The reduction assumes invertibility absent from the target."
}
```

The named attempt must be live. Withdrawal closes it and makes its obligation
ready again. Any trusted contributor may withdraw an abandoned attempt; Git
records who did so.

## Synchronization

The host's strict required checks are the lock. The campaign template supplies
a full-history, recursive-submodule workflow and a repository-rules manifest.
A host applies equivalent rules before admitting contributors. An agent:

1. fetches and rebases onto the latest default branch;
2. chooses a ready obligation;
3. submits one attempt event and enables squash auto-merge;
4. waits until that attempt reaches the default branch before doing proof work;
5. submits one certificate or withdrawal when finished.

If concurrent attempt pull requests target the same obligation, the first may
merge. Every other branch becomes stale; after reconciliation, validation
rejects its now-duplicate attempt. The losing agent abandons that event and
chooses another obligation. No secondary lock or conflict-resolution record
exists.

## Formal boundary

The generated ledger audit imports every obligation and certificate module,
checks each obligation constant is a closed term of type `Prop`, and checks
every certificate theorem is definitionally equal to the target proposition or
its negation. The campaign's strict Lean profile then
compiles this audit alongside its complete warning, source-policy, environment-
linter, and transitive-axiom checks.

Lean verifies the encoded proposition, not the faithfulness of its translation
from prose. Obligation pages and source synopses keep that seam visible.

## References

The repository-local `references/` corpus is ignored in full. It may contain
exact artifacts, neutral ad-fontes sidecars, digests, and a local catalogue.
Committed `sources/` files are public-safe synopsis projections: citation,
identity, canonical public location, version, inspection basis, neutral account,
hazards, and project use. They contain no source bytes, local artifact paths or
digests, private links, credentials, or private correspondence.
