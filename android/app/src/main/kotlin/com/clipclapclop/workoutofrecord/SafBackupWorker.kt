package com.clipclapclop.workoutofrecord

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.text.SimpleDateFormat
import java.util.*
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

class SafBackupWorker(ctx: Context, params: WorkerParameters) : Worker(ctx, params) {

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_BACKUP_URI = "flutter.backup_directory_path"
        private const val KEY_LAST_BACKUP = "flutter.backup_last_timestamp"
        private const val DB_FILENAME = "workout_of_record.sqlite"
        private const val SETTINGS_FILENAME = "settings.json"
    }

    override fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val uriString = prefs.getString(KEY_BACKUP_URI, null) ?: return Result.success()
        return try {
            val zipBytes = buildZip(prefs)
            writeToSaf(uriString, zipBytes)
            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
            prefs.edit().putString(KEY_LAST_BACKUP, sdf.format(Date())).apply()
            Result.success()
        } catch (_: Exception) {
            Result.failure()
        }
    }

    private fun buildZip(prefs: SharedPreferences): ByteArray {
        // Flutter's getApplicationDocumentsDirectory() maps to <dataDir>/app_flutter/
        val dbFile = java.io.File(applicationContext.filesDir.parentFile, "app_flutter/$DB_FILENAME")
        if (!dbFile.exists()) throw Exception("Database not found")
        val dbBytes = dbFile.readBytes()
        val settingsBytes = buildSettingsJson(prefs).toByteArray(Charsets.UTF_8)
        val out = ByteArrayOutputStream()
        ZipOutputStream(out).use { zip ->
            zip.putNextEntry(ZipEntry(DB_FILENAME))
            zip.write(dbBytes)
            zip.closeEntry()
            zip.putNextEntry(ZipEntry(SETTINGS_FILENAME))
            zip.write(settingsBytes)
            zip.closeEntry()
        }
        return out.toByteArray()
    }

    private fun buildSettingsJson(prefs: SharedPreferences): String {
        val json = JSONObject()
        if (prefs.contains("flutter.current_mesocycle_id")) {
            json.put("currentMesocycleId", prefs.getLong("flutter.current_mesocycle_id", 0))
        }
        if (prefs.contains("flutter.current_completed_workout_id")) {
            json.put("currentCompletedWorkoutId", prefs.getLong("flutter.current_completed_workout_id", 0))
        }
        prefs.getString("flutter.profile_date_of_birth", null)?.let { json.put("dateOfBirth", it) }
        if (prefs.contains("flutter.profile_weight_kg")) {
            json.put("weight", prefs.getFloat("flutter.profile_weight_kg", 0f).toDouble())
        }
        prefs.getString("flutter.profile_training_goal", null)?.let { json.put("trainingGoal", it) }
        prefs.getString("flutter.profile_calorie_state", null)?.let { json.put("calorieState", it) }
        if (prefs.contains("flutter.settings_ai_enabled")) {
            json.put("aiEnabled", prefs.getBoolean("flutter.settings_ai_enabled", false))
        }
        if (prefs.contains("flutter.settings_units_metric")) {
            json.put("unitsMetric", prefs.getBoolean("flutter.settings_units_metric", false))
        }
        if (prefs.contains("flutter.has_seen_profile_prompt")) {
            json.put("hasSeenProfilePrompt", prefs.getBoolean("flutter.has_seen_profile_prompt", false))
        }
        return json.toString()
    }

    private fun writeToSaf(uriString: String, bytes: ByteArray) {
        val treeUri = Uri.parse(uriString)
        val tree = DocumentFile.fromTreeUri(applicationContext, treeUri)
            ?: throw Exception("Cannot access backup folder")
        FixedNameBackupWriter(
            SafBackupDocumentStore(applicationContext, tree),
        ).replace(bytes)
    }
}
