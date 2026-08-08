# Releasing

Releases are built on the local Linux workstation. Forgejo is the canonical source and release authority. GitHub is an optional mirror for Obtainium and documentation while `githubMirrorEnabled` is true in `tool/release-config.json`. The release tool never edits, stages, or commits tracked files.

## One-time workstation setup

Required tools:

- Flutter, Java 17, and the Android SDK;
- the existing ignored `android/key.properties` and release keystore;
- Python 3 with `venv` support;
- Git and authenticated SSH access to canonical Forgejo `origin`;
- a Forgejo token with repository release write access; and
- while GitHub mirroring is enabled, a `github` Git remote for `clipclapclop/workout_of_record` and GitHub CLI authenticated for that repository.

Store the Forgejo token outside the repository with owner-only permissions:

```bash
install -d -m 700 ~/.config/workout-of-record
install -m 600 /dev/null ~/.config/workout-of-record/forgejo-release.token
vim ~/.config/workout-of-record/forgejo-release.token
```

For an ephemeral environment, `WORKOUT_OF_RECORD_FORGEJO_TOKEN` is accepted only when `WORKOUT_OF_RECORD_FORGEJO_TOKEN_HOST=git.oorangy.com` is also set. Do not put the token on a command line or in a tracked file.

When GitHub mirroring is enabled, install GitHub CLI using the operating system package manager, then run:

```bash
gh auth login
gh auth status
```

The release command creates `.venv-docs`, rebuilds it if its Python launcher is stale, installs the pinned documentation dependency, and creates/configures `gh-pages` on the first mirrored publication.

## Change fragments

Every implementation conversation writes durable release context to `.changes/unreleased/`. Update documentation in that conversation when practical; otherwise mark the documentation decision as deferred with a reason. This prevents a later release conversation from depending on earlier chat context.

When preparing a release, resolve deferred work and move every included fragment into `release/fragments/<version>/`. No unreleased JSON fragments may remain when publishing.

After the first automated release, the tool audits each application-code commit. Such a commit must contain a fragment or the exact trailer:

```text
Release-Impact: none
```

Do not rewrite shared release history merely to repair missing metadata. For an already-published commit that belongs to an implementation whose fragment was recorded in another commit, the release manifest may use `commitAuditExceptions`. Each entry must name the full immutable exception and originating commit SHAs, reference a fragment listed by that manifest, and give a concrete reason. The originating commit must precede the exception, must have recorded the linked fragment ID, and must share a monitored application path with the follow-up commit. The tool also rejects abbreviated SHAs, commits outside the release range, duplicate entries, and exceptions for commits that already pass the audit. Treat this as a reviewed recovery mechanism, not the normal fragment workflow.

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

Publication is Forgejo-first:

1. Push `main` and the annotated version tag to Forgejo.
2. Create or resume a draft Forgejo Release using the prepared notes.
3. Upload the APK and checksum, download each attachment again, and compare it byte-for-byte by SHA-256.
4. Publish the canonical Forgejo Release.
5. If `githubMirrorEnabled` is true, push the same branch and tag to GitHub, reconcile matching GitHub Release assets, deploy MkDocs to GitHub Pages, mirror `gh-pages` back to Forgejo, and publish the GitHub mirror.

Every GitHub CLI operation names `clipclapclop/workout_of_record` explicitly rather than inferring it from canonical `origin`. Set `githubMirrorEnabled` to `false` to publish only on Forgejo; in that mode the GitHub remote and CLI are not required.

## Recovery

The command is rerunnable:

- An existing tag must point to `HEAD`.
- Existing Forgejo and enabled GitHub assets are downloaded and compared before reuse.
- A differing same-name asset is never overwritten.
- A published Forgejo Release must already contain both matching assets; the tool will not silently repair an incomplete public release.
- Forgejo is published before the optional mirror. A later GitHub or documentation failure leaves the canonical release available and can be reconciled by rerunning the command.
- A matching already-published release is treated as complete.

## One-time Forgejo backfill

A historical release that was published on the GitHub mirror before Forgejo became the release authority can be backfilled without moving its immutable tag:

```bash
./tool/release --backfill-forgejo v1.0.5
```

The backfill requires clean `main`, an annotated tag that is an ancestor of `HEAD`, a public matching GitHub mirror, and the Forgejo release token. It pushes that exact annotated tag to canonical Forgejo, downloads the mirror APK and checksum, re-verifies checksum, package, version/build, arm64 architecture, and signing certificate, then creates and verifies the canonical Forgejo Release. It does not edit the tag or republish GitHub.

## Phone setup

Install Obtainium once, add `https://github.com/clipclapclop/workout_of_record`, and filter assets to `workout-of-record-android-arm64.apk`. This source remains valid while GitHub mirroring is enabled. Enable scheduled checks and permit installation from Obtainium. Back up the application before testing the first automated update, then verify the local database and settings remain intact.
