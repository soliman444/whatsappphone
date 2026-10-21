package com.example.whatsapp

import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class RaselApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    @Synchronized
    fun ensureEngine(): FlutterEngine {
        FlutterEngineCache.getInstance().get(ENGINE_ID)?.let { cached ->
            bindKeepAlive(cached)
            startDartIfNeeded(cached)
            return cached
        }
        val engine = FlutterEngine(this)
        bindKeepAlive(engine)
        startDartIfNeeded(engine)
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        return engine
    }

    private fun startDartIfNeeded(engine: FlutterEngine) {
        if (engine.dartExecutor.isExecutingDart) return
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
    }

    private fun bindKeepAlive(engine: FlutterEngine) {
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, KEEP_ALIVE_CHANNEL)
        FlutterBridge.keepAliveChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    setLiveSyncEnabled(this, true)
                    startSyncService(this)
                    result.success(true)
                }
                "stop" -> {
                    setLiveSyncEnabled(this, false)
                    stopService(Intent(this, SyncForegroundService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        const val ENGINE_ID = "rasel_engine"
        const val KEEP_ALIVE_CHANNEL = "com.example.whatsapp/keepalive"
        private const val PREFS = "rasel"
        private const val KEY_LIVE = "live_sync"

        @Volatile
        private var instance: RaselApplication? = null

        fun get(context: Context): RaselApplication {
            return instance ?: context.applicationContext as RaselApplication
        }

        fun startSyncService(context: Context) {
            val app = context.applicationContext
            val intent = Intent(app, SyncForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                app.startForegroundService(intent)
            } else {
                app.startService(intent)
            }
        }

        fun setLiveSyncEnabled(context: Context, enabled: Boolean) {
            context.applicationContext
                .getSharedPreferences(PREFS, MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_LIVE, enabled)
                .apply()
        }

        fun isLiveSyncEnabled(context: Context): Boolean {
            return context.applicationContext
                .getSharedPreferences(PREFS, MODE_PRIVATE)
                .getBoolean(KEY_LIVE, false)
        }
    }
}
