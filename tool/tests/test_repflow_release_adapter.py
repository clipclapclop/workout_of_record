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

    def test_verification_failure_is_bounded_structured_evidence(self) -> None:
        result, stdout, _, command, _ = self._run("verify", returncode=2)

        self.assertEqual(result, 0)
        self.assertEqual(command[-1], "--verify-published")
        self.assertEqual(json.loads(stdout)["status"], "failed")
        self.assertNotIn(str(self.root), stdout)

    def test_operation_metadata_cannot_be_reused_for_another_revision(self) -> None:
        path = self.root / "operation.json"
        adapter._write_metadata(path, ENVIRONMENT)
        changed = dict(ENVIRONMENT)
        changed["REPFLOW_REVISION"] = "b" * 40

        with self.assertRaisesRegex(adapter.AdapterError, "conflicts"):
            adapter._write_metadata(path, changed)

    def test_environment_rejects_another_repository(self) -> None:
        values = dict(ENVIRONMENT)
        values["REPFLOW_REPOSITORY"] = "someone/else"
        with patch.dict(os.environ, values, clear=True):
            with self.assertRaisesRegex(adapter.AdapterError, "repository identity"):
                adapter._environment("execute")


if __name__ == "__main__":
    unittest.main()
