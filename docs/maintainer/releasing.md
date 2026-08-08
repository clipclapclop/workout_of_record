# Releasing

Releases are built on the local Linux workstation. Forgejo is the canonical source repository; GitHub remains the staged APK and documentation distribution destination. The release tool never edits, stages, or commits tracked files.

## One-time workstation setup

Required tools:

- Flutter, Java 17, and the Android SDK;
- the existing ignored `android/key.properties` and release keystore;
- Python 3 with `venv` support;
- Git and authenticated SSH access to canonical Forgejo `origin`;
- a `github` Git remote for `clipclapclop/workout_of_record`; and
- GitHub CLI authenticated for `clipclapclop/workout_of_record`.

Install GitHub CLI using the operating system package manager, then run:

```bash
gh auth login
gh auth status
```

The release command creates `.venv-docs`, rebuilds it if its Python launcher is stale, installs the pinned documentation dependency, and creates/configures `gh-pages` on the first publication.

## Change fragments

Every implementation conversation writes durable release context to `.changes/unreleased/`. Update documentation in that conversation when practical; otherwise mark the documentation decision as deferred with a reason. This prevents a later release conversation from depending on earlier chat context.

When preparing a release, resolve deferred work and move every included fragment into `release/fragments/<version>/`. No unreleased JSON fragments may remain when publishing.

After the first automated release, the tool audits each application-code commit. Such a commit must contain a fragment or the exact trailer:

```text
Release-Impact: none
```

Do not rewrite shared release history merely to repair missing metadata. For an already-published commit that belongs to an implementation whose fragment was recorded in another commit, the release manifest may use `commitAuditExceptions`. Each entry must name the full immutable commit SHA, reference a fragment listed by that manifest, and give a concrete reason. The tool rejects abbreviated SHAs, commits outside the release range, unrelated fragments, duplicate entries, and exceptions for commits that already pass the audit. Treat this as a reviewed recovery mechanism, not the normal fragment workflow.

## Prepare

Ask Codex to **prepare a release**. It will inspect all fragments and the complete diff since the latest version tag, update documentation, increment `pubspec.yaml`, write the version manifest and release notes, and run validation without publishing.

Review and commit the preparation. The resulting working tree must be clean.

## Dry run

```bash
./tool/release --dry-run
```

The dry run fetches canonical Forgejo state, validates metadata and fragments, runs Flutter analysis/tests, builds MkDocs strictly, builds an arm64-only release APK, and verifies package identity, version, architecture, signing certificate, and checksum. Flutter adds its arm64 split offset (`2000`) to the base build number from `pubspec.yaml`; the release tool verifies both values. It does not push or change Forgejo or GitHub.

## Publish

Ask Codex to **publish the prepared release**, or run:

```bash
./tool/release
```

Publishing pushes `main` and the annotated version tag to Forgejo and GitHub, creates a draft GitHub Release, uploads the APK and checksum, deploys MkDocs to GitHub Pages, mirrors `gh-pages` back to Forgejo, and finally makes the release public. Every GitHub CLI operation names `clipclapclop/workout_of_record` explicitly rather than inferring it from canonical `origin`.

## Recovery

The command is rerunnable:

- An existing tag must point to `HEAD`.
- Existing release assets are downloaded and compared before reuse.
- A differing same-name asset is never overwritten.
- Documentation or repository-mirroring failures leave the release as a draft, so Obtainium cannot discover an incomplete release.
- A matching already-published release is treated as complete.

## Phone setup

Install Obtainium once, add `https://github.com/clipclapclop/workout_of_record`, and filter assets to `workout-of-record-android-arm64.apk`. Enable scheduled checks and permit installation from Obtainium. Back up the application before testing the first automated update, then verify the local database and settings remain intact.
