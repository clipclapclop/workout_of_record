package com.clipclapclop.workoutofrecord

import android.app.Application
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

/** Registers cue delivery on the foreground task's Flutter engine. */
class WorkoutApplication : Application(), FlutterForegroundTaskLifecycleListener {
    // These callbacks belong only to flutter_foreground_task's private engine;
    // the activity/UI engine does not invoke this listener. The plugin destroys
    // the current task engine before creating its replacement.
    private var foregroundTaskCueChannel: WorkoutCueChannel? = null
    private var foregroundTaskChimeChannel: WorkoutChimeChannel? = null

    override fun onCreate() {
        super.onCreate()
        FlutterForegroundTaskPlugin.addTaskLifecycleListener(this)
    }

    override fun onTerminate() {
        FlutterForegroundTaskPlugin.removeTaskLifecycleListener(this)
        foregroundTaskCueChannel?.dispose()
        foregroundTaskCueChannel = null
        foregroundTaskChimeChannel?.dispose()
        foregroundTaskChimeChannel = null
        super.onTerminate()
    }

    override fun onEngineCreate(flutterEngine: FlutterEngine?) {
        foregroundTaskCueChannel?.dispose()
        foregroundTaskCueChannel = flutterEngine?.let {
            WorkoutCueChannel(applicationContext, it.dartExecutor.binaryMessenger)
        }
        foregroundTaskChimeChannel?.dispose()
        foregroundTaskChimeChannel = flutterEngine?.let {
            WorkoutChimeChannel(applicationContext, it.dartExecutor.binaryMessenger)
        }
    }

    override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}

    override fun onTaskRepeatEvent() {}

    override fun onTaskDestroy() {}

    override fun onEngineWillDestroy() {
        foregroundTaskCueChannel?.dispose()
        foregroundTaskCueChannel = null
        foregroundTaskChimeChannel?.dispose()
        foregroundTaskChimeChannel = null
    }
}

private data class PendingSpeech(
    val text: String,
    val result: MethodChannel.Result,
)

private data class UtteranceResult(
    val result: MethodChannel.Result,
)

