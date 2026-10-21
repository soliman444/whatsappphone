package com.example.whatsapp

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return RaselApplication.get(this).ensureEngine()
    }

    private val audioChannelName = "com.example.whatsapp/audio"

    private var audioChannel: MethodChannel? = null
    private var mediaPlayer: MediaPlayer? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var preparedResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannelName)
        audioChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.success(false)
                    } else {
                        playAudio(path, result)
                    }
                }
                "stop" -> {
                    stopAudio()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playAudio(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists() || file.length() < 32) {
            result.success(false)
            return
        }
        stopAudio()
        preparedResult = result
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try {
            am.mode = AudioManager.MODE_NORMAL
            am.isSpeakerphoneOn = true
        } catch (_: Exception) {
        }
        requestMusicFocus(am)
        val mp = MediaPlayer()
        mediaPlayer = mp
        mp.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .setLegacyStreamType(AudioManager.STREAM_MUSIC)
                .build(),
        )
        mp.setVolume(1f, 1f)
        mp.setOnPreparedListener { player ->
            player.setVolume(1f, 1f)
            player.start()
            preparedResult?.success(true)
            preparedResult = null
        }
        mp.setOnCompletionListener {
            audioChannel?.invokeMethod("complete", null)
            stopAudio()
        }
        mp.setOnErrorListener { _, _, _ ->
            preparedResult?.success(false)
            preparedResult = null
            stopAudio()
            true
        }
        try {
            mp.setDataSource(path)
            mp.prepareAsync()
        } catch (_: Exception) {
            preparedResult?.success(false)
            preparedResult = null
            stopAudio()
        }
    }

    private fun requestMusicFocus(am: AudioManager) {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener { }
                .build()
            audioFocusRequest = request
            am.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            am.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
        }
    }

    private fun stopAudio() {
        try {
            mediaPlayer?.setOnCompletionListener(null)
            mediaPlayer?.setOnErrorListener(null)
            mediaPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
        }
        mediaPlayer = null
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            } else {
                @Suppress("DEPRECATION")
                am.abandonAudioFocus(null)
            }
        } catch (_: Exception) {
        }
        audioFocusRequest = null
        try {
            am.mode = AudioManager.MODE_NORMAL
            am.isSpeakerphoneOn = false
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        stopAudio()
        super.onDestroy()
    }
}
