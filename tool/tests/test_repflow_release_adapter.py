from __future__ import annotations

import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest.mock import patch


TOOL_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_DIR))

import repflow_release_adapter as adapter  # noqa: E402


REVISION = "a" * 40
ENVIRONMENT = {
    "REPFLOW_STAGE": "release",
    "REPFLOW_PHASE": "execute",
    "REPFLOW_REVISION": REVISION,
    "REPFLOW_OPERATION_ID": "release:https:git.oorangy.com:pr-7:" + REVISION,
    "REPFLOW_PULL_REQUEST": "7",
    "REPFLOW_REPOSITORY": "chad/workout_of_record",
}


class RepflowReleaseAdapterTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="release-adapter-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.checkout = self.root / "checkout"
        (self.checkout / "tool").mkdir(parents=True)
        (self.checkout / "tool/release").write_text("#!/bin/sh\n", encoding="utf-8")
        (self.checkout / "tool/release").chmod(0o755)
        (self.checkout / "pubspec.yaml").write_text(
            "name: fixture\nversion: 1.2.3+4\n", encoding="utf-8"
        )

    def _run(
        self, action: str, returncode: int = 0
    ) -> tuple[int, str, str, list[str], dict[str, str]]:
        command: list[str] = []
        environment: dict[str, str] = {}

        def fake_run(args: list[str], **kwargs: object) -> subprocess.CompletedProcess[bytes]:
            command.extend(args)
            environment.update(kwargs["env"])  # type: ignore[arg-type]
            return subprocess.CompletedProcess(args, returncode)

        values = dict(ENVIRONMENT)
        values["REPFLOW_PHASE"] = "verify" if action == "verify" else "execute"
        stdout = io.StringIO()
        stderr = io.StringIO()
        with (
            patch.object(adapter, "_environment", return_value=values),
            patch.object(
                adapter,
                "_load_config",
                return_value={"keyProperties": "/host/android-key.properties"},
            ),
            patch.object(adapter, "_checkout", return_value=self.checkout),
            patch.object(adapter, "_secure_file"),
            patch.object(adapter.Path, "cwd", return_value=self.root),
            patch.object(adapter, "EXPECTED_STATE_ROOT", self.root),
            patch.object(adapter.subprocess, "run", side_effect=fake_run),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            result = adapter.run(action)
        return result, stdout.getvalue(), stderr.getvalue(), command, environment

    def test_execute_passes_only_the_exact_revision_to_existing_publisher(self) -> None:
        result, stdout, _, command, environment = self._run("execute")

        self.assertEqual(result, 0)
        self.assertEqual(command, [str(self.checkout / "tool/release")])
        self.assertEqual(environment["WORKOUT_OF_RECORD_RELEASE_REVISION"], REVISION)
        self.assertEqual(
            environment["WORKOUT_OF_RECORD_KEY_PROPERTIES"],
            "/host/android-key.properties",
        )
        self.assertEqual(json.loads(stdout)["status"], "succeeded")
        self.assertEqual(json.loads(stdout)["externalId"], "v1.2.3")
        operation_key = adapter.hashlib.sha256(
            ENVIRONMENT["REPFLOW_OPERATION_ID"].encode()
        ).hexdigest()
        operation = self.root / "operations" / operation_key
        self.assertFalse((operation / "publication-possible").exists())
        self.assertTrue((operation / "publication-succeeded").is_file())

    def test_prepare_is_non_publishing(self) -> None:
        result, stdout, _, command, _ = self._run("prepare")

        self.assertEqual(result, 0)
        self.assertEqual(command[-1], "--dry-run")
        self.assertEqual(json.loads(stdout)["status"], "succeeded")

    def test_post_effect_execution_error_stays_uncertain_for_retry(self) -> None:
        result, stdout, stderr, _, _ = self._run("execute", returncode=3)
        operation_key = adapter.hashlib.sha256(
            ENVIRONMENT["REPFLOW_OPERATION_ID"].encode()
        ).hexdigest()

        self.assertEqual(result, 1)
        self.assertEqual(stdout, "")
        self.assertIn("retry the same Repflow operation", stderr)
        self.assertTrue(
            (self.root / "operations" / operation_key / "publication-possible").is_file()
        )

    def test_safe_pre_effect_failure_removes_uncertainty_marker(self) -> None:
        result, stdout, _, _, _ = self._run("execute", returncode=2)
        operation_key = adapter.hashlib.sha256(
            ENVIRONMENT["REPFLOW_OPERATION_ID"].encode()
        ).hexdigest()

        self.assertEqual(result, 0)
        self.assertEqual(json.loads(stdout)["status"], "failed")
        self.assertFalse(
            (self.root / "operations" / operation_key / "publication-possible").exists()
        )

    def test_retry_preflight_failure_preserves_prior_uncertainty(self) -> None:
        operation_key = adapter.hashlib.sha256(
            ENVIRONMENT["REPFLOW_OPERATION_ID"].encode()
        ).hexdigest()
        marker = self.root / "operations" / operation_key / "publication-possible"
        marker.parent.mkdir(parents=True)
        marker.write_text("prior uncertain publication\n", encoding="utf-8")

        result, stdout, stderr, _, _ = self._run("execute", returncode=2)

        self.assertEqual(result, 1)
        self.assertEqual(stdout, "")
        self.assertIn("prior publication attempt remains uncertain", stderr)
        self.assertTrue(marker.is_file())

    def test_verification_failure_is_bounded_structured_evidence(self) -> None:
        result, stdout, _, command, _ = self._run("verify", returncode=2)

        self.assertEqual(result, 0)
        self.assertEqual(command[-1], "--verify-published")
        self.assertEqual(json.loads(stdout)["status"], "failed")
        self.assertNotIn(str(self.root), stdout)

    def test_safe_precondition_is_terminal_structured_failure(self) -> None:
        stdout = io.StringIO()
        stderr = io.StringIO()
        with (
            patch.object(adapter, "run", side_effect=adapter.AdapterError("safe failure")),
            patch.object(adapter.Path, "cwd", return_value=self.root),
            patch.dict(os.environ, ENVIRONMENT, clear=True),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            with self.assertRaises(SystemExit) as exit_status:
                adapter.main(["execute"])

        self.assertEqual(exit_status.exception.code, 0)
        self.assertEqual(json.loads(stdout.getvalue())["status"], "failed")
        self.assertIn("safe failure", stderr.getvalue())

    def test_interrupted_checkout_without_github_remote_is_reconciled(self) -> None:
        source = self.root / "source"
        canonical = self.root / "canonical.git"
        github = self.root / "github.git"
        operation_id = ENVIRONMENT["REPFLOW_OPERATION_ID"]
        operation_key = adapter.hashlib.sha256(operation_id.encode()).hexdigest()
        checkout = self.root / "operations" / operation_key / "checkout"
        source.mkdir()
        subprocess.run(["git", "init", "--initial-branch=main"], cwd=source, check=True, capture_output=True)
        subprocess.run(["git", "config", "user.name", "Adapter Test"], cwd=source, check=True)
        subprocess.run(["git", "config", "user.email", "adapter@example.invalid"], cwd=source, check=True)
        (source / "pubspec.yaml").write_text("name: fixture\nversion: 1.2.3+4\n", encoding="utf-8")
        subprocess.run(["git", "add", "."], cwd=source, check=True)
        subprocess.run(["git", "commit", "-m", "fixture"], cwd=source, check=True, capture_output=True)
        revision = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=source, check=True, text=True, capture_output=True
        ).stdout.strip()
        subprocess.run(["git", "clone", "--bare", str(source), str(canonical)], check=True, capture_output=True)
        subprocess.run(["git", "init", "--bare", str(github)], check=True, capture_output=True)
        checkout.parent.mkdir(parents=True)
        subprocess.run(
            ["git", "clone", "--no-checkout", str(canonical), str(checkout)],
            check=True,
            capture_output=True,
        )
        values = dict(ENVIRONMENT)
        values["REPFLOW_REVISION"] = revision
        config = {
            "canonicalRepository": str(canonical),
            "githubRepository": str(github),
        }

        result = adapter._checkout(
            self.root, values, config, self.root / "checkout-recovery.log"
        )

        self.assertEqual(result, checkout)
        self.assertEqual(
            subprocess.run(
                ["git", "remote", "get-url", "github"],
                cwd=checkout,
                check=True,
                text=True,
                capture_output=True,
            ).stdout.strip(),
            str(github),
        )

    def test_operation_metadata_cannot_be_reused_for_another_revision(self) -> None:
        path = self.root / "operation.json"
        adapter._write_metadata(path, ENVIRONMENT)
        changed = dict(ENVIRONMENT)
        changed["REPFLOW_REVISION"] = "b" * 40

        with self.assertRaisesRegex(adapter.AdapterError, "conflicts"):
            adapter._write_metadata(path, changed)

    def test_production_phase_rejects_wrong_state_directory(self) -> None:
        with (
            patch.object(adapter, "_environment", return_value=dict(ENVIRONMENT)),
            patch.object(adapter, "_load_config", return_value={}),
            patch.object(adapter.Path, "cwd", return_value=self.root),
            patch.object(adapter, "EXPECTED_STATE_ROOT", self.root / "expected"),
        ):
            with self.assertRaisesRegex(adapter.AdapterError, "configured state directory"):
                adapter.run("execute")

    def test_environment_rejects_another_repository(self) -> None:
        values = dict(ENVIRONMENT)
        values["REPFLOW_REPOSITORY"] = "someone/else"
        with patch.dict(os.environ, values, clear=True):
            with self.assertRaisesRegex(adapter.AdapterError, "repository identity"):
                adapter._environment("execute")


if __name__ == "__main__":
    unittest.main()
