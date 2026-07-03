# Installation and updates

Workout of Record is distributed as a signed Android APK through [GitHub Releases](https://github.com/clipclapclop/workout_of_record/releases). It is not currently distributed through an app store.

## First installation

1. Back up any existing Workout of Record data before replacing a manually installed build.
2. Download `workout-of-record-android-arm64.apk` from the latest GitHub Release.
3. Open the APK and allow installation from the app Android identifies as the source, if prompted.
4. Confirm the installation.

The package and signing key remain stable across releases, so installing a newer APK updates the existing app without intentionally clearing its local database.

## Updates with Obtainium

1. Install [Obtainium](https://github.com/ImranR98/Obtainium).
2. Add `https://github.com/clipclapclop/workout_of_record` as an app source.
3. Set the APK filter to `workout-of-record-android-arm64.apk`.
4. Enable scheduled background checks.
5. Allow Obtainium to install unknown apps when Android requests that permission.

Obtainium detects a published release and downloads its APK. Android still presents the final installation confirmation on a standard, non-managed phone. Open Obtainium to check immediately instead of waiting for its background schedule.

!!! warning "Keep backups"
    An update is designed to preserve application data, but keep a recent backup before the first automated update and before any release that announces a database migration.
