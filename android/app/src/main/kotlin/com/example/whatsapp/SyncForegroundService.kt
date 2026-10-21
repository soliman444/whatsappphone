package com.example.whatsapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class SyncForegroundService : Service() {
    private val ticker = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    private val tick = object : Runnable {
        override fun run() {
            try {
                FlutterBridge.keepAliveChannel?.invokeMethod("tick", null)
            } catch (_: Exception) {
            }
            ticker.postDelayed(this, 15_000)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        acquireLocks()
        ticker.postDelayed(tick, 15_000)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAsForeground()
        if (wakeLock?.isHeld != true) acquireLocks()
        Handler(Looper.getMainLooper()).post {
            try {
                RaselApplication.get(this).ensureEngine()
            } catch (_: Exception) {
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        ticker.removeCallbacks(tick)
        releaseLocks()
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        val restart = Intent(applicationContext, SyncForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(restart)
        } else {
            startService(restart)
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun startAsForeground() {
        val channelId = "wa_sync_live"
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    "الاتصال في الخلفية",
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
        val launch = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification: Notification =
            NotificationCompat.Builder(this, channelId)
                .setContentTitle("راسل متصل")
                .setContentText("يستقبل الرسائل في الخلفية")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .setSilent(true)
                .setContentIntent(launch)
                .build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(
                1001,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_REMOTE_MESSAGING,
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                1001,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(1001, notification)
        }
    }

    private fun acquireLocks() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (wakeLock == null) {
                wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "rasel:sync")
                wakeLock?.setReferenceCounted(false)
            }
            if (wakeLock?.isHeld != true) wakeLock?.acquire()
        } catch (_: Exception) {
        }
        try {
            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            if (wifiLock == null) {
                wifiLock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    wm.createWifiLock(WifiManager.WIFI_MODE_FULL_LOW_LATENCY, "rasel:wifi")
                } else {
                    @Suppress("DEPRECATION")
                    wm.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "rasel:wifi")
                }
                wifiLock?.setReferenceCounted(false)
            }
            if (wifiLock?.isHeld != true) wifiLock?.acquire()
        } catch (_: Exception) {
        }
    }

    private fun releaseLocks() {
        try {
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (_: Exception) {
        }
        try {
            if (wifiLock?.isHeld == true) wifiLock?.release()
        } catch (_: Exception) {
        }
        wakeLock = null
        wifiLock = null
    }
}
