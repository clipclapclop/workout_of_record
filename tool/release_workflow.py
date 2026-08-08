#!/usr/bin/env python3
"""Build, verify, document, and publish a Workout of Record Android release."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


class ReleaseError(RuntimeError):
    """A release invariant was not satisfied."""


class CommandRunner:
    def run(
        self,
        args: Iterable[str | Path],
        *,
        cwd: Path,
        check: bool = True,
        capture: bool = False,
        input_text: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        command = [str(arg) for arg in args]
        print(f"+ {' '.join(command)}", flush=True)
        result = subprocess.run(
            command,
            cwd=cwd,
            check=False,
            text=True,
            input=input_text,
            stdout=subprocess.PIPE if capture else None,
            stderr=subprocess.PIPE if capture else None,
        )
        if check and result.returncode != 0:
            detail = "\n".join(
                part.strip() for part in (result.stdout, result.stderr) if part and part.strip()
            )
            suffix = f"\n{detail}" if detail else ""
            raise ReleaseError(f"Command failed ({result.returncode}): {' '.join(command)}{suffix}")
        return result


@dataclass(frozen=True)
class AppVersion:
    name: str
    code: int

    @property
    def tag(self) -> str:
        return f"v{self.name}"

    @property
    def semver(self) -> tuple[int, int, int]:
        match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", self.name)
        if not match:
            raise ReleaseError(
                f"Version name {self.name!r} must use MAJOR.MINOR.PATCH for releases."
            )
        return tuple(int(value) for value in match.groups())  # type: ignore[return-value]


class ReleaseWorkflow:
    def __init__(
        self,
        root: Path,
        *,
        dry_run: bool,
        backfill_forgejo: str | None = None,
        runner: CommandRunner | None = None,
    ) -> None:
        self.root = root.resolve()
        self.dry_run = dry_run
        self.backfill_forgejo = backfill_forgejo
        self.runner = runner or CommandRunner()
        self.config = self._load_json(self.root / "tool/release-config.json")
        self._validate_config()
        self.version = (
            self._read_backfill_version(backfill_forgejo)
            if backfill_forgejo
            else self._read_version()
        )
        self.manifest_path = (
            self.root / "release/manifests" / f"{self.version.name}.json"
        )
        self.manifest: dict[str, Any] = {}
        self.latest_tag: str | None = None
        self.changed_paths: set[str] = set()

    def execute(self) -> None:
        if self.backfill_forgejo:
            self._backfill_forgejo_release()
            return

        print(
            f"Preparing {self.version.tag} ({self.version.code})"
            + (" [dry run]" if self.dry_run else ""),
            flush=True,
        )
        self._preflight_git()
        self._validate_release_metadata()
        self._validate_change_fragments()
        self._validate_no_tracked_secrets()
        self._run_validations()
        apk, checksum_file = self._stage_and_verify_apk()

        if self.dry_run:
            print(f"Dry run complete: {apk}")
            print("No branch, tag, release, asset, or documentation site was published.")
            return

        self._publish(apk, checksum_file)
        print(f"Published {self.version.tag} successfully.")

    def _load_json(self, path: Path) -> dict[str, Any]:
        if not path.is_file():
            raise ReleaseError(f"Required JSON file does not exist: {path.relative_to(self.root)}")
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ReleaseError(f"Invalid JSON in {path.relative_to(self.root)}: {error}") from error
        if not isinstance(value, dict):
            raise ReleaseError(f"Expected a JSON object in {path.relative_to(self.root)}")
        return value

    def _validate_config(self) -> None:
        string_fields = (
            "displayName",
            "forgejoBaseUrl",
            "forgejoRepository",
            "androidPackage",
            "apkFilename",
            "expectedCertificateSha256",
            "mainBranch",
            "canonicalRemote",
            "documentationBranch",
        )
        for field in string_fields:
            value = self.config.get(field)
            if not isinstance(value, str) or not value.strip():
                raise ReleaseError(f"release-config.json: {field} must be a non-empty string.")
        parsed_forgejo = urllib.parse.urlparse(self.config["forgejoBaseUrl"])
        if (
            parsed_forgejo.scheme != "https"
            or not parsed_forgejo.hostname
            or parsed_forgejo.username
            or parsed_forgejo.password
            or parsed_forgejo.path not in {"", "/"}
            or parsed_forgejo.query
            or parsed_forgejo.fragment
        ):
            raise ReleaseError(
                "release-config.json: forgejoBaseUrl must be an HTTPS origin without credentials."
            )
        if not re.fullmatch(r"[^/\s]+/[^/\s]+", self.config["forgejoRepository"]):
            raise ReleaseError(
                "release-config.json: forgejoRepository must use owner/repository form."
            )
        mirror_enabled = self.config.get("githubMirrorEnabled")
        if not isinstance(mirror_enabled, bool):
            raise ReleaseError("release-config.json: githubMirrorEnabled must be boolean.")
        if mirror_enabled:
            for field in ("githubRepository", "githubRemote"):
                value = self.config.get(field)
                if not isinstance(value, str) or not value.strip():
                    raise ReleaseError(
                        f"release-config.json: {field} must be set when the GitHub mirror is enabled."
                    )
        offset = self.config.get("androidAbiVersionCodeOffset", 0)
        if not isinstance(offset, int) or offset < 0:
            raise ReleaseError(
                "release-config.json: androidAbiVersionCodeOffset must be a non-negative integer."
            )
        monitored = self.config.get("monitoredCodePaths")
        if not isinstance(monitored, list) or not monitored or not all(
            isinstance(path, str) and path for path in monitored
        ):
            raise ReleaseError(
                "release-config.json: monitoredCodePaths must contain path strings."
            )

    def _read_version(self) -> AppVersion:
        pubspec = (self.root / "pubspec.yaml").read_text(encoding="utf-8")
        match = re.search(r"^version:\s*([^+\s]+)\+(\d+)\s*$", pubspec, re.MULTILINE)
        if not match:
            raise ReleaseError("pubspec.yaml must contain version: MAJOR.MINOR.PATCH+BUILD")
        version = AppVersion(match.group(1), int(match.group(2)))
        version.semver
        return version

    def _read_backfill_version(self, tag: str) -> AppVersion:
        if not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
            raise ReleaseError("Forgejo backfill tag must use vMAJOR.MINOR.PATCH.")
        name = tag.removeprefix("v")
        manifest = self._load_json(self.root / "release/manifests" / f"{name}.json")
        code = manifest.get("versionCode")
        if not isinstance(code, int) or code < 1:
            raise ReleaseError(f"release/manifests/{name}.json: versionCode must be positive.")
        version = AppVersion(name, code)
        version.semver
        return version

    def _git(self, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        return self.runner.run(
            ["git", *args], cwd=self.root, check=check, capture=True
        )

    def _git_output(self, *args: str) -> str:
        return self._git(*args).stdout.strip()

    def _preflight_git(self) -> None:
        branch = self._git_output("branch", "--show-current")
        expected_branch = self.config["mainBranch"]
        if branch != expected_branch:
            raise ReleaseError(
                f"Releases must run from {expected_branch!r}; current branch is {branch!r}."
            )

        status = self._git_output("status", "--porcelain", "--untracked-files=all")
        if status:
            raise ReleaseError(
                "The release working tree must be clean. Commit or remove these changes:\n"
                + status
            )

        canonical_remote = self.config["canonicalRemote"]
        remotes = [canonical_remote]
        if self.config["githubMirrorEnabled"]:
            github_remote = self.config["githubRemote"]
            if canonical_remote == github_remote:
                raise ReleaseError(
                    "release-config.json: canonicalRemote and githubRemote must be different."
                )
            remotes.append(github_remote)
        for remote in remotes:
            if self._git("remote", "get-url", remote, check=False).returncode != 0:
                raise ReleaseError(f"Configured Git remote does not exist: {remote}")

        self._git("fetch", canonical_remote, "--tags", "--prune")
        remote_branch = f"{canonical_remote}/{expected_branch}"
        ancestor = self._git(
            "merge-base", "--is-ancestor", remote_branch, "HEAD", check=False
        )
        if ancestor.returncode != 0:
            raise ReleaseError(
                f"HEAD is outdated or diverged from {remote_branch}; reconcile it before release."
            )

        tags = [
            tag
            for tag in self._git_output(
                "tag", "--list", "v*", "--sort=-version:refname"
            ).splitlines()
            if re.fullmatch(r"v\d+\.\d+\.\d+", tag)
        ]
        current_tag_exists = self.version.tag in tags
        self.latest_tag = next(
            (tag for tag in tags if tag != self.version.tag), None
        )

        if current_tag_exists:
            tag_commit = self._git_output("rev-list", "-n", "1", self.version.tag)
            head_commit = self._git_output("rev-parse", "HEAD")
            if tag_commit != head_commit:
                raise ReleaseError(
                    f"Existing {self.version.tag} does not point at HEAD; versions are immutable."
                )
        elif self.latest_tag:
            previous = AppVersion(self.latest_tag.removeprefix("v"), 0)
            if self.version.semver <= previous.semver:
                raise ReleaseError(
                    f"{self.version.name} must be newer than the latest tag {self.latest_tag}."
                )

        if self.latest_tag:
            changed = self._git_output("diff", "--name-only", f"{self.latest_tag}..HEAD")
        else:
            changed = self._git_output("ls-files")
        self.changed_paths = {line for line in changed.splitlines() if line}

    def _validate_release_metadata(self) -> None:
        self.manifest = self._load_json(self.manifest_path)
        expected = {
            "version": self.version.name,
            "versionCode": self.version.code,
            "releaseNotes": f"docs/releases/{self.version.name}.md",
        }
        for key, value in expected.items():
            if self.manifest.get(key) != value:
                raise ReleaseError(
                    f"{self.manifest_path.relative_to(self.root)}: {key} must be {value!r}."
                )

        notes = self.root / expected["releaseNotes"]
        if not notes.is_file() or not notes.read_text(encoding="utf-8").strip():
            raise ReleaseError(f"Release notes are missing or empty: {notes.relative_to(self.root)}")

        impact = self.manifest.get("docsImpact")
        guide_paths = self.manifest.get("updatedGuidePaths")
        reason = self.manifest.get("noDocsReason")
        if impact not in {"updated", "none"}:
            raise ReleaseError("docsImpact must be either 'updated' or 'none'.")
        if not isinstance(guide_paths, list) or not all(
            isinstance(path, str) for path in guide_paths
        ):
            raise ReleaseError("updatedGuidePaths must be an array of paths.")
        if impact == "updated" and not guide_paths:
            raise ReleaseError("docsImpact 'updated' requires at least one updatedGuidePath.")
        if impact == "none" and (not isinstance(reason, str) or not reason.strip()):
            raise ReleaseError("docsImpact 'none' requires a non-empty noDocsReason.")
        if impact == "none" and guide_paths:
            raise ReleaseError("docsImpact 'none' cannot list updatedGuidePaths.")

        for value in guide_paths:
            path = self.root / value
            if not (value.startswith("docs/") or value == "README.md") or not path.is_file():
                raise ReleaseError(f"Updated guide does not exist: {value}")
            if value not in self.changed_paths:
                raise ReleaseError(f"Updated guide was not changed since the last release: {value}")

        screenshots = self.manifest.get("outstandingScreenshots")
        if not isinstance(screenshots, list) or not all(
            isinstance(item, str) and item.strip() for item in screenshots
        ):
            raise ReleaseError("outstandingScreenshots must be an array of non-empty IDs.")
        backlog_path = self.root / "docs/screenshot-backlog.md"
        if screenshots:
            if not backlog_path.is_file():
                raise ReleaseError("Outstanding screenshots require docs/screenshot-backlog.md.")
            backlog = backlog_path.read_text(encoding="utf-8")
            missing = [item for item in screenshots if f"`{item}`" not in backlog]
            if missing:
                raise ReleaseError(
                    "Screenshot IDs missing from docs/screenshot-backlog.md: "
                    + ", ".join(missing)
                )

        previous_codes: list[int] = []
        for path in (self.root / "release/manifests").glob("*.json"):
            if path == self.manifest_path:
                continue
            data = self._load_json(path)
            code = data.get("versionCode")
            if isinstance(code, int):
                previous_codes.append(code)
        if previous_codes and self.version.code <= max(previous_codes):
            raise ReleaseError("versionCode must increase monotonically across release manifests.")

    def _validate_change_fragments(self) -> None:
        unreleased = sorted((self.root / ".changes/unreleased").glob("*.json"))
        if unreleased:
            names = "\n".join(f"- {path.relative_to(self.root)}" for path in unreleased)
            raise ReleaseError(
                "Archive all unreleased change fragments into this release before publishing:\n"
                + names
            )

        fragment_values = self.manifest.get("changeFragments")
        if not isinstance(fragment_values, list) or not fragment_values:
            raise ReleaseError("changeFragments must list at least one archived fragment.")

        known_ids: set[str] = set()
        for value in fragment_values:
            if not isinstance(value, str):
                raise ReleaseError("Every changeFragments entry must be a path string.")
            expected_prefix = f"release/fragments/{self.version.name}/"
            if not value.startswith(expected_prefix):
                raise ReleaseError(f"Fragment must be archived under {expected_prefix}: {value}")
            fragment = self._load_json(self.root / value)
            self._validate_fragment(value, fragment, known_ids)

        if self.latest_tag:
            self._audit_commits_for_fragments(self.latest_tag)

    def _validate_fragment(
        self, path: str, fragment: dict[str, Any], known_ids: set[str]
    ) -> None:
        fragment_id = fragment.get("id")
        if not isinstance(fragment_id, str) or not re.fullmatch(
            r"[a-z0-9][a-z0-9-]*", fragment_id
        ):
            raise ReleaseError(f"{path}: id must be a lowercase kebab-case string.")
        if fragment_id in known_ids:
            raise ReleaseError(f"Duplicate change fragment id: {fragment_id}")
        known_ids.add(fragment_id)

        for key in ("summary", "releaseNote"):
            if not isinstance(fragment.get(key), str) or not fragment[key].strip():
                raise ReleaseError(f"{path}: {key} must be a non-empty string.")
        if fragment.get("audience") not in {"user", "maintainer", "internal"}:
            raise ReleaseError(f"{path}: audience is invalid.")

        docs = fragment.get("docs")
        if not isinstance(docs, dict):
            raise ReleaseError(f"{path}: docs must be an object.")
        impact = docs.get("impact")
        paths = docs.get("paths")
        reason = docs.get("reason")
        if impact not in {"updated", "none"}:
            raise ReleaseError(f"{path}: archived docs impact must be 'updated' or 'none'.")
        if not isinstance(paths, list) or not all(isinstance(item, str) for item in paths):
            raise ReleaseError(f"{path}: docs.paths must be an array of paths.")
        if impact == "updated" and not paths:
            raise ReleaseError(f"{path}: updated docs require at least one path.")
        if impact == "none" and (not isinstance(reason, str) or not reason.strip()):
            raise ReleaseError(f"{path}: no docs impact requires a reason.")
        for docs_path in paths:
            if not (self.root / docs_path).is_file():
                raise ReleaseError(f"{path}: referenced documentation is missing: {docs_path}")

        screenshots = fragment.get("screenshots")
        if not isinstance(screenshots, list) or not all(
            isinstance(item, str) for item in screenshots
        ):
            raise ReleaseError(f"{path}: screenshots must be an array of IDs.")
        outstanding = self.manifest.get("outstandingScreenshots", [])
        missing = [item for item in screenshots if item not in outstanding]
        if missing:
            raise ReleaseError(
                f"{path}: screenshot IDs are absent from the release manifest: "
                + ", ".join(missing)
            )

    def _commit_audit_exceptions(self, release_commits: set[str]) -> dict[str, str]:
        values = self.manifest.get("commitAuditExceptions", [])
        if not isinstance(values, list):
            raise ReleaseError("commitAuditExceptions must be an array.")

        manifest_fragments = set(self.manifest.get("changeFragments", []))
        monitored = tuple(self.config["monitoredCodePaths"])
        exceptions: dict[str, str] = {}
        for value in values:
            if not isinstance(value, dict):
                raise ReleaseError("Every commitAuditExceptions entry must be an object.")
            commit = value.get("commit")
            originating_commit = value.get("originatingCommit")
            fragment = value.get("fragment")
            reason = value.get("reason")
            for field, revision in (
                ("commit", commit),
                ("originatingCommit", originating_commit),
            ):
                if not isinstance(revision, str) or not re.fullmatch(
                    r"(?:[0-9a-f]{40}|[0-9a-f]{64})", revision
                ):
                    raise ReleaseError(
                        f"commitAuditExceptions {field} values must be full lowercase "
                        "immutable SHAs."
                    )
            if commit in exceptions:
                raise ReleaseError(f"Duplicate commit audit exception: {commit}")
            if commit not in release_commits:
                raise ReleaseError(
                    f"Commit audit exception is outside this release range: {commit}"
                )
            if originating_commit not in release_commits:
                raise ReleaseError(
                    "Commit audit exception originating commit is outside this release "
                    f"range: {originating_commit}"
                )
            if self._git(
                "merge-base", "--is-ancestor", originating_commit, commit, check=False
            ).returncode != 0:
                raise ReleaseError(
                    "Commit audit exception must follow its originating commit: "
                    f"{commit}"
                )
            if not isinstance(fragment, str) or fragment not in manifest_fragments:
                raise ReleaseError(
                    f"Commit audit exception must reference a listed change fragment: {commit}"
                )
            if not isinstance(reason, str) or not reason.strip():
                raise ReleaseError(
                    f"Commit audit exception requires a non-empty reason: {commit}"
                )

            fragment_id = self._load_json(self.root / fragment).get("id")
            originating_paths = self._git_output(
                "diff-tree", "--no-commit-id", "--name-only", "-r", originating_commit
            ).splitlines()
            recorded_fragment = False
            for path in originating_paths:
                if not (
                    path.startswith(".changes/unreleased/")
                    or path.startswith("release/fragments/")
                ):
                    continue
                historical = self._git("show", f"{originating_commit}:{path}", check=False)
                if historical.returncode != 0:
                    continue
                try:
                    historical_fragment = json.loads(historical.stdout)
                except json.JSONDecodeError:
                    continue
                if (
                    isinstance(historical_fragment, dict)
                    and historical_fragment.get("id") == fragment_id
                ):
                    recorded_fragment = True
                    break
            if not recorded_fragment:
                raise ReleaseError(
                    "Commit audit exception originating commit did not record the linked "
                    f"fragment: {commit}"
                )

            commit_paths = self._git_output(
                "diff-tree", "--no-commit-id", "--name-only", "-r", commit
            ).splitlines()
            originating_code = {
                path for path in originating_paths if path.startswith(monitored)
            }
            exception_code = {path for path in commit_paths if path.startswith(monitored)}
            if not originating_code.intersection(exception_code):
                raise ReleaseError(
                    "Commit audit exception does not share an application path with its "
                    f"originating implementation: {commit}"
                )
            exceptions[commit] = fragment
        return exceptions

    def _audit_commits_for_fragments(self, since_tag: str) -> None:
        commits = self._git_output("rev-list", "--reverse", f"{since_tag}..HEAD")
        release_commits = set(commits.splitlines())
        exceptions = self._commit_audit_exceptions(release_commits)
        used_exceptions: set[str] = set()
        monitored = tuple(self.config["monitoredCodePaths"])
        missing: list[str] = []
        for commit in commits.splitlines():
            paths = self._git_output(
                "diff-tree", "--no-commit-id", "--name-only", "-r", commit
            ).splitlines()
            if not any(path.startswith(monitored) for path in paths):
                continue
            has_fragment = any(
                path.startswith(".changes/unreleased/")
                or path.startswith("release/fragments/")
                for path in paths
            )
            message = self._git_output("show", "-s", "--format=%B", commit)
            no_impact = bool(
                re.search(r"^Release-Impact:\s*none\s*$", message, re.MULTILINE)
            )
            if has_fragment or no_impact:
                continue
            if commit in exceptions:
                used_exceptions.add(commit)
                continue
            missing.append(self._git_output("show", "-s", "--format=%h %s", commit))

        unused_exceptions = sorted(set(exceptions) - used_exceptions)
        if unused_exceptions:
            raise ReleaseError(
                "Commit audit exceptions must identify monitored application-code commits "
                "that otherwise fail the audit:\n- " + "\n- ".join(unused_exceptions)
            )
        if missing:
            raise ReleaseError(
                "Application-code commits without a change fragment or "
                "'Release-Impact: none' trailer:\n- " + "\n- ".join(missing)
            )

    def _validate_no_tracked_secrets(self) -> None:
        tracked = self._git_output("ls-files").splitlines()
        forbidden = [
            path
            for path in tracked
            if Path(path).name == "key.properties"
            or Path(path).suffix.lower() in {".jks", ".keystore"}
        ]
        if forbidden:
            raise ReleaseError("Signing credentials are tracked by Git: " + ", ".join(forbidden))

    def _run_validations(self) -> None:
        self._ensure_docs_environment()
        mkdocs = self.root / ".venv-docs/bin/mkdocs"
        commands = [
            ["flutter", "analyze", "--fatal-infos"],
            ["flutter", "test"],
            [mkdocs, "build", "--strict", "--clean"],
            [
                "flutter",
                "build",
                "apk",
                "--release",
                "--split-per-abi",
                "--target-platform",
                "android-arm64",
            ],
        ]
        for command in commands:
            self.runner.run(command, cwd=self.root)

    def _docs_python_is_usable(self, python: Path) -> bool:
        if not python.is_file():
            return False
        try:
            result = self.runner.run(
                [python, "--version"], cwd=self.root, check=False, capture=True
            )
        except OSError:
            return False
        return result.returncode == 0

    def _ensure_docs_environment(self) -> None:
        environment = self.root / ".venv-docs"
        python = environment / "bin/python"
        requirement = self.root / "docs/requirements.txt"
        stamp = environment / ".requirements-sha256"
        digest = hashlib.sha256(requirement.read_bytes()).hexdigest()
        if not self._docs_python_is_usable(python):
            shutil.rmtree(environment, ignore_errors=True)
            self.runner.run([sys.executable, "-m", "venv", ".venv-docs"], cwd=self.root)
        installed = stamp.read_text(encoding="utf-8").strip() if stamp.is_file() else ""
        if installed != digest:
            self.runner.run(
                [python, "-m", "pip", "install", "--disable-pip-version-check", "-r", requirement],
                cwd=self.root,
            )
            stamp.write_text(digest + "\n", encoding="utf-8")

    def _android_sdk(self) -> Path:
        for variable in ("ANDROID_SDK_ROOT", "ANDROID_HOME"):
            if os.environ.get(variable):
                return Path(os.environ[variable]).expanduser()
        properties = self.root / "android/local.properties"
        for line in properties.read_text(encoding="utf-8").splitlines():
            if line.startswith("sdk.dir="):
                return Path(line.split("=", 1)[1].replace(r"\:", ":").replace(r"\\", "\\"))
        raise ReleaseError("Android SDK path was not found.")

    def _build_tool(self, name: str) -> Path:
        candidates = list((self._android_sdk() / "build-tools").glob(f"*/{name}"))
        if not candidates:
            raise ReleaseError(f"Android build tool is unavailable: {name}")

        def version_key(path: Path) -> tuple[int, ...]:
            values = re.findall(r"\d+", path.parent.name)
            return tuple(int(value) for value in values)

        return max(candidates, key=version_key)

    def _stage_and_verify_apk(self) -> tuple[Path, Path]:
        source = self.root / "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
        if not source.is_file():
            raise ReleaseError(f"Flutter did not produce {source.relative_to(self.root)}")
        output_dir = self.root / "build/release"
        output_dir.mkdir(parents=True, exist_ok=True)
        apk = output_dir / self.config["apkFilename"]
        shutil.copy2(source, apk)
        self._verify_apk(apk)

        sha256 = self._sha256(apk)
        checksum = apk.with_suffix(apk.suffix + ".sha256")
        checksum.write_text(f"{sha256}  {apk.name}\n", encoding="utf-8")
        return apk, checksum

    def _verify_apk(self, apk: Path) -> None:
        if not apk.is_file():
            raise ReleaseError(f"Release APK is missing: {apk}")
        badging = self.runner.run(
            [self._build_tool("aapt"), "dump", "badging", apk],
            cwd=self.root,
            capture=True,
        ).stdout
        package = re.search(
            r"^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",
            badging,
            re.MULTILINE,
        )
        if not package:
            raise ReleaseError("Could not read package metadata from the APK.")
        actual_package, actual_code, actual_name = package.groups()
        if actual_package != self.config["androidPackage"]:
            raise ReleaseError(f"APK package is {actual_package}, expected {self.config['androidPackage']}.")
        expected_apk_code = self.version.code + int(
            self.config.get("androidAbiVersionCodeOffset", 0)
        )
        if actual_code != str(expected_apk_code) or actual_name != self.version.name:
            raise ReleaseError(
                f"APK version is {actual_name}+{actual_code}, expected "
                f"{self.version.name}+{expected_apk_code} (base build "
                f"{self.version.code})."
            )
        native_code = re.search(r"^native-code:\s*(.+)$", badging, re.MULTILINE)
        if not native_code or re.findall(r"'([^']+)'", native_code.group(1)) != ["arm64-v8a"]:
            raise ReleaseError("APK must contain only the arm64-v8a native architecture.")

        certificate = self.runner.run(
            [self._build_tool("apksigner"), "verify", "--print-certs", apk],
            cwd=self.root,
            capture=True,
        ).stdout
        digest_match = re.search(
            r"certificate SHA-256 digest:\s*([0-9a-fA-F]+)", certificate
        )
        if not digest_match:
            raise ReleaseError("Could not read the APK signing certificate fingerprint.")
        actual_digest = digest_match.group(1).lower()
        if actual_digest != self.config["expectedCertificateSha256"].lower():
            raise ReleaseError(
                f"APK certificate is {actual_digest}, expected "
                f"{self.config['expectedCertificateSha256']}."
            )

    def _verify_checksum_file(self, apk: Path, checksum: Path) -> None:
        expected = f"{self._sha256(apk)}  {apk.name}\n"
        if not checksum.is_file() or checksum.read_text(encoding="utf-8") != expected:
            raise ReleaseError("APK checksum file does not match the release APK.")

    def _sha256(self, path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def _publish(self, apk: Path, checksum: Path) -> None:
        self._forgejo_token()
        canonical_remote = self.config["canonicalRemote"]
        branch = self.config["mainBranch"]
        self.runner.run(["git", "push", canonical_remote, branch], cwd=self.root)
        self._ensure_release_tag()
        self.runner.run(
            ["git", "push", canonical_remote, self.version.tag], cwd=self.root
        )

        self._publish_forgejo_release(apk, checksum)
        if self.config["githubMirrorEnabled"]:
            self._publish_github_mirror(apk, checksum)

    def _ensure_release_tag(self) -> None:
        tag_result = self._git("rev-parse", "--verify", self.version.tag, check=False)
        if tag_result.returncode != 0:
            self.runner.run(
                [
                    "git",
                    "tag",
                    "-a",
                    self.version.tag,
                    "-m",
                    f"{self.config['displayName']} {self.version.name}",
                ],
                cwd=self.root,
            )
        elif self._git_output("rev-list", "-n", "1", self.version.tag) != self._git_output(
            "rev-parse", "HEAD"
        ):
            raise ReleaseError(f"Existing {self.version.tag} does not point at HEAD.")

    def _forgejo_token(self) -> str:
        expected_host = urllib.parse.urlparse(self.config["forgejoBaseUrl"]).hostname
        environment_token = os.environ.get("WORKOUT_OF_RECORD_FORGEJO_TOKEN")
        if environment_token:
            if os.environ.get("WORKOUT_OF_RECORD_FORGEJO_TOKEN_HOST") != expected_host:
                raise ReleaseError(
                    "WORKOUT_OF_RECORD_FORGEJO_TOKEN_HOST must match the configured Forgejo host."
                )
            token = environment_token.strip()
            if not token:
                raise ReleaseError("WORKOUT_OF_RECORD_FORGEJO_TOKEN must not be empty.")
            return token

        config_home = Path(
            os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")
        ).expanduser()
        token_path = config_home / "workout-of-record/forgejo-release.token"
        if not token_path.is_file():
            raise ReleaseError(
                f"Forgejo release token is missing: {token_path}."
            )
        metadata = token_path.stat()
        if metadata.st_uid != os.getuid() or metadata.st_mode & 0o777 != 0o600:
            raise ReleaseError(
                f"Forgejo release token must be owned by the current user with mode 0600: {token_path}"
            )
        token = token_path.read_text(encoding="utf-8").strip()
        if not token:
            raise ReleaseError(f"Forgejo release token is empty: {token_path}")
        return token

    def _forgejo_api(
        self,
        method: str,
        path: str,
        *,
        payload: dict[str, Any] | None = None,
        data: bytes | None = None,
        content_type: str | None = None,
        allow_not_found: bool = False,
    ) -> Any:
        if payload is not None and data is not None:
            raise ReleaseError("Forgejo API request cannot contain JSON and binary data together.")
        body = json.dumps(payload).encode() if payload is not None else data
        headers = {
            "Authorization": f"token {self._forgejo_token()}",
            "Accept": "application/json",
        }
        if payload is not None:
            headers["Content-Type"] = "application/json"
        elif content_type:
            headers["Content-Type"] = content_type
        url = self.config["forgejoBaseUrl"].rstrip("/") + "/api/v1" + path
        request = urllib.request.Request(url, data=body, method=method, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                response_body = response.read()
        except urllib.error.HTTPError as error:
            if allow_not_found and error.code == 404:
                return None
            detail = error.read().decode("utf-8", errors="replace")[:500]
            raise ReleaseError(
                f"Forgejo API {method} {path} failed with HTTP {error.code}: {detail}"
            ) from error
        except OSError as error:
            raise ReleaseError(f"Forgejo API {method} {path} failed: {error}") from error
        if not response_body:
            return None
        try:
            return json.loads(response_body)
        except json.JSONDecodeError as error:
            raise ReleaseError(f"Forgejo API returned invalid JSON for {path}.") from error

    def _forgejo_repository_path(self) -> str:
        owner, repository = self.config["forgejoRepository"].split("/", 1)
        return "/repos/{}/{}".format(
            urllib.parse.quote(owner, safe=""),
            urllib.parse.quote(repository, safe=""),
        )

    def _forgejo_release_state(self) -> dict[str, Any] | None:
        tag = urllib.parse.quote(self.version.tag, safe="")
        value = self._forgejo_api(
            "GET",
            f"{self._forgejo_repository_path()}/releases/tags/{tag}",
            allow_not_found=True,
        )
        if value is None:
            return None
        if not isinstance(value, dict):
            raise ReleaseError("Unexpected Forgejo release response.")
        return value

    def _validate_forgejo_release_metadata(self, release: dict[str, Any]) -> None:
        if not isinstance(release.get("draft"), bool):
            raise ReleaseError("Forgejo release response is missing its draft state.")
        notes = (self.root / self.manifest["releaseNotes"]).read_text(encoding="utf-8")
        expected = {
            "tag_name": self.version.tag,
            "name": f"{self.config['displayName']} {self.version.name}",
            "body": notes,
            "prerelease": False,
        }
        mismatched = [key for key, value in expected.items() if release.get(key) != value]
        if mismatched:
            raise ReleaseError(
                "Existing Forgejo release metadata differs for: " + ", ".join(mismatched)
            )

    def _download_forgejo_asset(self, asset: dict[str, Any], destination: Path) -> None:
        url = asset.get("browser_download_url")
        if not isinstance(url, str) or not url:
            raise ReleaseError("Forgejo release asset is missing its download URL.")
        headers = {"Authorization": f"token {self._forgejo_token()}"}
        request = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=120) as response, destination.open("wb") as output:
                shutil.copyfileobj(response, output)
        except OSError as error:
            raise ReleaseError(f"Could not download Forgejo release asset: {error}") from error

    def _ensure_forgejo_release_asset(
        self,
        local: Path,
        release: dict[str, Any],
        *,
        allow_upload: bool,
    ) -> bool:
        assets = [
            asset
            for asset in release.get("assets", [])
            if isinstance(asset, dict) and asset.get("name") == local.name
        ]
        if len(assets) > 1:
            raise ReleaseError(f"Forgejo release has duplicate assets named {local.name}.")
        if not assets:
            if not allow_upload:
                raise ReleaseError(
                    f"Published Forgejo release is missing required asset {local.name}."
                )
            release_id = release.get("id")
            if not isinstance(release_id, int):
                raise ReleaseError("Forgejo release response is missing its numeric ID.")
            name = urllib.parse.quote(local.name, safe="")
            self._forgejo_api(
                "POST",
                f"{self._forgejo_repository_path()}/releases/{release_id}/assets?name={name}",
                data=local.read_bytes(),
                content_type="application/octet-stream",
            )
            return True

        with tempfile.TemporaryDirectory(prefix="forgejo-release-asset-") as directory:
            remote = Path(directory) / local.name
            self._download_forgejo_asset(assets[0], remote)
            if self._sha256(remote) != self._sha256(local):
                raise ReleaseError(
                    f"Forgejo already has a different asset named {local.name}; refusing to replace it."
                )
        return False

    def _publish_forgejo_release(self, apk: Path, checksum: Path) -> None:
        self.manifest = self.manifest or self._load_json(self.manifest_path)
        release = self._forgejo_release_state()
        if release is None:
            notes = (self.root / self.manifest["releaseNotes"]).read_text(encoding="utf-8")
            value = self._forgejo_api(
                "POST",
                f"{self._forgejo_repository_path()}/releases",
                payload={
                    "tag_name": self.version.tag,
                    "target_commitish": self._git_output("rev-list", "-n", "1", self.version.tag),
                    "name": f"{self.config['displayName']} {self.version.name}",
                    "body": notes,
                    "draft": True,
                    "prerelease": False,
                },
            )
            if not isinstance(value, dict):
                raise ReleaseError("Forgejo release was not created.")
            release = value
        self._validate_forgejo_release_metadata(release)

        is_draft = release.get("draft") is True
        for asset in (apk, checksum):
            uploaded = self._ensure_forgejo_release_asset(
                asset, release, allow_upload=is_draft
            )
            if uploaded:
                release = self._forgejo_release_state() or release
                self._ensure_forgejo_release_asset(
                    asset, release, allow_upload=False
                )
        if not is_draft:
            print(f"Forgejo {self.version.tag} is already published and its assets match.")
            return

        release_id = release.get("id")
        if not isinstance(release_id, int):
            raise ReleaseError("Forgejo release response is missing its numeric ID.")
        value = self._forgejo_api(
            "PATCH",
            f"{self._forgejo_repository_path()}/releases/{release_id}",
            payload={"draft": False},
        )
        if not isinstance(value, dict) or value.get("draft") is not False:
            raise ReleaseError("Forgejo release did not become public.")
        self._validate_forgejo_release_metadata(value)
        print(f"Published canonical Forgejo release {self.version.tag}.")

    def _publish_github_mirror(self, apk: Path, checksum: Path) -> None:
        if shutil.which("gh") is None:
            raise ReleaseError("GitHub CLI is required while the GitHub mirror is enabled.")
        self.runner.run(["gh", "auth", "status"], cwd=self.root)
        canonical_remote = self.config["canonicalRemote"]
        github_remote = self.config["githubRemote"]
        github_repository = self.config["githubRepository"]
        branch = self.config["mainBranch"]
        self.runner.run(["git", "push", github_remote, branch], cwd=self.root)
        self.runner.run(["git", "push", github_remote, self.version.tag], cwd=self.root)

        release = self._github_release_state()
        notes = self.root / self.manifest["releaseNotes"]
        if release is None:
            self.runner.run(
                [
                    "gh", "release", "create", self.version.tag,
                    "--repo", github_repository, "--draft", "--verify-tag",
                    "--title", f"{self.config['displayName']} {self.version.name}",
                    "--notes-file", notes,
                ],
                cwd=self.root,
            )
            release = self._github_release_state()
        if release is None:
            raise ReleaseError("GitHub mirror release was not created.")
        self._validate_github_release_metadata(release)

        for asset in (apk, checksum):
            self._ensure_github_release_asset(asset, release)
            release = self._github_release_state() or release

        if not release.get("isDraft"):
            print(f"GitHub mirror {self.version.tag} is already published and its assets match.")
            return

        mkdocs = self.root / ".venv-docs/bin/mkdocs"
        self.runner.run(
            [
                mkdocs, "gh-deploy", "--force", "--clean",
                "--remote-name", github_remote,
                "--message", f"docs: {self.version.tag}",
            ],
            cwd=self.root,
        )
        self._ensure_github_pages()
        documentation_branch = self.config["documentationBranch"]
        self.runner.run(
            ["git", "fetch", github_remote, documentation_branch], cwd=self.root
        )
        self.runner.run(
            [
                "git", "push", canonical_remote,
                f"{github_remote}/{documentation_branch}:{documentation_branch}",
            ],
            cwd=self.root,
        )
        self.runner.run(
            [
                "gh", "release", "edit", self.version.tag,
                "--repo", github_repository, "--draft=false",
            ],
            cwd=self.root,
        )

    def _github_release_state(self) -> dict[str, Any] | None:
        result = self.runner.run(
            [
                "gh", "release", "view", self.version.tag,
                "--repo", self.config["githubRepository"],
                "--json", "isDraft,assets,url,tagName,name,body",
            ],
            cwd=self.root,
            check=False,
            capture=True,
        )
        if result.returncode != 0:
            return None
        value = json.loads(result.stdout)
        if not isinstance(value, dict):
            raise ReleaseError("Unexpected GitHub release response.")
        return value

    def _validate_github_release_metadata(self, release: dict[str, Any]) -> None:
        notes = (self.root / self.manifest["releaseNotes"]).read_text(encoding="utf-8")
        expected = {
            "tagName": self.version.tag,
            "name": f"{self.config['displayName']} {self.version.name}",
            "body": notes,
        }
        mismatched = [key for key, value in expected.items() if release.get(key) != value]
        if mismatched:
            raise ReleaseError(
                "Existing GitHub mirror metadata differs for: " + ", ".join(mismatched)
            )

    def _ensure_github_release_asset(self, local: Path, release: dict[str, Any]) -> None:
        names = {
            asset.get("name")
            for asset in release.get("assets", [])
            if isinstance(asset, dict)
        }
        if local.name not in names:
            self.runner.run(
                [
                    "gh", "release", "upload", self.version.tag,
                    "--repo", self.config["githubRepository"], local,
                ],
                cwd=self.root,
            )
            return

        with tempfile.TemporaryDirectory(prefix="release-asset-") as directory:
            self.runner.run(
                [
                    "gh", "release", "download", self.version.tag,
                    "--repo", self.config["githubRepository"],
                    "--pattern", local.name, "--dir", directory,
                ],
                cwd=self.root,
            )
            remote = Path(directory) / local.name
            if not remote.is_file() or self._sha256(remote) != self._sha256(local):
                raise ReleaseError(
                    f"GitHub already has a different asset named {local.name}; refusing to replace it."
                )

    def _preflight_forgejo_backfill(self) -> None:
        branch = self._git_output("branch", "--show-current")
        expected_branch = self.config["mainBranch"]
        if branch != expected_branch:
            raise ReleaseError(
                f"Forgejo backfill must run from {expected_branch!r}; current branch is {branch!r}."
            )
        status = self._git_output("status", "--porcelain", "--untracked-files=all")
        if status:
            raise ReleaseError(
                "The Forgejo backfill working tree must be clean. Commit or remove these changes:\n"
                + status
            )
        if not self.config["githubMirrorEnabled"]:
            raise ReleaseError(
                "Forgejo backfill requires the existing GitHub mirror as its asset source."
            )
        for remote in (self.config["canonicalRemote"], self.config["githubRemote"]):
            if self._git("remote", "get-url", remote, check=False).returncode != 0:
                raise ReleaseError(f"Configured Git remote does not exist: {remote}")
        self._git("fetch", self.config["canonicalRemote"], "--tags", "--prune")
        if self._git("rev-parse", "--verify", self.version.tag, check=False).returncode != 0:
            raise ReleaseError(f"Backfill tag does not exist: {self.version.tag}")
        if self._git_output("cat-file", "-t", f"refs/tags/{self.version.tag}") != "tag":
            raise ReleaseError(f"Backfill tag must be annotated: {self.version.tag}")
        tag_commit = self._git_output("rev-list", "-n", "1", self.version.tag)
        if self._git(
            "merge-base", "--is-ancestor", tag_commit, "HEAD", check=False
        ).returncode != 0:
            raise ReleaseError(f"Backfill tag is not an ancestor of HEAD: {self.version.tag}")

        self.manifest = self._load_json(self.manifest_path)
        expected = {
            "version": self.version.name,
            "versionCode": self.version.code,
            "releaseNotes": f"docs/releases/{self.version.name}.md",
        }
        for key, value in expected.items():
            if self.manifest.get(key) != value:
                raise ReleaseError(
                    f"{self.manifest_path.relative_to(self.root)}: {key} must be {value!r}."
                )
        notes = self.root / expected["releaseNotes"]
        if not notes.is_file() or not notes.read_text(encoding="utf-8").strip():
            raise ReleaseError(f"Release notes are missing or empty: {notes.relative_to(self.root)}")
        self._forgejo_token()

    def _backfill_forgejo_release(self) -> None:
        print(f"Backfilling canonical Forgejo release {self.version.tag}", flush=True)
        self._preflight_forgejo_backfill()
        self.runner.run(
            ["git", "push", self.config["canonicalRemote"], self.version.tag],
            cwd=self.root,
        )
        if shutil.which("gh") is None:
            raise ReleaseError("GitHub CLI is required to retrieve the existing mirror assets.")
        self.runner.run(["gh", "auth", "status"], cwd=self.root)
        mirror = self._github_release_state()
        if mirror is None or mirror.get("isDraft") is not False:
            raise ReleaseError("GitHub mirror release must already be public for backfill.")
        self._validate_github_release_metadata(mirror)

        with tempfile.TemporaryDirectory(prefix="forgejo-release-backfill-") as directory:
            asset_directory = Path(directory)
            assets = (
                asset_directory / self.config["apkFilename"],
                asset_directory / f"{self.config['apkFilename']}.sha256",
            )
            for asset in assets:
                self.runner.run(
                    [
                        "gh", "release", "download", self.version.tag,
                        "--repo", self.config["githubRepository"],
                        "--pattern", asset.name, "--dir", asset_directory,
                    ],
                    cwd=self.root,
                )
                if not asset.is_file():
                    raise ReleaseError(f"GitHub mirror asset is missing: {asset.name}")
            apk, checksum = assets
            self._verify_checksum_file(apk, checksum)
            self._verify_apk(apk)
            self._publish_forgejo_release(apk, checksum)
        print(f"Forgejo backfill complete for {self.version.tag}.")

    def _ensure_github_pages(self) -> None:
        repository = self.config["githubRepository"]
        state = self.runner.run(
            ["gh", "api", f"repos/{repository}/pages"],
            cwd=self.root,
            check=False,
            capture=True,
        )
        if state.returncode == 0:
            return
        payload = json.dumps(
            {
                "source": {
                    "branch": self.config["documentationBranch"],
                    "path": "/",
                }
            }
        )
        self.runner.run(
            ["gh", "api", "--method", "POST", f"repos/{repository}/pages", "--input", "-"],
            cwd=self.root,
            input_text=payload,
        )


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(description=__doc__)
    mode = value.add_mutually_exclusive_group()
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Run all local checks and builds without changing Forgejo or GitHub.",
    )
    mode.add_argument(
        "--backfill-forgejo",
        metavar="TAG",
        help="Backfill one canonical Forgejo release from its existing verified GitHub mirror.",
    )
    return value


def main(argv: list[str] | None = None) -> None:
    args = parser().parse_args(argv)
    root = Path(__file__).resolve().parent.parent
    try:
        ReleaseWorkflow(
            root,
            dry_run=args.dry_run,
            backfill_forgejo=args.backfill_forgejo,
        ).execute()
    except ReleaseError as error:
        print(f"release: error: {error}", file=sys.stderr)
        raise SystemExit(1) from error


if __name__ == "__main__":
    main()
