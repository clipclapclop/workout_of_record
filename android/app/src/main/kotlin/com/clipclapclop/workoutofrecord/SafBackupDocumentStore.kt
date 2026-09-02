package com.clipclapclop.workoutofrecord

import android.content.Context
import androidx.documentfile.provider.DocumentFile
import java.security.MessageDigest

internal class SafBackupDocumentStore(
    private val context: Context,
    private val tree: DocumentFile,
) : BackupDocumentStore {
    override fun exists(name: String): Boolean = tree.findFile(name)?.exists() == true

    override fun write(name: String, bytes: ByteArray) {
        if (exists(name)) throw Exception("Temporary backup file already exists: $name")
        val document = tree.createFile("application/zip", name)
            ?: throw Exception("Cannot create temporary backup file")
        if (document.name != name) {
            document.delete()
            throw Exception("The selected folder changed the temporary backup filename")
        }
        val stream = context.contentResolver.openOutputStream(document.uri, "w")
            ?: throw Exception("Cannot open temporary backup file")
        stream.use {
            it.write(bytes)
            it.flush()
        }
    }

    override fun digest(name: String): BackupDocumentDigest {
        val document = tree.findFile(name) ?: throw Exception("Backup file is missing: $name")
        val stream = context.contentResolver.openInputStream(document.uri)
            ?: throw Exception("Cannot read backup file: $name")
        val digest = MessageDigest.getInstance("SHA-256")
        var byteCount = 0L
        stream.use {
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            while (true) {
                val count = it.read(buffer)
                if (count < 0) break
                if (count == 0) continue
                digest.update(buffer, 0, count)
                byteCount += count
            }
        }
        return BackupDocumentDigest(
            byteCount = byteCount,
            sha256 = digest.digest().joinToString("") { "%02x".format(it) },
        )
    }

    override fun rename(from: String, to: String): Boolean {
        if (exists(to)) return false
        val source = tree.findFile(from) ?: return false
        if (!source.renameTo(to)) return false
        return !exists(from) && exists(to)
    }

    override fun delete(name: String): Boolean {
        val document = tree.findFile(name) ?: return true
        return document.delete() && !exists(name)
    }
}
