package com.example.whatsapp

import io.flutter.plugin.common.MethodChannel

object FlutterBridge {
    @Volatile
    var keepAliveChannel: MethodChannel? = null
}
