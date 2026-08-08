# Release 1.0.5 validation record

This page records the first real release after Forgejo became canonical. Forgejo is also the release authority; GitHub remains an optional APK, documentation, and Obtainium mirror. It is intentionally incomplete until the Forgejo backfill and phone verification finish.

## Preparation

- Version: `1.0.5`
- Base Android build number: `6`
- Expected arm64 APK build number: `2006`
- Previous release tag: `v1.0.4`
- Included fragments: backup-restore hardening, active-workout recovery coverage, and database migration fixtures for schemas 8 through 13
- Local aggregate check: passed during release preparation

## Defect found

The release commit audit found nine backup-restore follow-up commits that did not each modify the implementation's existing change fragment or contain `Release-Impact: none`. The fragment had been created in the originating backup-restore commit, so release intent and documentation were present, but the per-commit audit correctly blocked the release.

Rewriting shared `main` history was rejected because it would replace already-published commit identities. The recovery was to add a narrow `commitAuditExceptions` mechanism and list the nine full immutable SHAs in `release/manifests/1.0.5.json`, each linked to the archived backup-restore fragment with a reason.

The first published PR review correctly found that merely requiring any fragment listed by the release manifest did not prove that an exception belonged to that implementation. The exception now also names the full originating commit. The tool verifies that the origin precedes the follow-up, recorded the linked fragment ID, and changed at least one of the same monitored application paths. It continues to reject every unlisted commit and rejects broad, stale, duplicate, unrelated, or unnecessary exceptions.

Future follow-up commits that touch application code must update their task's fragment in that commit or use the exact `Release-Impact: none` trailer when there is genuinely no release impact.

The strict documentation build also exposed a stale ignored `.venv-docs` whose Python launcher still referenced the repository's former filesystem location. Deleting and recreating the environment recovered the build. The release tool now probes that interpreter and automatically rebuilds an unusable documentation environment before installing the pinned requirements.

## Publication evidence

- Release preparation merged to canonical `main` at `18fec46d08513858b6c7763e5b883b43a644dd0f`.
- `./tool/release --dry-run` passed analyzer, 84 Flutter tests, strict MkDocs, package `com.clipclapclop.workoutofrecord`, version `1.0.5`, arm64 build code `2006`, ABI `arm64-v8a`, and signing certificate `c6ea597a06ae86049cb28bfdaac8048ccfd592821fc71bb4ee5b4b63dd0b57cb`.
- The verified APK checksum is `0a63f660c3fe29226d3e3c2316067e61e336109efed5d522ad3f4fed8890fac1`.
- The first build attempt exposed Flutter selecting Android Studio JBR 25.0.2. Configuring `/usr/lib/jvm/java-17-openjdk` with `flutter config --jdk-dir` recovered the build.
- Publication occurred only after explicit authorization. Forgejo and GitHub `main` both resolved to `18fec46d08513858b6c7763e5b883b43a644dd0f`; annotated tag object `352f78ecfb4062eaf0435d112c9f97206d538788` dereferenced to that revision on both; and both `gh-pages` branches resolved to `313894649c89918b74d62e4e40d4a8c0017d56ca`.
- The downloaded GitHub APK and checksum matched the locally verified files, the release was public and non-draft, and GitHub Pages reported built with HTTP 200.

## Authority correction

The initial workflow published the release object only on GitHub even though Forgejo was canonical. The owner overrode that distribution design: Forgejo must own the canonical release, with GitHub retained only as an optional mirror. Issue #21 adds Forgejo-first publication and a one-time, fully re-verified v1.0.5 backfill. The existing GitHub Release remains available as the requested mirror.

The first review of the backfill correctly found that it verified a local annotated tag without explicitly transferring that immutable tag to Forgejo. A follow-up review then caught two recovery hazards: backfill was incorrectly coupled to the current mirror-enabled flag, and it pushed the tag before validating the historical mirror assets. The backfill now works independently of the future mirror setting and pushes the exact tag only after GitHub authentication, asset download, checksum verification, and APK identity/signing checks pass. A conflicting remote tag fails rather than being replaced.

## Remaining validation

- [ ] Backfill and verify the canonical Forgejo v1.0.5 Release with the matching APK and checksum.
- [ ] Update through Obtainium on the Pixel and confirm database, settings, active state, and signing continuity.
- [ ] Record any further defects or recovery steps in the governing Forgejo issue.
