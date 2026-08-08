# Release 1.0.5 validation record

This page records the first real release after Forgejo became canonical while GitHub remained the APK, documentation, and Obtainium destination. It is intentionally incomplete until publication and phone verification finish.

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

## Remaining validation

- [ ] Merge the reviewed release preparation to canonical `main`.
- [ ] Run `./tool/release --dry-run` from clean `main` and record package identity, arm64 architecture, signing certificate, version/build number, checksum, tests, and strict documentation results.
- [ ] Publish only after explicit authorization.
- [ ] Verify `main`, annotated `v1.0.5`, and `gh-pages` revisions on Forgejo and GitHub.
- [ ] Verify the GitHub Release became public only after matching APK/checksum assets and documentation deployment completed.
- [ ] Update through Obtainium on the Pixel and confirm database, settings, active state, and signing continuity.
- [ ] Record any further defects or recovery steps here.
