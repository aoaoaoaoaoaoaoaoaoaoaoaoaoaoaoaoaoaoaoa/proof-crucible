from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CRUCIBLE = ROOT / "bin/crucible"


def run(*argv: str | Path, cwd: Path, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [str(argument) for argument in argv],
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    return result


class Campaign:
    def __init__(self, root: Path) -> None:
        self.root = root
        run("git", "init", "-b", "main", cwd=root)
        run("git", "config", "user.name", "Test", cwd=root)
        run("git", "config", "user.email", "test@example.invalid", cwd=root)
        (root / "ledger/events").mkdir(parents=True)
        (root / "sources").mkdir()
        (root / "verification").mkdir()
        (root / "crucible.toml").write_text(
            'protocol = 1\ncampaign = "fixture"\nledger = "ledger/events"\n'
            'lean_profile = "strict"\naxiom_snapshot = "verification/axioms.txt"\n',
            encoding="utf-8",
        )
        (root / ".gitignore").write_text("/references/\n/_site/\n", encoding="utf-8")
        (root / "sources/source.md").write_text("# Source\n", encoding="utf-8")
        (root / "verification/axioms.txt").write_text(
            "'Fixture.sentinel' does not depend on any axioms\n", encoding="utf-8"
        )
        self.commit(
            "bootstrap", ".gitignore", "crucible.toml", "sources/source.md", "verification/axioms.txt"
        )

    def commit(self, message: str, *paths: str) -> str:
        run("git", "add", "--", *paths, cwd=self.root)
        run("git", "commit", "-m", message, cwd=self.root)
        return run("git", "rev-parse", "HEAD", cwd=self.root).stdout.strip()

    def event(self, name: str, event: dict[str, object], *additional_paths: str) -> str:
        path = f"ledger/events/{name}.json"
        (self.root / path).write_text(json.dumps(event, indent=2) + "\n", encoding="utf-8")
        return self.commit(f"{event['kind']}: {name}", path, *additional_paths)

    def obligation(self) -> str:
        (self.root / "Fixture").mkdir(exist_ok=True)
        (self.root / "Fixture/Target.lean").write_text(
            "namespace Fixture\ndef target : Prop := True\nend Fixture\n", encoding="utf-8"
        )
        return self.event(
            "target",
            {
                "protocol": 1,
                "kind": "obligation",
                "title": "Target",
                "statement": "The target proposition holds.",
                "module": "Fixture.Target",
                "proposition": "Fixture.target",
                "formalization": "Fixture/Target.lean",
                "requires": [],
                "sources": ["sources/source.md"],
            },
            "Fixture/Target.lean",
        )

    def attempt(self, target: str, name: str = "attack") -> str:
        return self.event(
            name,
            {
                "protocol": 1,
                "kind": "attempt",
                "target": target,
                "approach": "Construct the witness directly.",
                "informed_by": [],
            },
        )


class ProtocolTests(unittest.TestCase):
    def campaign(self) -> tuple[tempfile.TemporaryDirectory[str], Campaign]:
        temporary = tempfile.TemporaryDirectory()
        return temporary, Campaign(Path(temporary.name))

    def test_valid_certificate_lifecycle_and_lean_bridge(self) -> None:
        temporary, campaign = self.campaign()
        self.addCleanup(temporary.cleanup)
        target = campaign.obligation()
        attempt = campaign.attempt(target)
        (campaign.root / "Fixture/Result.lean").write_text(
            "namespace Fixture\ntheorem target_proved : target := trivial\nend Fixture\n", encoding="utf-8"
        )
        (campaign.root / "verification/axioms.txt").write_text(
            "'Fixture.sentinel' does not depend on any axioms\n"
            "'Fixture.target_proved' does not depend on any axioms\n",
            encoding="utf-8",
        )
        campaign.event(
            "certificate",
            {
                "protocol": 1,
                "kind": "certificate",
                "target": target,
                "attempt": attempt,
                "polarity": "proves",
                "module": "Fixture.Result",
                "theorem": "Fixture.target_proved",
                "proof": "Fixture/Result.lean",
                "requires": [],
                "summary": "A direct witness proves the target.",
            },
            "Fixture/Result.lean",
            "verification/axioms.txt",
        )
        result = run(CRUCIBLE, "--repo", campaign.root, "check", cwd=campaign.root)
        self.assertIn("certificate=1", result.stdout)
        output = Path("build/LedgerAudit.lean")
        run(CRUCIBLE, "--repo", campaign.root, "lean-audit", "--output", output, cwd=campaign.root)
        audit = (campaign.root / output).read_text(encoding="utf-8")
        self.assertIn("example : Prop := @Fixture.target", audit)
        self.assertIn("example : Fixture.target :=", audit)
        self.assertIn("Fixture.target_proved", audit)
        run(CRUCIBLE, "--repo", campaign.root, "render", "--output", "_site", cwd=campaign.root)
        self.assertIn("Fixture.target_proved", (campaign.root / "_site/index.html").read_text(encoding="utf-8"))

    def test_initializer_materializes_complete_campaign(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        run("git", "init", "-b", "main", cwd=root)
        run(CRUCIBLE, "--repo", root, "init", "--campaign", "fixture", cwd=root)
        self.assertIn('campaign = "fixture"', (root / "crucible.toml").read_text(encoding="utf-8"))
        self.assertTrue((root / "scripts/check.sh").is_file())
        self.assertTrue((root / "Verification/Audit.lean").is_file())
        self.assertTrue((root / ".github/workflows/check.yml").is_file())
        self.assertTrue((root / ".agents/skills/proof-crucible").is_symlink())

    def test_concurrent_attempt_is_rejected_after_reconciliation(self) -> None:
        temporary, campaign = self.campaign()
        self.addCleanup(temporary.cleanup)
        target = campaign.obligation()
        campaign.attempt(target, "first")
        campaign.attempt(target, "second")
        result = run(CRUCIBLE, "--repo", campaign.root, "check", cwd=campaign.root, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("duplicates live attempt", result.stderr)

    def test_event_mutation_is_rejected_even_when_current_json_is_valid(self) -> None:
        temporary, campaign = self.campaign()
        self.addCleanup(temporary.cleanup)
        campaign.obligation()
        path = campaign.root / "ledger/events/target.json"
        event = json.loads(path.read_text(encoding="utf-8"))
        event["title"] = "Rewritten target"
        path.write_text(json.dumps(event, indent=2) + "\n", encoding="utf-8")
        campaign.commit("rewrite forbidden event", "ledger/events/target.json")
        result = run(CRUCIBLE, "--repo", campaign.root, "check", cwd=campaign.root, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not append-only", result.stderr)

    def test_dirty_event_is_rejected_instead_of_read_from_worktree(self) -> None:
        temporary, campaign = self.campaign()
        self.addCleanup(temporary.cleanup)
        campaign.obligation()
        path = campaign.root / "ledger/events/target.json"
        event = json.loads(path.read_text(encoding="utf-8"))
        event["title"] = "Uncommitted rewrite"
        path.write_text(json.dumps(event, indent=2) + "\n", encoding="utf-8")
        result = run(CRUCIBLE, "--repo", campaign.root, "check", cwd=campaign.root, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ledger worktree is dirty", result.stderr)

    def test_obligation_formalization_is_immutable(self) -> None:
        temporary, campaign = self.campaign()
        self.addCleanup(temporary.cleanup)
        campaign.obligation()
        path = campaign.root / "Fixture/Target.lean"
        path.write_text("namespace Fixture\ndef target : Prop := False\nend Fixture\n", encoding="utf-8")
        campaign.commit("rewrite target", "Fixture/Target.lean")
        result = run(CRUCIBLE, "--repo", campaign.root, "check", cwd=campaign.root, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("changed after node", result.stderr)

    def test_source_scanner_ignores_prose_but_rejects_kernel_bypass(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        source = root / "Source.lean"
        source.write_text('/-- A partial derivative; the word "axiom" is quoted. -/\ntheorem t : True := trivial\n')
        scanner = ROOT / "profiles/lean-strict/scripts/check-proof-sources.sh"
        run(scanner, source, cwd=root)
        source.write_text("set_option debug.skipKernelTC true in\ntheorem t : True := trivial\n")
        result = run(scanner, source, cwd=root, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("strictness relaxation", result.stderr)


if __name__ == "__main__":
    unittest.main()
