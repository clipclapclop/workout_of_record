# Repository workflow

## Validation

- Run `flutter analyze --fatal-infos` and `flutter test` after changing Dart code.
- Do not publish a release to test release tooling. Use `./tool/release --dry-run`.
- Preserve `android/key.properties` and the release keystore as local, ignored files.

## Durable change fragments

Conversations are not release history. Every substantive application-code change must create or update one JSON fragment under `.changes/unreleased/` during the same implementation task. Use a unique `YYYYMMDD-short-description.json` filename and this shape:

```json
{
  "id": "short-description",
  "summary": "What changed and why.",
  "audience": "user",
  "releaseNote": "Concise text suitable for release notes.",
  "docs": {
    "impact": "updated",
    "paths": ["docs/guides/relevant-page.md"],
    "reason": ""
  },
  "screenshots": []
}
```

- `audience` is `user`, `maintainer`, or `internal`.
- `docs.impact` is `updated`, `deferred`, or `none` while unreleased.
- Update user documentation in the implementation task when practical. Use `deferred` with a concrete reason when release preparation must finish it. Use `none` with a concrete reason for changes that do not affect documentation.
- Screenshot IDs must also appear in `docs/screenshot-backlog.md`.
- Delete a fragment if its implementation is abandoned.
- If an application-code commit truly has no release impact, it may instead end with the exact commit trailer `Release-Impact: none`.

## Preparing a release

When the user says **prepare a release**:

1. Read every `.changes/unreleased/*.json` file and compare the complete diff from the latest `vMAJOR.MINOR.PATCH` tag to `HEAD`.
2. Resolve all deferred documentation decisions and update relevant guide pages.
3. Choose the requested semantic version, or increment the patch version by default, and increment the Android build number monotonically in `pubspec.yaml`.
4. Write `docs/releases/<version>.md` and `release/manifests/<version>.json`.
5. Move included fragments to `release/fragments/<version>/`; archived fragments may contain only `updated` or `none` documentation impacts.
6. Update `docs/releases/index.md` and the screenshot backlog.
7. Show the complete release-preparation diff and run local validation. Do not publish merely because preparation was requested.

## Publishing a release

When the user says **publish the prepared release**, that explicitly authorizes the canonical Forgejo Release, Forgejo pushes and asset uploads, and any GitHub mirror and documentation deployment enabled in `tool/release-config.json`. Ensure the working tree is committed and clean, then run `./tool/release`.

When the user says **prepare and publish a release**, perform both workflows. Do not infer publication authority from an ordinary implementation request.

The release command is deterministic and never edits, stages, or commits tracked files. See `docs/maintainer/releasing.md` for setup, recovery, and phone instructions.
