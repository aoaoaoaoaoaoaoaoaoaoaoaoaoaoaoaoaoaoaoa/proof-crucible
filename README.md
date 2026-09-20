# Proof Crucible

Proof Crucible is a Git-native protocol for concurrent, formally checked
mathematical research. A campaign records formal obligations, exclusive proof
results, and failed approaches as append-only Git commits. Deterministic remote
branches are the live claims. Git owns identity, time, synchronization,
admission, and version pins; the validator, Codex skill, frontier view, and
static DAG are projections.

## Campaign integration

Pin this repository as a submodule and expose its skill at Codex's repository
skill path:

```console
mkdir my-campaign && cd my-campaign
git init -b main
git submodule add https://github.com/aoaoaoaoaoaoaoaoaoaoaoaoaoaoaoaoaoaoaoa/proof-crucible.git .crucible
.crucible/bin/crucible init --campaign my-campaign
git add . && git commit -m 'Initialize Proof Crucible campaign'
```

Edit `CAMPAIGN.md` so its immediate frontier names an executable first step,
push the repository, let the initial `check` workflow complete, then apply the
shipped branch protection:

```console
.crucible/bin/crucible doctor
.crucible/bin/crucible frontier
scripts/apply-github-rules
```

Private GitHub campaigns require an account plan that supports branch
protection. If applying the rules fails, the repository is not yet an
autonomous, protocol-conforming campaign: do not silently substitute unchecked
merges or change its visibility. Enable a supporting plan before unattended
multi-user operation.

The check script uses the toolchain installation selected by `elan`; it does
not relocate `ELAN_HOME` or install a second copy of Lean in CI.

`init` installs the repository's shared-Lake-package worktree hook. After a
fresh recursive clone, run `scripts/share-lake-packages.sh --install` once.

A non-recursive clone begins with:

```console
git submodule update --init --recursive
```

The gitlink pins exact bytes. Signed release tags describe distribution
versions; campaign correctness never depends on a mutable tag or branch.

To claim a ready obligation, use its full node ID:

```console
.crucible/bin/crucible claim "$OBLIGATION" --approach 'state the method'
```

The command atomically creates `attempt/$OBLIGATION` only if no contributor has
already created it. The result is closed by a squash-merged certificate or
withdrawal pull request; no custom lock or attempt record exists.

`frontier` and `render` project the checked-out ledger. On an older attempt
branch, fetched claims for later obligations are outside that snapshot and are
not overlaid. Use synchronized `main` for the complete live campaign view.

## Distribution

- [`protocol/1/PROTOCOL.md`](protocol/1/PROTOCOL.md) is the normative event and
  Git synchronization contract.
- [`.agents/skills/proof-crucible/SKILL.md`](.agents/skills/proof-crucible/SKILL.md)
  is the Codex operating method.
- `bin/crucible` validates and projects a campaign without third-party Python
  packages.
- `profiles/lean-strict/` carries the formal verification baseline.
- `campaign-template/` carries the small campaign-owned bootstrap.

Run `scripts/check` for the protocol and validator suite.
`scripts/check-campaign-template` additionally instantiates a fresh campaign and
runs its complete strict Lean transaction.
