package com.geomeasure.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "geomeasure/capability_detection"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "detectCapabilities") {
                val capabilities = mapOf(
                    "hasLidar" to false,
                    "hasDepthSensor" to true,
                    "hasArCore" to true,
                    "hasArKit" to false,
                    "hasCamera" to true,
                    "hasGps" to true,
                    "hasCompass" to true,
                    "hasGyroscope" to true,
                    "hasAccelerometer" to true,
                    "hasBarometer" to false,
                    "hasBluetooth" to true,
                    "hasNfc" to false,
                    "hasUwb" to false,
                    "hasFlash" to true,
                    "hasMicrophone" to true,
                    "hasGpu" to true,
                    "hasAiAccelerator" to true,
                    "cameraCalibrated" to false,
                    "ramMb" to 4096,
                    "cpuCores" to 8,
                    "storageAvailableMb" to 4096,
                    "displayResolution" to "1080x2400",
                    "osVersion" to "Android 14",
                    "batteryLevel" to 0.95,
                    "thermalState" to "nominal",
                    "sensorAccuracy" to "high",
                    "networkType" to "wifi",
                    "permissionsGranted" to true
                )
                result.success(capabilities)
            } else {
                result.notImplemented()
            }
        }
    }
}
