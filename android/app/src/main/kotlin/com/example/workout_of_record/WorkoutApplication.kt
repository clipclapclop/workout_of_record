package com.clipclapclop.workoutofrecord

import android.app.Application
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
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
    private var cueChannel: WorkoutCueChannel? = null

    override fun onCreate() {
        super.onCreate()
        FlutterForegroundTaskPlugin.addTaskLifecycleListener(this)
    }

    override fun onTerminate() {
        FlutterForegroundTaskPlugin.removeTaskLifecycleListener(this)
        cueChannel?.dispose()
        cueChannel = null
        super.onTerminate()
    }

    override fun onEngineCreate(flutterEngine: FlutterEngine?) {
        cueChannel?.dispose()
        cueChannel = flutterEngine?.let {
            WorkoutCueChannel(applicationContext, it.dartExecutor.binaryMessenger)
        }
    }

    override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}

    override fun onTaskRepeatEvent() {}

    override fun onTaskDestroy() {}

    override fun onEngineWillDestroy() {
        cueChannel?.dispose()
        cueChannel = null
    }
}

/** Plays speech and vibration without depending on the activity/UI engine. */
private class WorkoutCueChannel(
    context: Context,
    messenger: io.flutter.plugin.common.BinaryMessenger,
) : MethodChannel.MethodCallHandler, TextToSpeech.OnInitListener {
    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
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
    private var pendingSpeech: String? = null
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
            "silent" -> Unit
            "tts" -> speakOrQueue(cueText?.takeIf { it.isNotBlank() } ?: "ready")
            // TimerSound.chime has always meant spoken "ready"; the settings
            // screen explains that the app does not bundle an audio file.
            "chime" -> speakOrQueue("ready")
            else -> speakOrQueue("ready")
        }

        result.success(null)
    }

    override fun onInit(status: Int) {
        if (disposed || status != TextToSpeech.SUCCESS) return
        val engine = tts ?: return
        engine.language = Locale.US
        engine.setSpeechRate(1.0f)
        engine.setAudioAttributes(speechAttributes)
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}

            override fun onDone(utteranceId: String?) {
                abandonAudioFocus()
            }

            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) {
                abandonAudioFocus()
            }

            override fun onError(utteranceId: String?, errorCode: Int) {
                abandonAudioFocus()
            }
        })
        ttsReady = true
        pendingSpeech?.let {
            pendingSpeech = null
            speak(it)
        }
    }

    private fun speakOrQueue(text: String) {
        if (ttsReady) {
            speak(text)
        } else {
            // Keep only the latest one-shot cue while the engine binds.
            pendingSpeech = text
        }
    }

    private fun speak(text: String) {
        requestAudioFocus()
        val utteranceId = "workout-cue-${UUID.randomUUID()}"
        val result = tts?.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), utteranceId)
        if (result != TextToSpeech.SUCCESS) abandonAudioFocus()
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
        pendingSpeech = null
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
