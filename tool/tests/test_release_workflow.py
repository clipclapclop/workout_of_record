from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
import urllib.parse
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
                    "forgejoBaseUrl": "https://forgejo.example",
                    "forgejoRepository": "example/fixture",
                    "githubMirrorEnabled": True,
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

    def _commit_fragment_follow_up(self) -> tuple[str, str]:
        archived = self.root / "release/fragments/1.0.1/fixture.json"
        self._write(".changes/unreleased/fixture.json", archived.read_text(encoding="utf-8"))
        self._write("lib/app.dart", "void main() { print('origin'); }\n")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "originating change"], cwd=self.root)
        originating = self._run(
            ["git", "rev-parse", "HEAD"], cwd=self.root
        ).stdout.strip()

        self._write("lib/app.dart", "void main() { print('follow-up'); }\n")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "follow-up fix"], cwd=self.root)
        self._run(["git", "push"], cwd=self.root)
        follow_up = self._run(
            ["git", "rev-parse", "HEAD"], cwd=self.root
        ).stdout.strip()
        return originating, follow_up

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

    def test_github_remote_is_optional_when_mirror_is_disabled(self) -> None:
        config_path = self.root / "tool/release-config.json"
        config = json.loads(config_path.read_text(encoding="utf-8"))
        config["githubMirrorEnabled"] = False
        config.pop("githubRepository")
        config.pop("githubRemote")
        config_path.write_text(json.dumps(config), encoding="utf-8")
        self._run(["git", "remote", "remove", "github"], cwd=self.root)
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "disable GitHub mirror"], cwd=self.root)
        self._run(["git", "push"], cwd=self.root)

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

    def test_forgejo_backfill_accepts_annotated_ancestor_tag(self) -> None:
        self._run(
            ["git", "tag", "-a", "v1.0.1", "-m", "Fixture 1.0.1"],
            cwd=self.root,
        )
        self._run(["git", "push", "origin", "v1.0.1"], cwd=self.root)
        self._write("tool/backfill.txt", "backfill support\n")
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "add backfill support"], cwd=self.root)
        self._run(["git", "push"], cwd=self.root)

        workflow = ReleaseWorkflow(
            self.root,
            dry_run=False,
            backfill_forgejo="v1.0.1",
        )
        workflow._forgejo_token = lambda: "token"  # type: ignore[method-assign]

        workflow._preflight_forgejo_backfill()

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
        originating, commit = self._commit_fragment_follow_up()

        workflow = self._workflow_after_preflight()
        workflow.manifest = dict(self.manifest)
        workflow.manifest["commitAuditExceptions"] = [
            {
                "commit": commit,
                "originatingCommit": originating,
                "fragment": "release/fragments/1.0.1/fixture.json",
                "reason": "The fragment was recorded in the originating implementation commit.",
            }
        ]
        workflow._audit_commits_for_fragments("v1.0.0")

    def test_commit_audit_exception_requires_full_immutable_sha(self) -> None:
        self._run(["git", "tag", "v1.0.0"], cwd=self.root)
        originating, _ = self._commit_fragment_follow_up()

        workflow = self._workflow_after_preflight()
        workflow.manifest = dict(self.manifest)
        workflow.manifest["commitAuditExceptions"] = [
            {
                "commit": "deadbee",
                "originatingCommit": originating,
                "fragment": "release/fragments/1.0.1/fixture.json",
                "reason": "Too broad to be safe.",
            }
        ]
        with self.assertRaisesRegex(ReleaseError, "full lowercase immutable SHAs"):
            workflow._audit_commits_for_fragments("v1.0.0")

    def test_commit_audit_exception_rejects_unrelated_fragment(self) -> None:
        other_fragment = {
            "id": "other",
            "summary": "Other change.",
            "audience": "internal",
            "releaseNote": "Other release note.",
            "docs": {
                "impact": "updated",
                "paths": ["docs/guide.md"],
                "reason": "",
            },
            "screenshots": [],
        }
        self._write(
            "release/fragments/1.0.1/other.json", json.dumps(other_fragment)
        )
        self._run(["git", "add", "."], cwd=self.root)
        self._run(["git", "commit", "-m", "other release metadata"], cwd=self.root)
        self._run(["git", "tag", "v1.0.0"], cwd=self.root)
        originating, commit = self._commit_fragment_follow_up()

        workflow = self._workflow_after_preflight()
        workflow.manifest = dict(self.manifest)
        workflow.manifest["changeFragments"] = [
            *self.manifest["changeFragments"],
            "release/fragments/1.0.1/other.json",
        ]
        workflow.manifest["commitAuditExceptions"] = [
            {
                "commit": commit,
                "originatingCommit": originating,
                "fragment": "release/fragments/1.0.1/other.json",
                "reason": "This fragment belongs to a different implementation.",
            }
        ]
        with self.assertRaisesRegex(ReleaseError, "did not record the linked fragment"):
            workflow._audit_commits_for_fragments("v1.0.0")

    def test_forgejo_draft_is_verified_before_publication(self) -> None:
        workflow = ReleaseWorkflow(self.root, dry_run=False)
        workflow.manifest = dict(self.manifest)
        apk = self.root / "fixture-arm64.apk"
        checksum = self.root / "fixture-arm64.apk.sha256"
        apk.write_bytes(b"verified apk")
        checksum.write_bytes(b"verified checksum")
        notes = (self.root / "docs/releases/1.0.1.md").read_text(encoding="utf-8")
        release = {
            "id": 7,
            "tag_name": "v1.0.1",
            "name": "Fixture 1.0.1",
            "body": notes,
            "draft": True,
            "prerelease": False,
            "assets": [],
        }
        created = False
        calls: list[tuple[str, str]] = []
        uploaded: dict[str, bytes] = {}
        downloaded: list[str] = []

        def fake_state() -> dict[str, object] | None:
            return dict(release) if created else None

        def fake_api(method: str, path: str, **kwargs: object) -> dict[str, object]:
            nonlocal created
            calls.append((method, path))
            if method == "POST" and path.endswith("/releases"):
                created = True
                return dict(release)
            if method == "POST" and "/assets?" in path:
                name = urllib.parse.parse_qs(urllib.parse.urlparse(path).query)["name"][0]
                uploaded[name] = kwargs["data"]  # type: ignore[assignment]
                release["assets"].append(  # type: ignore[union-attr]
                    {"name": name, "browser_download_url": f"https://forgejo/{name}"}
                )
                return {"name": name}
            if method == "PATCH":
                release["draft"] = False
                return dict(release)
            self.fail(f"Unexpected Forgejo API call: {method} {path}")

        def fake_download(asset: dict[str, object], destination: Path) -> None:
            name = str(asset["name"])
            downloaded.append(name)
            destination.write_bytes(uploaded[name])

        workflow._forgejo_release_state = fake_state  # type: ignore[method-assign]
        workflow._forgejo_api = fake_api  # type: ignore[method-assign]
        workflow._download_forgejo_asset = fake_download  # type: ignore[method-assign]
        workflow._git_output = lambda *args: "a" * 40  # type: ignore[method-assign]

        workflow._publish_forgejo_release(apk, checksum)

        self.assertFalse(release["draft"])
        self.assertEqual(
            [method for method, _ in calls],
            ["POST", "POST", "POST", "PATCH"],
        )
        self.assertEqual(uploaded[apk.name], apk.read_bytes())
        self.assertEqual(uploaded[checksum.name], checksum.read_bytes())
        self.assertEqual(downloaded, [apk.name, checksum.name])

    def test_forgejo_matching_asset_is_reused(self) -> None:
        workflow = ReleaseWorkflow(self.root, dry_run=False)
        local = self.root / "fixture-arm64.apk"
        local.write_bytes(b"same")
        release = {
            "assets": [
                {"name": local.name, "browser_download_url": "https://forgejo/asset"}
            ]
        }
        workflow._download_forgejo_asset = (  # type: ignore[method-assign]
            lambda asset, destination: destination.write_bytes(b"same")
        )

        uploaded = workflow._ensure_forgejo_release_asset(
            local, release, allow_upload=False
        )

        self.assertFalse(uploaded)

    def test_forgejo_conflicting_asset_is_rejected(self) -> None:
        workflow = ReleaseWorkflow(self.root, dry_run=False)
        local = self.root / "fixture-arm64.apk"
        local.write_bytes(b"expected")
        release = {
            "assets": [
                {"name": local.name, "browser_download_url": "https://forgejo/asset"}
            ]
        }
        workflow._download_forgejo_asset = (  # type: ignore[method-assign]
            lambda asset, destination: destination.write_bytes(b"different")
        )

        with self.assertRaisesRegex(ReleaseError, "different asset"):
            workflow._ensure_forgejo_release_asset(
                local, release, allow_upload=False
            )

    def test_published_forgejo_release_cannot_be_repaired_with_missing_asset(self) -> None:
        workflow = ReleaseWorkflow(self.root, dry_run=False)
        local = self.root / "fixture-arm64.apk"
        local.write_bytes(b"expected")

        with self.assertRaisesRegex(ReleaseError, "missing required asset"):
            workflow._ensure_forgejo_release_asset(
                local, {"id": 7, "assets": []}, allow_upload=False
            )

    def test_canonical_release_precedes_github_mirror(self) -> None:
        workflow = ReleaseWorkflow(self.root, dry_run=False)
        workflow.manifest = dict(self.manifest)
        apk = self.root / "fixture-arm64.apk"
        checksum = self.root / "fixture-arm64.apk.sha256"
        apk.write_bytes(b"apk")
        checksum.write_bytes(b"checksum")
        events: list[str] = []

        class RecordingRunner:
            def run(self, args: object, **kwargs: object) -> subprocess.CompletedProcess[str]:
                command = [str(value) for value in args]  # type: ignore[union-attr]
                events.append("command:" + " ".join(command))
                return subprocess.CompletedProcess(command, 0, "", "")

        workflow.runner = RecordingRunner()  # type: ignore[assignment]
        workflow._forgejo_token = lambda: "token"  # type: ignore[method-assign]
        workflow._ensure_release_tag = lambda: events.append("tag")  # type: ignore[method-assign]
        workflow._publish_forgejo_release = (  # type: ignore[method-assign]
            lambda apk, checksum: events.append("forgejo")
        )
        workflow._publish_github_mirror = (  # type: ignore[method-assign]
            lambda apk, checksum: events.append("github")
        )

        workflow._publish(apk, checksum)

        self.assertLess(events.index("forgejo"), events.index("github"))
        self.assertLess(
            events.index("command:git push origin v1.0.1"),
            events.index("forgejo"),
        )

    def test_disabled_github_mirror_is_not_published(self) -> None:
        workflow = ReleaseWorkflow(self.root, dry_run=False)
        workflow.config["githubMirrorEnabled"] = False
        workflow.manifest = dict(self.manifest)
        apk = self.root / "fixture-arm64.apk"
        checksum = self.root / "fixture-arm64.apk.sha256"
        apk.write_bytes(b"apk")
        checksum.write_bytes(b"checksum")
        events: list[str] = []

        class RecordingRunner:
            def run(self, args: object, **kwargs: object) -> subprocess.CompletedProcess[str]:
                command = [str(value) for value in args]  # type: ignore[union-attr]
                return subprocess.CompletedProcess(command, 0, "", "")

        workflow.runner = RecordingRunner()  # type: ignore[assignment]
        workflow._forgejo_token = lambda: "token"  # type: ignore[method-assign]
        workflow._ensure_release_tag = lambda: None  # type: ignore[method-assign]
        workflow._publish_forgejo_release = (  # type: ignore[method-assign]
            lambda apk, checksum: events.append("forgejo")
        )
        workflow._publish_github_mirror = (  # type: ignore[method-assign]
            lambda apk, checksum: events.append("github")
        )

        workflow._publish(apk, checksum)

        self.assertEqual(events, ["forgejo"])


if __name__ == "__main__":
    unittest.main()
