from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


TOOL_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_DIR))

from release_workflow import ReleaseError, ReleaseWorkflow  # noqa: E402


class ReleaseWorkflowTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="release-test-")
        self.addCleanup(self.temp.cleanup)
        base = Path(self.temp.name)
        self.remote = base / "remote.git"
        self.github_remote = base / "github.git"
        self.root = base / "repo"
        self._run(["git", "init", "--bare", self.remote], cwd=base)
        self._run(["git", "init", "--bare", self.github_remote], cwd=base)
        self._run(["git", "init", "--initial-branch=main", self.root], cwd=base)
        self._run(["git", "config", "user.name", "Release Test"], cwd=self.root)
        self._run(["git", "config", "user.email", "release@example.invalid"], cwd=self.root)

        self._write("pubspec.yaml", "name: fixture\nversion: 1.0.1+2\n")
        self._write(
            "tool/release-config.json",
            json.dumps(
                {
                    "displayName": "Fixture",
                    "githubRepository": "example/fixture",
                    "androidPackage": "example.fixture",
                    "androidAbiVersionCodeOffset": 2000,
                    "apkFilename": "fixture-arm64.apk",
                    "expectedCertificateSha256": "abc",
                    "mainBranch": "main",
                    "canonicalRemote": "origin",
                    "githubRemote": "github",
                    "documentationBranch": "gh-pages",
                    "monitoredCodePaths": ["lib/"],
                }
            ),
        )
        self._write("docs/releases/1.0.1.md", "# 1.0.1\n")
        self._write("docs/guide.md", "# Guide\n")
        self._write(
            "release/fragments/1.0.1/fixture.json",
            json.dumps(
                {
                    "id": "fixture",
                    "summary": "Fixture change.",
                    "audience": "internal",
                    "releaseNote": "Fixture release note.",
                    "docs": {
                        "impact": "updated",
                        "paths": ["docs/guide.md"],
                        "reason": "",
                    },
                    "screenshots": [],
                }
            ),
        )
        self.manifest = {
            "version": "1.0.1",
            "versionCode": 2,
            "releaseNotes": "docs/releases/1.0.1.md",
            "docsImpact": "updated",
            "updatedGuidePaths": ["docs/guide.md"],
            "noDocsReason": "",
            "changeFragments": ["release/fragments/1.0.1/fixture.json"],
            "outstandingScreenshots": [],
        }
        self._write("release/manifests/1.0.1.json", json.dumps(self.manifest))
        self._write("lib/app.dart", "void main() {}\n")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "fixture"], cwd=self.root)
        self._run(["git", "remote", "add", "origin", self.remote], cwd=self.root)
        self._run(
            ["git", "remote", "add", "github", self.github_remote], cwd=self.root
        )
        self._run(["git", "push", "-u", "origin", "main"], cwd=self.root)

    def _run(self, command: list[object], *, cwd: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(value) for value in command],
            cwd=cwd,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def _write(self, relative: str, content: str) -> None:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def _workflow_after_preflight(self) -> ReleaseWorkflow:
        workflow = ReleaseWorkflow(self.root, dry_run=True)
        workflow._preflight_git()
        return workflow

    def test_canonical_and_github_remotes_must_be_distinct(self) -> None:
        config_path = self.root / "tool/release-config.json"
        config = json.loads(config_path.read_text(encoding="utf-8"))
        config["githubRemote"] = config["canonicalRemote"]
        config_path.write_text(json.dumps(config), encoding="utf-8")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "invalid remotes"], cwd=self.root)
        self._run(["git", "push"], cwd=self.root)

        with self.assertRaisesRegex(ReleaseError, "must be different"):
            ReleaseWorkflow(self.root, dry_run=True)._preflight_git()

    def test_missing_github_remote_is_rejected(self) -> None:
        self._run(["git", "remote", "remove", "github"], cwd=self.root)

        with self.assertRaisesRegex(ReleaseError, "Configured Git remote does not exist"):
            ReleaseWorkflow(self.root, dry_run=True)._preflight_git()

    def test_dirty_working_tree_is_rejected(self) -> None:
        self._write("untracked.txt", "dirty\n")
        with self.assertRaisesRegex(ReleaseError, "working tree must be clean"):
            ReleaseWorkflow(self.root, dry_run=True)._preflight_git()

    def test_remote_divergence_is_rejected(self) -> None:
        other = Path(self.temp.name) / "other"
        self._run(
            ["git", "clone", "--branch", "main", self.remote, other],
            cwd=Path(self.temp.name),
        )
        self._run(["git", "config", "user.name", "Other"], cwd=other)
        self._run(["git", "config", "user.email", "other@example.invalid"], cwd=other)
        (other / "remote.txt").write_text("remote\n", encoding="utf-8")
        self._run(["git", "add", "."], cwd=other)
        self._run(["git", "commit", "-m", "remote update"], cwd=other)
        self._run(["git", "push"], cwd=other)

        with self.assertRaisesRegex(ReleaseError, "outdated or diverged"):
            ReleaseWorkflow(self.root, dry_run=True)._preflight_git()

    def test_stale_docs_environment_python_is_rejected(self) -> None:
        python = self.root / ".venv-docs/bin/python"
        python.parent.mkdir(parents=True)
        python.write_text("#!/missing/python\n", encoding="utf-8")
        python.chmod(0o755)

        workflow = ReleaseWorkflow(self.root, dry_run=True)
        self.assertFalse(workflow._docs_python_is_usable(python))

    def test_docs_none_requires_reason(self) -> None:
        manifest = dict(self.manifest)
        manifest.update(
            {"docsImpact": "none", "updatedGuidePaths": [], "noDocsReason": ""}
        )
        self._write("release/manifests/1.0.1.json", json.dumps(manifest))
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "invalid manifest"], cwd=self.root)
        self._run(["git", "push"], cwd=self.root)

        workflow = self._workflow_after_preflight()
        with self.assertRaisesRegex(ReleaseError, "non-empty noDocsReason"):
            workflow._validate_release_metadata()

    def test_unreleased_fragment_is_rejected(self) -> None:
        self._write(".changes/unreleased/pending.json", "{}\n")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "pending fragment"], cwd=self.root)
        self._run(["git", "push"], cwd=self.root)

        workflow = self._workflow_after_preflight()
        workflow._validate_release_metadata()
        with self.assertRaisesRegex(ReleaseError, "Archive all unreleased"):
            workflow._validate_change_fragments()

    def test_changed_docs_manifest_and_fragment_are_valid(self) -> None:
        workflow = self._workflow_after_preflight()
        workflow._validate_release_metadata()
        workflow._validate_change_fragments()

    def test_commit_audit_rejects_code_without_fragment(self) -> None:
        self._run(["git", "tag", "v1.0.0"], cwd=self.root)
        self._write("lib/app.dart", "void main() { print('changed'); }\n")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "code without metadata"], cwd=self.root)
        self._run(["git", "push"], cwd=self.root)

        workflow = self._workflow_after_preflight()
        with self.assertRaisesRegex(ReleaseError, "without a change fragment"):
            workflow._audit_commits_for_fragments("v1.0.0")

    def test_commit_audit_accepts_explicit_no_impact_trailer(self) -> None:
        self._run(["git", "tag", "v1.0.0"], cwd=self.root)
        self._write("lib/app.dart", "void main() { print('internal'); }\n")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(
            [
                "git",
                "commit",
                "-m",
                "internal refactor",
                "-m",
                "Release-Impact: none",
            ],
            cwd=self.root,
        )
        self._run(["git", "push"], cwd=self.root)

        workflow = self._workflow_after_preflight()
        workflow._audit_commits_for_fragments("v1.0.0")

    def test_commit_audit_accepts_exact_release_exception(self) -> None:
        self._run(["git", "tag", "v1.0.0"], cwd=self.root)
        self._write("lib/app.dart", "void main() { print('follow-up'); }\n")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "follow-up fix"], cwd=self.root)
        self._run(["git", "push"], cwd=self.root)
        commit = self._run(["git", "rev-parse", "HEAD"], cwd=self.root).stdout.strip()

        workflow = self._workflow_after_preflight()
        workflow.manifest = dict(self.manifest)
        workflow.manifest["commitAuditExceptions"] = [
            {
                "commit": commit,
                "fragment": "release/fragments/1.0.1/fixture.json",
                "reason": "The fragment was recorded in the originating implementation commit.",
            }
        ]
        workflow._audit_commits_for_fragments("v1.0.0")

    def test_commit_audit_exception_requires_full_immutable_sha(self) -> None:
        self._run(["git", "tag", "v1.0.0"], cwd=self.root)
        self._write("lib/app.dart", "void main() { print('follow-up'); }\n")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "follow-up fix"], cwd=self.root)
        self._run(["git", "push"], cwd=self.root)

        workflow = self._workflow_after_preflight()
        workflow.manifest = dict(self.manifest)
        workflow.manifest["commitAuditExceptions"] = [
            {
                "commit": "deadbee",
                "fragment": "release/fragments/1.0.1/fixture.json",
                "reason": "Too broad to be safe.",
            }
        ]
        with self.assertRaisesRegex(ReleaseError, "full lowercase immutable SHAs"):
            workflow._audit_commits_for_fragments("v1.0.0")


if __name__ == "__main__":
    unittest.main()
