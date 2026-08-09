#!/usr/bin/env python3
"""Host-installed Repflow adapter for the existing deterministic release tool."""

from __future__ import annotations

import fcntl
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
from pathlib import Path
from typing import Any


EXPECTED_REPOSITORY = "chad/workout_of_record"
EXPECTED_CANONICAL_REMOTE = "ssh://git@git.oorangy.com:2222/chad/workout_of_record.git"
EXPECTED_GITHUB_REMOTE = "git@github.com:clipclapclop/workout_of_record.git"
CONFIG_PATH = Path.home() / ".config/workout-of-record/repflow-release-adapter.json"


class AdapterError(RuntimeError):
    """A safe adapter precondition was not satisfied."""


def _secure_file(path: Path, *, executable: bool = False) -> None:
    try:
        metadata = path.lstat()
    except OSError as error:
        raise AdapterError(f"Required host file is unavailable: {path}") from error
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISREG(metadata.st_mode):
        raise AdapterError(f"Host file must be a regular non-symlink: {path}")
    if metadata.st_uid != os.getuid() or metadata.st_mode & 0o022:
        raise AdapterError(f"Host file has unsafe ownership or permissions: {path}")
    if executable and not metadata.st_mode & stat.S_IXUSR:
        raise AdapterError(f"Host executable is not owner-executable: {path}")


def _load_config() -> dict[str, str]:
    _secure_file(CONFIG_PATH)
    if CONFIG_PATH.stat().st_mode & 0o077:
        raise AdapterError("Adapter configuration must have mode 0600.")
    try:
        value = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise AdapterError("Adapter configuration is invalid.") from error
    required = ("canonicalRepository", "githubRepository", "keyProperties")
    if not isinstance(value, dict) or value.get("schema") != 1:
        raise AdapterError("Adapter configuration must use schema 1.")
    for key in required:
        if not isinstance(value.get(key), str) or not value[key].strip():
            raise AdapterError(f"Adapter configuration field {key} is required.")
    if value["canonicalRepository"] != EXPECTED_CANONICAL_REMOTE:
        raise AdapterError("Canonical repository does not match this installed adapter.")
    if value["githubRepository"] != EXPECTED_GITHUB_REMOTE:
        raise AdapterError("GitHub repository does not match this installed adapter.")
    key_properties = Path(value["keyProperties"])
    if not key_properties.is_absolute():
        raise AdapterError("keyProperties must be an absolute host path.")
    _secure_file(key_properties)
    if key_properties.stat().st_mode & 0o077:
        raise AdapterError("Android key properties must have mode 0600.")
    return {key: value[key] for key in required}


def _environment(action: str) -> dict[str, str]:
    values = {
        name: os.environ.get(name, "")
        for name in (
            "REPFLOW_STAGE",
            "REPFLOW_PHASE",
            "REPFLOW_REVISION",
            "REPFLOW_OPERATION_ID",
            "REPFLOW_PULL_REQUEST",
            "REPFLOW_REPOSITORY",
        )
    }
    expected_phase = "verify" if action == "verify" else "execute"
    if values["REPFLOW_STAGE"] != "release" or values["REPFLOW_PHASE"] != expected_phase:
        raise AdapterError("Repflow stage or phase does not match the adapter action.")
    if values["REPFLOW_REPOSITORY"] != EXPECTED_REPOSITORY:
        raise AdapterError("Repflow repository identity does not match this adapter.")
    if not re.fullmatch(r"[0-9a-f]{40}", values["REPFLOW_REVISION"]):
        raise AdapterError("Repflow revision must be a full lowercase SHA-1.")
    if not values["REPFLOW_OPERATION_ID"] or len(values["REPFLOW_OPERATION_ID"]) > 512:
        raise AdapterError("Repflow operation identity is missing or too long.")
    if not re.fullmatch(r"[1-9][0-9]*", values["REPFLOW_PULL_REQUEST"]):
        raise AdapterError("Repflow pull-request identity is invalid.")
    return values


def _run(command: list[str], *, cwd: Path, log: Path) -> subprocess.CompletedProcess[bytes]:
    log.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    with log.open("ab") as output:
        os.chmod(log, 0o600)
        output.write(("\n+ " + " ".join(command) + "\n").encode())
        output.flush()
        try:
            return subprocess.run(
                command,
                cwd=cwd,
                check=False,
                stdout=output,
                stderr=subprocess.STDOUT,
            )
        except OSError as error:
            raise AdapterError(f"Required command could not start: {command[0]}") from error