/** Plays speech and vibration without depending on the activity/UI engine. */
private class WorkoutCueChannel(
    context: Context,
    messenger: io.flutter.plugin.common.BinaryMessenger,
) : MethodChannel.MethodCallHandler, TextToSpeech.OnInitListener {
    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager = appContext.getSystemService(AudioManager::class.java)
    private val speechAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()
    private val focusRequest = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            .setAudioAttributes(speechAttributes)
            .setOnAudioFocusChangeListener { }
            .build()
    } else {
        null
    }

    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var ttsFailure: Pair<String, String>? = null
    private var pendingSpeech: PendingSpeech? = null
    private val utteranceResults = mutableMapOf<String, UtteranceResult>()
    private var disposed = false

    init {
        channel.setMethodCallHandler(this)
        // Initialize when the foreground task starts rather than waiting for the
        // timer to expire. GrapheneOS TTS engines can take a moment to bind.
        tts = TextToSpeech(appContext, this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "fire") {
            result.notImplemented()
            return
        }

        val haptic = call.argument<Boolean>("haptic") ?: false
        if (haptic) vibrate()

        val sound = call.argument<String>("sound") ?: "tts"
        val cueText = call.argument<String>("cueText")
        when (sound) {
            "silent" -> result.success(null)
            "tts" -> speakOrQueue(
                cueText?.takeIf { it.isNotBlank() } ?: "ready",
                result,
            )
            // TimerSound.chime has always meant spoken "ready"; the settings
            // screen explains that the app does not bundle an audio file.
            "chime" -> speakOrQueue("ready", result)
            else -> speakOrQueue("ready", result)
        }
    }

    override fun onInit(status: Int) {
        if (disposed) return
        if (status != TextToSpeech.SUCCESS) {
            markTtsFailure("tts_init_failed", "The text-to-speech engine did not initialize")
            return
        }
        val engine = tts
        if (engine == null) {
            markTtsFailure("tts_unavailable", "The text-to-speech engine is unavailable")
            return
        }
        val languageStatus = engine.setLanguage(Locale.US)
        if (languageStatus == TextToSpeech.LANG_MISSING_DATA ||
            languageStatus == TextToSpeech.LANG_NOT_SUPPORTED
        ) {
            markTtsFailure("tts_language_unavailable", "English speech data is unavailable")
            return
        }
        engine.setSpeechRate(1.0f)
        engine.setAudioAttributes(speechAttributes)
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {
                // Confirm native delivery to Dart, but retain transient audio
                // focus until speech completes.
                completeUtterance(utteranceId, null, releaseAudioFocus = false)
            }

            override fun onDone(utteranceId: String?) {
                completeUtterance(utteranceId, null, releaseAudioFocus = true)
            }

            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) {
                completeUtterance(utteranceId, "The text-to-speech engine rejected the cue")
            }

            override fun onError(utteranceId: String?, errorCode: Int) {
                completeUtterance(
                    utteranceId,
                    "The text-to-speech engine rejected the cue ($errorCode)",
                )
            }
        })
        ttsReady = true
        pendingSpeech?.let { pending ->
            pendingSpeech = null
            speak(pending.text, pending.result)
        }
    }

    private fun speakOrQueue(
        text: String,
        result: MethodChannel.Result,
    ) {
        val failure = ttsFailure
        if (disposed) {
            result.error("cue_channel_closed", "The foreground cue channel is closed", null)
        } else if (failure != null) {
            result.error(failure.first, failure.second, null)
        } else if (ttsReady) {
            speak(text, result)
        } else {
            pendingSpeech?.result?.error(
                "cue_superseded",
                "A newer workout cue replaced this cue",
                null,
            )
            pendingSpeech = PendingSpeech(text, result)
        }
    }

    private fun speak(
        text: String,
        methodResult: MethodChannel.Result,
    ) {
        requestAudioFocus()
        val utteranceId = "workout-cue-${UUID.randomUUID()}"
        utteranceResults[utteranceId] = UtteranceResult(methodResult)
        val speechResult =
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), utteranceId)
        if (speechResult != TextToSpeech.SUCCESS) {
            utteranceResults.remove(utteranceId)
            abandonAudioFocus()
            methodResult.error(
                "tts_speak_failed",
                "The text-to-speech engine did not accept the cue",
                null,
            )
        }
    }

    private fun completeUtterance(
        utteranceId: String?,
        error: String?,
        releaseAudioFocus: Boolean = true,
    ) {
        if (utteranceId == null) return
        mainHandler.post {
            val pending = utteranceResults.remove(utteranceId)
            if (pending != null) {
                if (error == null) {
                    pending.result.success(null)
                } else {
                    pending.result.error("tts_utterance_failed", error, null)
                }
            }
            if (releaseAudioFocus) abandonAudioFocus()
        }
    }

    private fun markTtsFailure(code: String, message: String) {
        ttsFailure = code to message
        failPendingSpeech(code, message)
    }

    private fun failPendingSpeech(code: String, message: String) {
        val result = pendingSpeech?.result
        pendingSpeech = null
        result?.error(code, message, null)
    }

    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.requestAudioFocus(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            )
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }

    private fun vibrate() {
        val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            appContext.getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            appContext.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createOneShot(
                    HAPTIC_DURATION_MS,
                    VibrationEffect.DEFAULT_AMPLITUDE,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(HAPTIC_DURATION_MS)
        }
    }

    fun dispose() {
        disposed = true
        failPendingSpeech("cue_channel_closed", "The foreground cue channel closed")
        for (pending in utteranceResults.values) {
            pending.result.error(
                "cue_channel_closed",
                "The foreground cue channel closed",
                null,
            )
        }
        utteranceResults.clear()
        channel.setMethodCallHandler(null)
        abandonAudioFocus()
        tts?.stop()
        tts?.shutdown()
        tts = null
        ttsReady = false
    }

    private companion object {
        const val CHANNEL_NAME = "com.clipclapclop.workoutofrecord/workout_cue"
        const val HAPTIC_DURATION_MS = 120L
    }
}
