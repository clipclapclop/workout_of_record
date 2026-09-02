# Settings, backups, and recovery

## Timer and AI settings

Workout weights are recorded in pounds and distances in miles. Settings cover rest-timer behavior, optional AI configuration, and backup/restore controls. Rest-timer settings include an optional get-ready sequence: a lower built-in tone at 10 seconds remaining followed by a higher tone at 5 seconds. The sequence does not change the visible countdown, does not require text-to-speech, and is suppressed when the alert sound is set to Silent. Core workout logging remains available when AI is disabled or unavailable.

API credentials entered for optional AI features are device settings and must never be placed in release manifests, documentation, or the repository.

## Backups

Open **Settings → Backup & Restore** to choose an Android document-tree location, enable backups, and control whether a backup runs after workout completion. The selected location can be a directory synchronized or exposed by another storage application.

The backup screen reports the last successful backup and any current error. If Android revokes access to the selected folder, choose the location again.

A successful backup is always named `workout_of_record.zip`, allowing another storage application to copy that exact file and manage its own version history. Before replacing it, the app writes and verifies a temporary document, preserves the prior file during the rename, and verifies the final exact-name document. Temporary pending or previous documents are removed after success. If replacement is interrupted, the next backup attempt restores the preserved prior file before trying again. The app reports failure rather than falling back to truncating the existing backup when the selected Android storage provider cannot perform the safe rename.

### Supported backup format

A supported backup is a ZIP containing exactly these two files at its root:

- `workout_of_record.sqlite`, containing workout history and plans; and
- `settings.json`, containing the active mesocycle and workout pointers, profile values, timer behavior, non-secret AI configuration, profile-prompt state, and notes.

The ZIP may be at most 256 MiB, and `settings.json` may be at most 1 MiB. `settings.json` is a UTF-8 JSON object with these supported fields:

- `currentMesocycleId` and `currentCompletedWorkoutId`: positive integers or `null`;
- `dateOfBirth`: an ISO-8601 string or `null`;
- `weight`: a finite non-negative number of pounds or `null`;
- `trainingGoal`: `strength`, `hypertrophy`, `endurance`, `general`, or `null`;
- `calorieState`: `surplus`, `maintenance`, `deficit`, or `null`;
- `trainingStartDate`: an ISO-8601 string or `null`;
- `timerEnabled`, `timerHaptic`, `timerKeepAwake`, and `timerGetReadyChimes`: booleans;
- `timerDefaultSeconds`: a positive integer;
- `timerSound`: `tts`, `chime`, or `silent`;
- `aiEnabled` and `hasSeenProfilePrompt`: booleans;
- `aiModel`, `aiRecommendationPrompt`, `aiChatPrompt`, `aiUserNotes`, and `notes`: strings;
- `aiCreditId`: a string or `null`; and
- `aiHistoryWeeks`: an integer from 1 through 12.

Fields may be omitted for compatibility with earlier released backups, in which case the app default is restored. The retired `unitsMetric` field is accepted from older backups when it contains a boolean, but its value is ignored. That preference changed labels only and never converted or tagged stored values. The app's sole existing data set was confirmed to contain pounds and miles, so numeric values are deliberately left unchanged; converting them during restore would corrupt those records. Unknown fields are rejected. The API key, backup and AI-log folder permissions, AI logging state, and backup status/error bookkeeping are not included. Those credentials and device-specific locations remain unchanged on the current device and must be configured again after restoring to another installation.

The database schema must be within the restore range supported by the installed app. The current app supports schemas 8 through 13 and migrates older supported backups on a staged copy before restore. A database at schema 7 or older, or a backup from a newer unsupported schema, is rejected rather than being opened unsafely.

## Restore

Use restore from the backup screen and select the intended archive. Restoring replaces application data, so verify the selected file before confirming.

Before replacing anything, the app verifies the ZIP and its checksums, settings value types and enum names, SQLite integrity and relationships, schema compatibility, and active pointers. An active-workout pointer must identify an unfinished workout in the selected active mesocycle. Missing, duplicate, malformed, corrupt, incompatible, or mismatched content is rejected with an error and does not change current data.

After validation, the app checkpoints and closes the current database, preserves a recovery copy, removes old SQLite WAL/SHM files, and installs the staged database. A durable recovery record keeps the database and settings together: if replacement fails, the app restores both immediately, and if the app stops between those steps, it rolls both back before opening the database on the next launch. A successful restore still requires the app to restart.

!!! note "Screenshot pending — backup-settings"
    Capture Backup & Restore after a folder is selected, with automatic backup enabled and the last-backup status visible.
