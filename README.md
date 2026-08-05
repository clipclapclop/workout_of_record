# Workout of Record

A private, Android-first Flutter workout logger with persistent in-workout progress, mesocycle planning, history, backups, and optional AI recommendations.

## Repository

The canonical source and issue tracker are hosted on [Forgejo](https://git.oorangy.com/chad/workout_of_record). GitHub remains the staged distribution destination for releases, documentation, and Obtainium updates.

## Six months later: start here

The intended workflow is:

1. Make one or more changes in separate Codex conversations.
2. Each implementation records durable release context in `.changes/unreleased/`; you do not need to keep the conversations open.
3. When the accumulated changes are ready, tell Codex **“Prepare a release.”** This updates the version, user documentation, release notes, and release manifest, then validates without publishing.
4. Review the preparation. When satisfied, tell Codex **“Publish the prepared release.”** That explicitly authorizes the commit, Forgejo and GitHub pushes, tag, GitHub Release, documentation deployment, and APK publication.
5. Obtainium notices the GitHub Release on your Pixel. Approve Android's installation prompt.

For a one-step release, say **“Prepare and publish a patch release.”** Use the two-step form when you want to inspect documentation and release notes first.

Publishing is never implied by an ordinary implementation request.

## One-time computer setup

The workstation needs Flutter, Java, the Android SDK, Python 3, Git, the local signing files, and GitHub CLI. Most are already configured on the original development computer.

Confirm the important pieces:

```bash
flutter --version
test -f android/key.properties
git remote -v  # origin is Forgejo; github is the distribution remote
gh --version
gh auth status
```

If GitHub CLI is not authenticated:

```bash
gh auth login
```

Keep `android/key.properties` and its referenced keystore. They are intentionally ignored by Git and are required to update the installed app with the same signing identity. Back them up securely; do not commit or replace them casually.

## Normal development

Ask Codex to implement changes normally. Repository instructions in [`AGENTS.md`](AGENTS.md) require each substantive application change to create or update a small JSON change fragment. These fragments preserve the intent, release-note text, documentation impact, and screenshot work across unrelated conversations.

Before considering a change complete, run the repository-owned aggregate check:

```bash
./scripts/check
```

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for its locked, offline dependency behavior.

Commit changes in coherent units. If a code commit genuinely has no release or documentation impact, its commit message may use the exact trailer described in `AGENTS.md`:

```text
Release-Impact: none
```

Do not add that trailer merely to bypass a missing fragment.

## Documentation

User and maintainer documentation lives under [`docs/`](docs/index.md) and is built with MkDocs:

```bash
python3 -m venv .venv-docs
.venv-docs/bin/pip install -r docs/requirements.txt
.venv-docs/bin/mkdocs serve
```

## Prepare a release

Preferred method: tell Codex **“Prepare a release.”** It will inspect every unreleased fragment and the complete Git diff since the previous version tag. Conversation memory is not used as the release record.

Preparation should leave you with:

- an incremented version in `pubspec.yaml`;
- `docs/releases/<version>.md`;
- `release/manifests/<version>.json`;
- fragments archived under `release/fragments/<version>/`;
- updated guide pages or an explicit reason that no guide update is needed; and
- no remaining `.changes/unreleased/*.json` files for that release.

Preparation does not publish anything. Review the changes and commit them before running the publisher. The release command deliberately refuses a dirty working tree.

## Validate and publish manually

From a clean `main` branch, run:

```bash
./tool/release --dry-run
./tool/release
```

The dry run performs the same local validation and signed arm64 APK build without pushing, tagging, publishing, or deploying documentation. The publish command then:

1. pushes `main` and an annotated `v<version>` tag to canonical Forgejo and the GitHub distribution remote;
2. creates or resumes a draft GitHub Release;
3. uploads `workout-of-record-android-arm64.apk` and its SHA-256 checksum;
4. deploys the MkDocs site to GitHub's `gh-pages` and mirrors that branch to Forgejo; and
5. publishes the release only after documentation and both repository destinations succeed.

The command never edits, stages, or commits tracked files. It is safe to rerun after a partial failure when the existing tag and assets match.

## One-time phone setup

Install [Obtainium](https://github.com/ImranR98/Obtainium), then:

1. Add `https://github.com/clipclapclop/workout_of_record`.
2. Filter APKs to `workout-of-record-android-arm64.apk`.
3. Enable scheduled background update checks.
4. Allow Obtainium to install unknown apps when Android asks.
5. Back up Workout of Record before the first automated update.

Opening Obtainium forces an immediate check. Otherwise, wait for its configured schedule. A stock Android phone still requires confirmation before installing the downloaded update.

## Common failures

| Message or symptom | What to do |
| --- | --- |
| Working tree must be clean | Run `git status`; review and commit the intended release preparation. Do not blindly discard or stash unfamiliar work. |
| Branch is outdated or diverged | Run `git fetch origin`, inspect `git log --oneline --graph --decorate --all`, and reconcile canonical Forgejo `main` before retrying. |
| Unreleased fragments remain | Ask Codex to prepare the release so deferred docs are resolved and fragments are archived. |
| GitHub CLI is unauthenticated | Run `gh auth login`, then verify with `gh auth status`. |
| APK certificate mismatch | Stop. Confirm the original release keystore and `android/key.properties`; do not publish with a new key. |
| Existing asset differs | Do not overwrite an immutable release. Correct the prepared version or create a newer version. |
| Kotlin migration warning | The build currently remains valid. Follow [`docs/maintainer/kotlin-migration.md`](docs/maintainer/kotlin-migration.md) before a future Flutter upgrade removes compatibility. |
| Obtainium does not see an update | Confirm the GitHub Release is published rather than draft, the asset filename matches the filter, and the new version is greater than the installed version. |

## Detailed references

- [Release setup, invariants, and recovery](docs/maintainer/releasing.md)
- [Installation and Obtainium](docs/guides/installation.md)
- [Release history](docs/releases/index.md)
- [Screenshot backlog](docs/screenshot-backlog.md)

The NAS mirror, silent installation, automated screenshots, and headless LLM documentation generation are intentionally deferred. GitHub Releases and one Android confirmation are the supported path.
