package com.clipclapclop.workoutofrecord

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var safChannel: SafChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        safChannel = SafChannel(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SafChannel.CHANNEL)
            .setMethodCallHandler(safChannel::handleMethodCall)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        safChannel.onActivityResult(requestCode, resultCode, data)
    }
}
