---
name: proof-crucible
description: "Work in a Proof Crucible mathematical campaign: recover its Git ledger, atomically claim a formal obligation, produce a strictly Lean-checked certificate or withdrawal, synchronize concurrent agents through branches, and project the frontier. Use whenever a repository pins Proof Crucible or contains crucible.toml."
---

# Proof Crucible

The protected `main` branch is the durable record. Remote
`attempt/<obligation-id>` branches are the live claim set. Never create a
parallel task list, lock file, status database, or ambient research log. Load
the pinned protocol at `.crucible/protocol/1/PROTOCOL.md` before changing a
campaign ledger.

## Enter a campaign

1. If `.crucible` is absent, run `git submodule update --init --recursive`.
2. Fetch `main` and all attempt refs:

   ```console
   git fetch --prune origin main '+refs/heads/attempt/*:refs/remotes/origin/attempt/*'
   ```

3. Reconcile local `main` exactly with `origin/main`.
4. Run `.crucible/bin/crucible doctor` and stop on a failed invariant.
5. Read `AGENTS.md`, `CAMPAIGN.md`, `crucible.toml`, committed source
   synopses, and `.crucible/bin/crucible frontier`.
6. Take the named immediate step, or the highest-leverage ready obligation whose
   prerequisites you understand.

If the ledger is empty, execute `CAMPAIGN.md`'s immediate frontier. The first
node is an obligation commit containing its source synopsis, dedicated Lean
formalization file, and one event. Merge that node before claiming it.

Read `references/` only after checking its local catalogue and sidecars. It is
an ignored ad-fontes corpus. Never add anything beneath it to Git. Durable,
public-safe understanding belongs in a committed `sources/` synopsis; source
bytes, local digests and paths, private links, credentials, correspondence, and
raw model transcripts do not.

## Claim before material work

Run:

```console
.crucible/bin/crucible claim <full-obligation-sha> --approach '<specific method>'
```

This creates the deterministic `attempt/<full-obligation-sha>` branch with one
empty claim commit and atomically pushes it only if the remote ref is absent.
First successful push owns the work. If the compare-and-swap loses, choose a
different ready obligation. Do not add an attempt event or another lock.

## Formalize

An obligation names a closed Lean term of type `Prop`. Prove that exact term or
its negation; do not weaken it, change quantifiers, add hidden assumptions, or
silently repair the proposition during the proof. A defective translation
becomes a new obligation with explicit provenance.

The obligation's dedicated formalization file is immutable after its node.
Semantic corrections create a new obligation rather than rewriting the old
target. Finished proofs expose a static proof DAG: named intermediate facts,
`calc` chains, explicit constructors, and visible automation leaves. Remove
exploratory goal-state choreography.

Keep the remote branch to the claim commit until the result is ready. Add the
finished proof plus exactly one certificate event in one result commit, or add
one withdrawal event in one result commit. Then generate the ledger/type bridge
and run the complete gate:

```console
.crucible/bin/crucible lean-audit --output .lake/build/crucible/LedgerAudit.lean
scripts/check.sh
```

## Close the attempt branch

- A `certificate` is lawful only when its theorem has exactly the target
  proposition or its negation and the complete gate passes.
- A `withdrawal` records the approach and why it failed, was blocked, or was
  abandoned. It does not settle the obligation.
- Promote reusable mathematics found during failure into its own obligation and
  certificate. Withdrawal prose is not mathematical evidence.
- Add exactly one event per node commit and never modify an existing event.

Push normally, open a pull request to `main`, and enable squash auto-merge.
Required checks admit the result; the squash commit becomes the node; repository
settings delete the branch. Fetch again before choosing more work.

To close an abandoned claim, a trusted contributor checks out the existing
remote attempt branch, adds a withdrawal result commit, and completes the same
pull-request transaction. Never delete a claim based only on age.

## Projection

```console
.crucible/bin/crucible frontier
.crucible/bin/crucible render --output _site
```

These read durable nodes and locally fetched remote attempt refs. They never own
or mutate status. Git commits provide identity and time; signed tags and the
campaign gitlink provide distribution versioning.
