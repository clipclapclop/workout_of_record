package com.clipclapclop.workoutofrecord

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.SoundPool
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Plays the two bundled get-ready tones on either Flutter engine. */
internal class WorkoutChimeChannel(
    context: Context,
    messenger: io.flutter.plugin.common.BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager = appContext.getSystemService(AudioManager::class.java)
    private val audioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()
    private val focusRequest = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            .setAudioAttributes(audioAttributes)
            .setOnAudioFocusChangeListener { }
            .build()
    } else {
        null
    }
    private val soundPool = SoundPool.Builder()
        .setMaxStreams(1)
        .setAudioAttributes(audioAttributes)
        .build()
    private val loadedSounds = mutableSetOf<Int>()
    private val failedSounds = mutableSetOf<Int>()
    private val releaseFocus = Runnable { abandonAudioFocus() }
    private var lowSoundId = 0
    private var highSoundId = 0
    private var disposed = false

    init {
        channel.setMethodCallHandler(this)
        soundPool.setOnLoadCompleteListener { _, soundId, status ->
            if (chimeForSound(soundId) == null) return@setOnLoadCompleteListener
            if (status == 0) {
                loadedSounds.add(soundId)
            } else {
                failedSounds.add(soundId)
            }
        }
        lowSoundId = soundPool.load(appContext, R.raw.get_ready_low, 1)
        highSoundId = soundPool.load(appContext, R.raw.get_ready_high, 1)
        if (lowSoundId == 0) failedSounds.add(lowSoundId)
        if (highSoundId == 0) failedSounds.add(highSoundId)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "play") {
            result.notImplemented()
            return
        }
        val chime = call.argument<String>("chime")
        if (chime != TEN_SECONDS && chime != FIVE_SECONDS) {
            result.error("invalid_chime", "Unknown get-ready chime", null)
            return
        }
        playIfReady(chime, result)
    }

    private fun playIfReady(chime: String, result: MethodChannel.Result) {
        if (disposed) {
            result.error("chime_channel_closed", "The get-ready chime channel is closed", null)
            return
        }
        val soundId = soundForChime(chime)
        when {
            loadedSounds.contains(soundId) -> playLoaded(chime, result)
            failedSounds.contains(soundId) -> result.error(
                "chime_load_failed",
                "The get-ready chime did not load",
                null,
            )
            else -> result.error(
                "chime_not_ready",
                "The get-ready chime is still loading",
                null,
            )
        }
    }

    private fun playLoaded(chime: String, result: MethodChannel.Result) {
        requestAudioFocus()
        val streamId = soundPool.play(soundForChime(chime), 1f, 1f, 1, 0, 1f)
        if (streamId == 0) {
            abandonAudioFocus()
            result.error("chime_play_failed", "The get-ready chime did not play", null)
            return
        }
        mainHandler.removeCallbacks(releaseFocus)
        mainHandler.postDelayed(releaseFocus, FOCUS_DURATION_MS)
        result.success(null)
    }

    private fun soundForChime(chime: String): Int =
        if (chime == TEN_SECONDS) lowSoundId else highSoundId

    private fun chimeForSound(soundId: Int): String? = when (soundId) {
        lowSoundId -> TEN_SECONDS
        highSoundId -> FIVE_SECONDS
        else -> null
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

    fun dispose() {
        disposed = true
        channel.setMethodCallHandler(null)
        mainHandler.removeCallbacks(releaseFocus)
        abandonAudioFocus()
        soundPool.release()
    }

    private companion object {
        const val CHANNEL_NAME = "com.clipclapclop.workoutofrecord/get_ready_chime"
        const val TEN_SECONDS = "tenSeconds"
        const val FIVE_SECONDS = "fiveSeconds"
        const val FOCUS_DURATION_MS = 500L
    }
}
