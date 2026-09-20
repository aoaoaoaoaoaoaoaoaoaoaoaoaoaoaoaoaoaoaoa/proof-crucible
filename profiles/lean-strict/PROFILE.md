# Strict Lean profile

This profile is the campaign baseline. Campaigns own their copied executable
configuration and reviewed axiom snapshot; `crucible doctor` checks that the
required posture remains visible.

## Severity

Lean code is warning-free and suppression-free:

- every compiler and enabled syntax-linter warning is an error;
- automatic implicit variables are disabled;
- every default mathlib environment linter runs over the whole first-party
  package;
- the bundled `leanchecker` replays every first-party module's declarations
  through Lean's kernel, detecting unchecked environment insertion;
- every certificate theorem has its complete transitive axiom set compared
  byte-for-byte with a reviewed snapshot;
- `sorry`, `admit`, project `axiom`s, `unsafe`, `partial`, `native_decide`,
  `implemented_by`, `run_tac`, external declarations, and equivalent proof
  apertures are forbidden;
- linter suppressions and local relaxations are forbidden.

Kernel acceptance is the floor. Audit definitions for vacuity, quantifier
drift, wrong multiplication order, empty-witness loopholes, coercion loss, and
mismatch with the source statement.

Copy `Verification/Audit.lean` and both source-policy scripts into the campaign
without weakening them. Pin an exact stable Lean toolchain and mathlib revision.
The root `lakefile.lean` owns these minimum options:

```lean
leanOptions := #[
  ⟨`warningAsError, true⟩, ⟨`autoImplicit, false⟩, ⟨`pp.unicode.fun, true⟩,
  ⟨`linter.docPrime, true⟩, ⟨`linter.hashCommand, true⟩, ⟨`linter.oldObtain, true⟩,
  ⟨`linter.style.refine, true⟩, ⟨`linter.style.cdot, true⟩,
  ⟨`linter.style.dollarSyntax, true⟩, ⟨`linter.style.lambdaSyntax, true⟩,
  ⟨`linter.style.longFile, 1500⟩, ⟨`linter.style.longLine, true⟩,
  ⟨`linter.style.missingEnd, true⟩, ⟨`linter.style.setOption, true⟩]
```

## Proof form

Finished proofs expose a static proof DAG rather than the temporal trace of
interactive search.

- Prefer direct proof terms when immediately legible.
- Otherwise use semantically named `have` declarations, `calc` chains,
  explicit constructors, and `refine` applications exposing the outer term.
- Write known theorem arguments explicitly. Naked `apply` sequences are
  exploratory residue.
- Preserve hypotheses; derive normalized forms as new named facts.
- Put automation at leaves whose exact proposition is visible.
- Make cases and induction branches explicit and named.
- Avoid `simp_all`, `at *`, long semicolon pipelines, `all_goals`, `any_goals`,
  goal swapping, and comparable global proof-state mutation unless an
  irreducible final proof requires them.

## Verification transaction

The canonical campaign check must:

1. validate the Git ledger;
2. generate and compile the exact obligation/certificate bridge with
   `crucible lean-audit`;
3. scan every first-party Lean source for forbidden apertures;
4. compile every first-party module with warnings as errors;
5. run every default environment linter, including slow checks;
6. compare the complete certificate axiom reports with the reviewed snapshot;
7. run `LEAN_NUM_THREADS=1 lake env leanchecker <library>...` for every first-party library.

`leanchecker` reuses Lean's kernel; it is not an independent proof assistant.
Keep its library roots synchronized with the complete build/linter scope when
adding or renaming a library. The generated exact-type audit is still required.
Only replay is serialized: each checker task imports its own environment, and
parallel Mathlib imports can exhaust small CI runners. Ordinary builds retain
their normal concurrency. This changes resource use, not verification coverage.

Changing the snapshot is a mathematical review action, never blind generated
cleanup.
