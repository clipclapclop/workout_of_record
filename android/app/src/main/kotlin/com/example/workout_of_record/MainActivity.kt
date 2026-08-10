package com.clipclapclop.workoutofrecord

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var safChannel: SafChannel
    private var workoutChimeChannel: WorkoutChimeChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        safChannel = SafChannel(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SafChannel.CHANNEL)
            .setMethodCallHandler(safChannel::handleMethodCall)
        workoutChimeChannel = WorkoutChimeChannel(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        workoutChimeChannel?.dispose()
        workoutChimeChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        safChannel.onActivityResult(requestCode, resultCode, data)
    }
}
