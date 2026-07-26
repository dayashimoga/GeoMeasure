package com.geomeasure.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import android.hardware.camera2.CameraManager
import android.os.BatteryManager
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "geomeasure/capability_detection"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "detectCapabilities") {
                val capabilities = HashMap<String, Any>()
                val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
                val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
                val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager

                val hasGyro = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE) != null
                val hasAccel = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null
                val hasCompass = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null
                val hasBarometer = sensorManager.getDefaultSensor(Sensor.TYPE_PRESSURE) != null

                var hasDepthSensor = false
                try {
                    val cameraIds = cameraManager.cameraIdList
                    for (id in cameraIds) {
                        val chars = cameraManager.getCameraCharacteristics(id)
                        val caps = chars.get(android.hardware.camera2.CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
                        if (caps != null && caps.contains(android.hardware.camera2.CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT)) {
                            hasDepthSensor = true
                            break
                        }
                    }
                } catch (e: Exception) {
                    hasDepthSensor = false
                }

                val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) / 100.0

                capabilities["hasLidar"] = false
                capabilities["hasDepthSensor"] = hasDepthSensor
                capabilities["hasArCore"] = true
                capabilities["hasArKit"] = false
                capabilities["hasCamera"] = true
                capabilities["hasGps"] = true
                capabilities["hasCompass"] = hasCompass
                capabilities["hasGyroscope"] = hasGyro
                capabilities["hasAccelerometer"] = hasAccel
                capabilities["hasBarometer"] = hasBarometer
                capabilities["hasBluetooth"] = true
                capabilities["hasNfc"] = true
                capabilities["hasUwb"] = false
                capabilities["ramMb"] = (Runtime.getRuntime().maxMemory() / (1024 * 1024)).toInt()
                capabilities["cpuCores"] = Runtime.getRuntime().availableProcessors()
                capabilities["hasAiAccelerator"] = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                capabilities["batteryLevel"] = batteryLevel
                capabilities["thermalState"] = "nominal"
                capabilities["sensorAccuracy"] = if (hasGyro && hasAccel) "high" else "medium"
                capabilities["permissionsGranted"] = true

                result.success(capabilities)
            } else {
                result.notImplemented()
            }
        }
    }
}
