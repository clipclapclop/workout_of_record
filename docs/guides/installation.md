# Installation and updates

Workout of Record is distributed as a signed Android APK through canonical [Forgejo Releases](https://git.oorangy.com/chad/workout_of_record/releases). GitHub Releases remain an optional mirror for Obtainium while enabled. The app is not currently distributed through an app store.

## First installation

1. Back up any existing Workout of Record data before replacing a manually installed build.
2. Download `workout-of-record-android-arm64.apk` from the latest Forgejo Release.
3. Open the APK and allow installation from the app Android identifies as the source, if prompted.
4. Confirm the installation.

The package and signing key remain stable across releases, so installing a newer APK updates the existing app without intentionally clearing its local database. Android automatic cloud backup is disabled, so uninstalling the app or moving to another phone requires restoring a separately saved Workout of Record backup.

## Updates with Obtainium

1. Install [Obtainium](https://github.com/ImranR98/Obtainium).
2. Add `https://github.com/clipclapclop/workout_of_record` as an app source.
3. Set the APK filter to `workout-of-record-android-arm64.apk`.
4. Enable scheduled background checks.
5. Allow Obtainium to install unknown apps when Android requests that permission.

While the GitHub mirror is enabled, Obtainium detects its matching published release and downloads the same APK as Forgejo. Android still presents the final installation confirmation on a standard, non-managed phone. Open Obtainium to check immediately instead of waiting for its background schedule.

!!! warning "Keep backups"
    An update is designed to preserve application data, but keep a recent backup before the first automated update and before any release that announces a database migration.
