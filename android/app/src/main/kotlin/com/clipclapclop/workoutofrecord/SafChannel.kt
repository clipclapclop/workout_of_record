package com.clipclapclop.workoutofrecord

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.concurrent.TimeUnit

class SafChannel(private val activity: MainActivity) {

    companion object {
        const val CHANNEL = "workout_of_record/saf"
        private const val REQUEST_PICK_FOLDER = 1001
        private const val WORK_NAME = "saf_backup"
    }

    private var pendingResult: MethodChannel.Result? = null

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "checkFolder" -> {
                val uri = call.argument<String>("uri")!!
                checkFolder(uri, result)
            }
            "writeFile" -> {
                val uri = call.argument<String>("uri")!!
                val bytes = call.argument<ByteArray>("bytes")!!
                writeFile(uri, bytes, result)
            }
            "scheduleBackup" -> {
                val hour = call.argument<Int>("hour")!!
                val minute = call.argument<Int>("minute")!!
                scheduleBackup(hour, minute, result)
            }
            "appendToFile" -> {
                val uri = call.argument<String>("uri")!!
                val fileName = call.argument<String>("fileName")!!
                val bytes = call.argument<ByteArray>("bytes")!!
                appendToFile(uri, fileName, bytes, result)
            }
            "cancelBackup" -> cancelBackup(result)
            else -> result.notImplemented()
        }
    }

    private fun checkFolder(uriString: String, result: MethodChannel.Result) {
        try {
            val treeUri = Uri.parse(uriString)
            // Verify we still hold a persistable permission for this URI.
            val hasPermission = activity.contentResolver.persistedUriPermissions.any {
                it.uri == treeUri && it.isWritePermission
            }
            if (!hasPermission) {
                result.success(false)
                return
            }
            // Verify the folder itself is still accessible.
            val tree = DocumentFile.fromTreeUri(activity, treeUri)
            result.success(tree != null && tree.exists() && tree.canWrite())
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
        }
        @Suppress("DEPRECATION")
        activity.startActivityForResult(intent, REQUEST_PICK_FOLDER)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_PICK_FOLDER) return
        val result = pendingResult ?: return
        pendingResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }
        val uri = data.data!!
        activity.contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        )
        result.success(uri.toString())
    }

    private fun writeFile(uriString: String, bytes: ByteArray, result: MethodChannel.Result) {
        try {
            val treeUri = Uri.parse(uriString)
            val tree = DocumentFile.fromTreeUri(activity, treeUri)
                ?: throw Exception("Cannot access folder")
            FixedNameBackupWriter(
                SafBackupDocumentStore(activity, tree),
            ).replace(bytes)
            result.success(null)
        } catch (e: Exception) {
            result.error("WRITE_FAILED", e.message, null)
        }
    }

    private fun appendToFile(
        uriString: String,
        fileName: String,
        bytes: ByteArray,
        result: MethodChannel.Result
    ) {
        try {
            val treeUri = Uri.parse(uriString)
            val tree = DocumentFile.fromTreeUri(activity, treeUri)
                ?: throw Exception("Cannot access folder")
            val existing = tree.findFile(fileName)
            val target = existing ?: tree.createFile("text/markdown", fileName)
                ?: throw Exception("Cannot create file in folder")
            // "wa" = write-append mode
            activity.contentResolver.openOutputStream(target.uri, "wa")!!.use {
                it.write(bytes)
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("APPEND_FAILED", e.message, null)
        }
    }

    private fun scheduleBackup(hour: Int, minute: Int, result: MethodChannel.Result) {
        try {
            val now = Calendar.getInstance()
            val next = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            if (!next.after(now)) next.add(Calendar.DAY_OF_MONTH, 1)
            val initialDelayMs = next.timeInMillis - now.timeInMillis
            val request = PeriodicWorkRequestBuilder<SafBackupWorker>(24, TimeUnit.HOURS)
                .setInitialDelay(initialDelayMs, TimeUnit.MILLISECONDS)
                .build()
            @Suppress("DEPRECATION")
            WorkManager.getInstance(activity)
                .enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.REPLACE, request)
            result.success(null)
        } catch (e: Exception) {
            result.error("SCHEDULE_FAILED", e.message, null)
        }
    }

    private fun cancelBackup(result: MethodChannel.Result) {
        WorkManager.getInstance(activity).cancelUniqueWork(WORK_NAME)
        result.success(null)
    }
}
