---
name: proof-crucible
description: "Work in a Proof Crucible mathematical campaign: recover its Git ledger, claim a formal obligation, produce a strictly Lean-checked certificate or withdrawal, synchronize concurrent agents, and project the frontier. Use whenever a repository pins Proof Crucible or contains crucible.toml."
---

# Proof Crucible

The protected default branch is the record. Never create a parallel task list,
database, or ambient research log. Load the pinned protocol at
[`protocol/1/PROTOCOL.md`](../../../protocol/1/PROTOCOL.md) before changing a
campaign ledger.

## Enter a campaign

1. If `.crucible` is absent, run `git submodule update --init --recursive`.
2. Run `.crucible/bin/crucible doctor` and stop on a failed invariant.
3. Read the campaign's `AGENTS.md`, `CAMPAIGN.md`, `crucible.toml`, committed
   source synopses, and `.crucible/bin/crucible frontier`.
4. If the campaign names an immediate step, take it. Otherwise choose the
   highest-leverage ready obligation whose prerequisites you understand.

Read `references/` only after checking its local catalogue and sidecars. It is
an ignored ad-fontes corpus. Never add anything beneath it to Git. Durable,
public-safe understanding belongs in a committed `sources/` synopsis; source
bytes, local digests and paths, private links, credentials, correspondence, and
raw model transcripts do not.

## Open work before doing it

An unrecorded proof search is invisible and may duplicate another contributor.
Before material work:

1. fetch and reconcile with the current default branch;
2. confirm the obligation remains ready;
3. add exactly one `attempt` event in its own logical change;
4. run `.crucible/bin/crucible check`;
5. submit it through the campaign's required checks and wait for its squash
   commit to reach the default branch.

Only the merged attempt SHA owns the work. If a concurrent attempt wins, delete
the losing branch event, choose another obligation, and do not preserve a
duplicate withdrawal.

## Formalize

An obligation must already name a closed Lean term of type `Prop`. Prove that
exact term or its negation; do not weaken it, change quantifiers, add hidden
assumptions, or silently repair the proposition during the proof. A defective
translation becomes a new obligation with explicit provenance.

Use the campaign's canonical strict check throughout. Finished proofs expose a
static proof DAG: named intermediate facts, `calc` chains, explicit constructors
and visible automation leaves. Remove exploratory goal-state choreography.

Before certifying, generate the ledger/type bridge and run the complete gate:

```console
.crucible/bin/crucible lean-audit --output .lake/build/crucible/LedgerAudit.lean
scripts/check.sh
```

## Close every merged attempt

- Add a `certificate` only when the theorem has exactly the target proposition
  or its negation and the complete gate passes.
- Add a `withdrawal` when the approach failed, was blocked, or was abandoned.
- Promote reusable mathematics found during failure into its own obligation and
  certificate. Withdrawal prose is not mathematical evidence.
- Add exactly one event per node commit and never modify an existing event.

After the closing node reaches the default branch, fetch again and choose the
next ready obligation. Continue until the requested boundary, budget, or a real
external blocker ends the run.

## Synchronization

Strict up-to-date required checks are the lock. Reconcile a stale branch and run
the validator again. Never resolve a duplicate-attempt rejection by adding a
secondary lock, editing history, or weakening validation. Any trusted
contributor may close an abandoned live attempt with a withdrawal whose reason
states the evidence for abandonment.

The dashboard is read-only:

```console
.crucible/bin/crucible render --output _site
```

It never owns status or accepts mutations.