def _checked(command: list[str], *, cwd: Path, log: Path) -> None:
    if _run(command, cwd=cwd, log=log).returncode != 0:
        raise AdapterError(f"Host checkout command failed: {command[0]}")


def _succeeds(command: list[str], *, cwd: Path) -> bool:
    try:
        return subprocess.run(
            command,
            cwd=cwd,
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode == 0
    except OSError:
        return False


def _output(command: list[str], *, cwd: Path) -> str:
    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except OSError as error:
        raise AdapterError(f"Required command could not start: {command[0]}") from error
    if result.returncode != 0:
        raise AdapterError(f"Host checkout query failed: {command[0]}")
    return result.stdout.strip()


def _write_metadata(path: Path, values: dict[str, str]) -> None:
    expected = {
        "operationId": values["REPFLOW_OPERATION_ID"],
        "revision": values["REPFLOW_REVISION"],
        "pullRequest": values["REPFLOW_PULL_REQUEST"],
        "repository": values["REPFLOW_REPOSITORY"],
    }
    if path.exists():
        try:
            existing = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise AdapterError("Existing operation metadata is invalid.") from error
        if existing != expected:
            raise AdapterError("Existing operation metadata conflicts with this invocation.")
        return
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(expected, sort_keys=True) + "\n", encoding="utf-8")
    os.chmod(temporary, 0o600)
    temporary.replace(path)


def _checkout(
    state_root: Path,
    values: dict[str, str],
    config: dict[str, str],
    log: Path,
) -> Path:
    operation_key = hashlib.sha256(values["REPFLOW_OPERATION_ID"].encode()).hexdigest()
    operation = state_root / "operations" / operation_key
    operation.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(operation, 0o700)
    _write_metadata(operation / "operation.json", values)
    checkout = operation / "checkout"
    if checkout.exists() and (checkout.is_symlink() or not checkout.is_dir()):
        raise AdapterError("Existing operation checkout is not a regular directory.")
    if checkout.exists() and not _succeeds(
        ["git", "rev-parse", "--git-dir"], cwd=checkout
    ):
        shutil.rmtree(checkout)
    if not checkout.exists():
        _checked(
            ["git", "clone", "--no-checkout", config["canonicalRepository"], str(checkout)],
            cwd=operation,
            log=log,
        )
    remotes = set(_output(["git", "remote"], cwd=checkout).splitlines())
    if "origin" not in remotes:
        shutil.rmtree(checkout)
        _checked(
            ["git", "clone", "--no-checkout", config["canonicalRepository"], str(checkout)],
            cwd=operation,
            log=log,
        )
        remotes = set(_output(["git", "remote"], cwd=checkout).splitlines())
    if "github" not in remotes:
        _checked(
            ["git", "remote", "add", "github", config["githubRepository"]],
            cwd=checkout,
            log=log,
        )
    if _output(["git", "remote", "get-url", "origin"], cwd=checkout) != config[
        "canonicalRepository"
    ]:
        raise AdapterError("Canonical checkout remote differs from host configuration.")
    if _output(["git", "remote", "get-url", "github"], cwd=checkout) != config[
        "githubRepository"
    ]:
        raise AdapterError("GitHub checkout remote differs from host configuration.")

    _checked(
        [
            "git", "fetch", "--force", "--prune", "--tags", "origin",
            "refs/heads/main:refs/remotes/origin/main",
        ],
        cwd=checkout,
        log=log,
    )
    revision = values["REPFLOW_REVISION"]
    _checked(["git", "cat-file", "-e", f"{revision}^{{commit}}"], cwd=checkout, log=log)
    _checked(
        ["git", "merge-base", "--is-ancestor", revision, "origin/main"],
        cwd=checkout,
        log=log,
    )
    _checked(["git", "checkout", "-B", "main", revision], cwd=checkout, log=log)
    _checked(["git", "reset", "--hard", revision], cwd=checkout, log=log)
    _checked(["git", "clean", "-ffd"], cwd=checkout, log=log)

    if _output(["git", "rev-parse", "HEAD"], cwd=checkout) != revision:
        raise AdapterError("Prepared checkout is not at the exact Repflow revision.")
    if _output(["git", "status", "--porcelain", "--untracked-files=all"], cwd=checkout):
        raise AdapterError("Prepared exact-revision checkout is not clean.")
    return checkout


