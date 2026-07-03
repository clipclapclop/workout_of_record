# Settings, backups, and recovery

## General, timer, and AI settings

Settings are divided into general display and unit preferences, rest-timer behavior, optional AI configuration, and backup/restore controls. Core workout logging remains available when AI is disabled or unavailable.

API credentials entered for optional AI features are device settings and must never be placed in release manifests, documentation, or the repository.

## Backups

Open **Settings → Backup & Restore** to choose an Android document-tree location, enable backups, and control whether a backup runs after workout completion. The selected location can be a directory synchronized or exposed by another storage application.

The backup screen reports the last successful backup and any current error. If Android revokes access to the selected folder, choose the location again.

## Restore

Use restore from the backup screen and select the intended archive. Restoring replaces application data, so make a current backup first and verify the selected file before confirming.

!!! note "Screenshot pending — backup-settings"
    Capture Backup & Restore after a folder is selected, with automatic backup enabled and the last-backup status visible.
