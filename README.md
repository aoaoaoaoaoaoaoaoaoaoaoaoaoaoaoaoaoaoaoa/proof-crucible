# Proof Crucible

Proof Crucible is a Git-native protocol for concurrent, formally checked
mathematical research. A campaign records formal obligations, exclusive proof
attempts, Lean certificates, and withdrawals as append-only Git commits. Git
owns truth; the validator, Codex skill, frontier view, and static DAG are
projections.

## Campaign integration

Pin this repository as a submodule and expose its skill at Codex's repository
skill path:

```console
git submodule add https://github.com/aoaoaoaoaoaoaoaoaoaoaoaoaoaoaoaoaoaoaoa/proof-crucible.git .crucible
mkdir -p .agents/skills
ln -s ../../.crucible/.agents/skills/proof-crucible .agents/skills/proof-crucible
cp .crucible/campaign-template/crucible.toml .
cp .crucible/campaign-template/AGENTS.md .
mkdir -p ledger/events sources references
printf '/references/\n/_site/\n' >> .gitignore
git add .gitmodules .crucible .agents AGENTS.md crucible.toml .gitignore ledger sources
```

Then adapt the campaign name and Lean package, install the strict profile, and
run:

```console
.crucible/bin/crucible doctor
.crucible/bin/crucible frontier
```

A non-recursive clone begins with:

```console
git submodule update --init --recursive
```

The gitlink pins exact bytes. Signed release tags describe distribution
versions; campaign correctness never depends on a mutable tag or branch.

## Distribution

- [`protocol/1/PROTOCOL.md`](protocol/1/PROTOCOL.md) is the normative event and
  synchronization contract.
- [`.agents/skills/proof-crucible/SKILL.md`](.agents/skills/proof-crucible/SKILL.md)
  is the Codex operating method.
- `bin/crucible` validates and projects a campaign without third-party Python
  packages.
- `profiles/lean-strict/` carries the formal verification baseline.
- `campaign-template/` carries the small campaign-owned bootstrap.

Run `scripts/check` to verify the distribution.