def _tag(checkout: Path) -> str:
    pubspec = (checkout / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([^+\s]+)\+\d+\s*$", pubspec, re.MULTILINE)
    if not match or not re.fullmatch(r"\d+\.\d+\.\d+", match.group(1)):
        raise AdapterError("Exact revision does not contain a releasable application version.")
    return "v" + match.group(1)


def _result(status: str, summary: str, tag: str | None = None) -> None:
    value: dict[str, Any] = {"status": status, "summary": summary}
    if tag is not None:
        value["externalId"] = tag
    sys.stdout.write(json.dumps(value, separators=(",", ":")) + "\n")


def run(action: str) -> int:
    values = _environment(action)
    config = _load_config()
    state_root = Path.cwd().resolve()
    state_root.mkdir(mode=0o700, parents=True, exist_ok=True)
    lock_path = state_root / ".adapter.lock"
    with lock_path.open("a+b") as lock:
        os.chmod(lock_path, 0o600)
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        operation_key = hashlib.sha256(values["REPFLOW_OPERATION_ID"].encode()).hexdigest()
        log = state_root / "operations" / operation_key / f"{action}.log"
        log.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        checkout = _checkout(state_root, values, config, log)
        tag = _tag(checkout)
        release = checkout / "tool/release"
        _secure_file(release, executable=True)
        command = [str(release)]
        if action == "prepare":
            command.append("--dry-run")
        elif action == "verify":
            command.append("--verify-published")
        environment = dict(os.environ)
        environment["WORKOUT_OF_RECORD_RELEASE_REVISION"] = values["REPFLOW_REVISION"]
        environment["WORKOUT_OF_RECORD_KEY_PROPERTIES"] = config["keyProperties"]
        effect_marker = log.parent / "publication-possible"
        publication_was_possible = effect_marker.exists()
        if action == "execute":
            effect_marker.write_text("publication may have started\n", encoding="utf-8")
            os.chmod(effect_marker, 0o600)
        with log.open("ab") as output:
            os.chmod(log, 0o600)
            output.write(("\n+ tool/release " + " ".join(command[1:]) + "\n").encode())
            output.flush()
            try:
                completed = subprocess.run(
                    command,
                    cwd=checkout,
                    check=False,
                    env=environment,
                    stdout=output,
                    stderr=subprocess.STDOUT,
                )
            except OSError as error:
                raise AdapterError("The exact-revision release publisher could not start.") from error

        short_revision = values["REPFLOW_REVISION"][:12]
        if completed.returncode == 0:
            verb = (
                "Prepared"
                if action == "prepare"
                else "Verified"
                if action == "verify"
                else "Published"
            )
            status = "passed" if action == "verify" else "succeeded"
            _result(status, f"{verb} {tag} at exact revision {short_revision}.", tag)
            return 0
        if action == "verify":
            _result("failed", f"Published {tag} did not pass exact-revision verification.", tag)
            return 0
        if action == "prepare":
            _result("failed", f"{tag} failed before any publication effect.", tag)
            return 0
        if completed.returncode == 2:
            if publication_was_possible:
                print(
                    "A prior publication attempt remains uncertain; repair the preflight "
                    "failure and retry the same Repflow operation.",
                    file=sys.stderr,
                )
                return 1
            effect_marker.unlink(missing_ok=True)
            _result("failed", f"{tag} failed before any publication effect.", tag)
            return 0
        print(
            "Release publication may have started but did not return reconcilable evidence; "
            "retry the same Repflow operation.",
            file=sys.stderr,
        )
        return 1


def main(argv: list[str] | None = None) -> None:
    arguments = sys.argv[1:] if argv is None else argv
    if len(arguments) != 1 or arguments[0] not in {"execute", "verify", "prepare"}:
        print("usage: workout-of-record-release-adapter execute|verify|prepare", file=sys.stderr)
        raise SystemExit(64)
    action = arguments[0]
    try:
        raise SystemExit(run(action))
    except AdapterError as error:
        operation_id = os.environ.get("REPFLOW_OPERATION_ID", "")
        operation_key = hashlib.sha256(operation_id.encode()).hexdigest()
        effect_marker = Path.cwd().resolve() / "operations" / operation_key / "publication-possible"
        if action == "execute" and effect_marker.is_file():
            print(
                "Release publication may already have started; repair the host precondition "
                "and retry the same Repflow operation.",
                file=sys.stderr,
            )
            raise SystemExit(1) from error
        phase = "verification" if action == "verify" else "preparation"
        _result("failed", f"Release {phase} stopped at a safe host precondition.")
        print(f"release adapter: {error}", file=sys.stderr)
        # A valid structured `failed` result is terminal evidence. Nonzero exit is
        # reserved for uncertain effects so Repflow retains recovery state and its lock.
        raise SystemExit(0) from error


if __name__ == "__main__":
    main()
