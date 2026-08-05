# Development

## Project check

Run the repository-owned aggregate check before proposing a change:

```sh
./scripts/check
```

The check resolves only versions allowed by `pubspec.lock`, treats all analyzer information as fatal, runs the complete Flutter test suite, and runs the release-workflow unit tests. It was established with Flutter 3.44.0 and Dart 3.12.0. Upgrade the toolchain and resulting compatibility files deliberately rather than allowing an unrelated change to rewrite them.

Dependency resolution runs offline so the same command works in Repflow's network-isolated exact-revision sandbox. Populate the trusted host's Pub cache deliberately with `flutter pub get --enforce-lockfile` before running the check when required; do not give the sandbox network access or credentials as a shortcut.

## Stale Flutter artifacts

After changing Flutter SDK versions, local generated artifacts can become incompatible with the new engine. If tests report generated-cache or shader-format failures, recreate ignored artifacts and rerun the check:

```sh
flutter clean
flutter pub get --enforce-lockfile
./scripts/check
```

If locked dependency resolution is no longer valid for the chosen SDK, handle the SDK and lockfile update as an explicit toolchain change.
