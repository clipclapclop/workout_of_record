package com.clipclapclop.workoutofrecord

import java.security.MessageDigest

internal data class BackupDocumentDigest(
    val byteCount: Long,
    val sha256: String,
) {
    companion object {
        fun fromBytes(bytes: ByteArray): BackupDocumentDigest = BackupDocumentDigest(
            byteCount = bytes.size.toLong(),
            sha256 = MessageDigest.getInstance("SHA-256")
                .digest(bytes)
                .joinToString("") { "%02x".format(it) },
        )
    }
}

internal interface BackupDocumentStore {
    fun exists(name: String): Boolean
    fun write(name: String, bytes: ByteArray)
    fun digest(name: String): BackupDocumentDigest
    fun rename(from: String, to: String): Boolean
    fun delete(name: String): Boolean
}

internal class BackupReplacementException(
    message: String,
    cause: Throwable? = null,
) : Exception(message, cause)

/** Safely replaces the one fixed-name backup without requiring local rotation. */
internal class FixedNameBackupWriter(
    private val store: BackupDocumentStore,
) {
    companion object {
        const val FINAL_NAME = "workout_of_record.zip"
        const val PENDING_NAME = "workout_of_record.pending.zip"
        const val PREVIOUS_NAME = "workout_of_record.previous.zip"
    }

    fun replace(bytes: ByteArray) {
        recoverInterruptedReplacement()
        deleteRequired(PENDING_NAME)

        val expected = BackupDocumentDigest.fromBytes(bytes)
        try {
            store.write(PENDING_NAME, bytes)
            requireDigest(PENDING_NAME, expected)
        } catch (error: Exception) {
            deleteBestEffort(PENDING_NAME)
            throw BackupReplacementException(
                "Could not stage and verify the new backup. The existing backup was not changed.",
                error,
            )
        }

        val replacingExisting = store.exists(FINAL_NAME)
        try {
            if (replacingExisting) {
                deleteRequired(PREVIOUS_NAME)
                renameRequired(FINAL_NAME, PREVIOUS_NAME)
            }
            renameRequired(PENDING_NAME, FINAL_NAME)
            requireDigest(FINAL_NAME, expected)
            deleteRequired(PREVIOUS_NAME)
        } catch (error: Exception) {
            val rollbackError = rollbackPrevious()
            if (rollbackError != null) {
                throw BackupReplacementException(
                    "Backup replacement failed and the previous backup could not be restored. " +
                        "Keep $PREVIOUS_NAME; the app will retry recovery next time.",
                    rollbackError,
                )
            }
            if (!replacingExisting) deleteBestEffort(FINAL_NAME)
            deleteBestEffort(PENDING_NAME)
            throw BackupReplacementException(
                if (replacingExisting) {
                    "Backup replacement failed. The previous backup was restored."
                } else {
                    "Backup replacement failed before the first backup could be installed."
                },
                error,
            )
        }
    }

    /** Restores the previous fixed-name file after a process interruption. */
    fun recoverInterruptedReplacement() {
        if (store.exists(PREVIOUS_NAME)) {
            val rollbackError = rollbackPrevious()
            if (rollbackError != null) {
                throw BackupReplacementException(
                    "An interrupted backup could not be recovered. Keep $PREVIOUS_NAME and try again.",
                    rollbackError,
                )
            }
        }

        if (store.exists(PENDING_NAME)) {
            deleteRequired(PENDING_NAME)
        }
    }

    private fun rollbackPrevious(): Exception? {
        if (!store.exists(PREVIOUS_NAME)) return null
        return try {
            if (store.exists(FINAL_NAME) && !store.delete(FINAL_NAME)) {
                throw BackupReplacementException("Could not remove the incomplete final backup.")
            }
            renameRequired(PREVIOUS_NAME, FINAL_NAME)
            null
        } catch (error: Exception) {
            error
        }
    }

    private fun requireDigest(name: String, expected: BackupDocumentDigest) {
        val actual = store.digest(name)
        if (actual != expected) {
            throw BackupReplacementException("Backup verification failed for $name.")
        }
    }

    private fun renameRequired(from: String, to: String) {
        if (!store.rename(from, to)) {
            throw BackupReplacementException("The selected folder could not rename $from safely.")
        }
    }

    private fun deleteRequired(name: String) {
        if (store.exists(name) && !store.delete(name)) {
            throw BackupReplacementException("The selected folder could not remove stale $name.")
        }
    }

    private fun deleteBestEffort(name: String) {
        try {
            if (store.exists(name)) store.delete(name)
        } catch (_: Exception) {
            // A stale pending file is safe to reconcile on the next attempt.
        }
    }
}
