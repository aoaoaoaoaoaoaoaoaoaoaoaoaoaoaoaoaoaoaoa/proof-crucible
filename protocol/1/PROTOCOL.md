# Proof Crucible Protocol 1

## Authority

The protected `main` branch is the durable campaign record. Ledger events are
append-only files whose introducing commits are graph nodes. Remote
`attempt/<obligation-id>` branches are the live claim set. Filesystem state,
pull-request metadata, CI records, local databases, dashboards, and model
transcripts are not authorities.

Git is tamper-evident rather than absolutely immutable. A conforming host blocks
`main` force pushes and deletion, requires linear history and strict status
checks, admits campaign changes through squash-merged pull requests, and deletes
merged branches.

## Names

- **campaign**: one repository and mathematical objective;
- **obligation**: an exact proposition represented by a closed Lean term of
  type `Prop`, not yet settled;
- **attempt branch**: the exclusive live work claim on one obligation;
- **certificate**: a Lean theorem whose type proves or refutes an obligation;
- **withdrawal**: a durable account of an approach closed without a result;
- **node**: the commit that first adds exactly one event file.

Only a certificate is a result. Mathematical information recovered from a
failed search must become an obligation and certificate; withdrawal prose does
not establish it.

## What Git already owns

Git commit IDs identify nodes. Git commits carry contributor identity and time.
Branches carry live claims. Pull requests carry review and closure. Required
checks carry admission. Signed tags identify distribution releases, and a
campaign's `.crucible` gitlink pins the exact distribution.

The event ledger stores only mathematical facts Git cannot infer: exact
propositions, source provenance, proof certificates, failed approaches, and
semantic dependency edges. Commit ancestry is chronology, not mathematical
dependency, so `requires` remains explicit. Git notes are excluded: they are
mutable, omitted by ordinary fetches, and too easy to lose.

## Storage

Events live directly under `ledger/events/` as UTF-8 JSON files. Each event:

1. conforms exactly to `event.schema.json`, which is normative for event syntax;
2. is added by a commit that adds no other event;
3. is never modified, renamed, copied, or deleted;
4. refers to earlier nodes by their full 40- or 64-hexadecimal commit IDs;
5. uses committed, repository-relative paths for every source synopsis.

The filename is lowercase kebab-case ending in `.json`. No subdirectories are
allowed beneath `ledger/events/`. The node ID is derived from Git and never
appears inside its event. All graph references point backward, so a conforming
history is acyclic by construction. Ordinary maintenance commits and attempt
claim commits are not nodes. The reference validator owns Git, repository, and
state-transition laws not expressible in JSON Schema.

## Events

### Obligation

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
remote attempt branch.

### Certificate

```json
{
  "protocol": 1,
  "kind": "certificate",
  "target": "0123456789abcdef0123456789abcdef01234567",
  "approach": "Reduce the inverse construction to the bounded normal form.",
  "polarity": "proves",
  "module": "Hessian.Results.DegreeFive",
  "theorem": "Hessian.degreeFiveConjecture_proved",
  "proof": "Hessian/Results/DegreeFive.lean",
  "requires": [],
  "summary": "The reduction discharges the remaining inversion case."
}
```

`polarity` is `proves` or `refutes`. The theorem's type must be definitionally
equal to the target proposition or its negation. The certificate commit adds or
changes `proof`, and `verification/axioms.txt` must contain the named theorem.
`requires` contains only prior certificate nodes. The certificate settles the
obligation. `approach` preserves the experiment whose branch disappears after
merge.

### Withdrawal

```json
{
  "protocol": 1,
  "kind": "withdrawal",
  "target": "0123456789abcdef0123456789abcdef01234567",
  "approach": "Reduce the inverse construction to the bounded normal form.",
  "reason": "The reduction assumes invertibility absent from the target."
}
```

The target must be a prior unsettled obligation. A withdrawal preserves a
failed approach but does not settle its target; after the branch is deleted,
the obligation is ready again. Several sequential withdrawals may therefore
target one obligation.

## Attempt branches

The canonical live claim for obligation `<id>` is the remote ref
`refs/heads/attempt/<id>`, where `<id>` is the obligation's full commit ID. Its
first commit is empty, descends from current `origin/main`, describes the
approach in its body, and carries this trailer:

```text
Crucible-Obligation: <id>
```

Creation is one compare-and-swap push whose expected old value is absence:

```console
git push --force-with-lease=refs/heads/attempt/<id>: origin \
  <claim-commit>:refs/heads/attempt/<id>
```

This use of `--force-with-lease` cannot overwrite a winner: the empty expected
value permits creation only while the ref does not exist. `crucible claim`
constructs this transaction. First successful push owns the work; a loser
chooses another obligation. There are no lock files, leases, clocks, actors,
heartbeats, or duplicate claim events.

Keep the branch linear. After the claim commit, accumulate the finished proof
and exactly one certificate event in one result commit, or one withdrawal event
in one result commit. Push normally, open a pull request to `main`, and let
required checks admit a squash merge. The host deletes the merged branch. The
squash commit becomes the durable node while its event preserves the approach.

An abandoned live claim is resolved by a trusted contributor checking out that
same branch, adding a withdrawal, and completing its pull request. A branch is
never deleted merely because it is old.

## Agent transaction

An agent:

1. fetches `main` and `refs/heads/attempt/*`, then makes local `main` exactly
   match `origin/main`;
2. validates the campaign and chooses a ready obligation;
3. runs `crucible claim <id> --approach '<method>'`;
4. performs the formal work without pushing unrelated checkpoint commits;
5. adds the proof and certificate, or the withdrawal, as one result commit;
6. pushes, opens a pull request, and enables squash auto-merge;
7. fetches again after closure and selects the next ready obligation.

The dashboard is a read-only projection of durable `main` nodes overlaid with
the locally fetched remote attempt refs. It never owns status.

## Formal boundary

The generated ledger audit imports every obligation and certificate module,
checks each obligation constant is a closed term of type `Prop`, and checks
every certificate theorem is definitionally equal to the target proposition or
its negation. The campaign's strict Lean profile then compiles this audit
alongside its complete warning, source-policy, environment-linter, and
transitive-axiom checks.

Lean verifies the encoded proposition, not the faithfulness of its translation
from prose. Obligation pages and source synopses keep that seam visible.

## References

The repository-local `references/` corpus is ignored in full. It may contain
exact artifacts, neutral ad-fontes sidecars, digests, and a local catalogue.
Committed `sources/` files are public-safe synopsis projections: citation,
identity, canonical public location, version, inspection basis, neutral account,
hazards, and project use. They contain no source bytes, local artifact paths or
digests, private links, credentials, private correspondence, or raw model
transcripts.
