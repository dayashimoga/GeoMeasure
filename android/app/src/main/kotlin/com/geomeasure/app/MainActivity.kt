package com.geomeasure.app

import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.BatteryManager
import android.os.Build
import android.os.StatFs
import android.os.Environment
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.view.WindowManager
import android.util.DisplayMetrics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "geomeasure/capability_detection"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "detectCapabilities") {
                try {
                    val capabilities = detectRealCapabilities()
                    result.success(capabilities)
                } catch (e: Exception) {
                    result.error("DETECTION_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun detectRealCapabilities(): Map<String, Any> {
        val ctx = applicationContext
        val pm = ctx.packageManager
        val sensorManager = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager

        // Sensor availability checks
        val hasGyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE) != null
        val hasAccelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null
        val hasCompass = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null
        val hasBarometer = sensorManager.getDefaultSensor(Sensor.TYPE_PRESSURE) != null

        // Camera / depth sensor checks
        val hasCamera = pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
        val hasFlash = pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
        var hasDepthSensor = false
        var hasLidar = false
        try {
            val cameraManager = ctx.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            for (cameraId in cameraManager.cameraIdList) {
                val chars = cameraManager.getCameraCharacteristics(cameraId)
                val facing = chars.get(CameraCharacteristics.LENS_FACING)
                if (facing == CameraCharacteristics.LENS_FACING_BACK) {
                    // Check for depth sensor capability
                    val capabilities = chars.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
                    if (capabilities != null) {
                        if (capabilities.contains(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT)) {
                            hasDepthSensor = true
                        }
                    }
                    // Check for ToF sensor (time-of-flight) via physical camera list
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        val physicalCameraIds = chars.physicalCameraIds
                        if (physicalCameraIds.size > 1) {
                            // Multi-camera setup may include ToF
                            for (physicalId in physicalCameraIds) {
                                try {
                                    val physChars = cameraManager.getCameraCharacteristics(physicalId)
                                    val physCaps = physChars.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
                                    if (physCaps != null && physCaps.contains(
                                            CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT)) {
                                        hasDepthSensor = true
                                    }
                                } catch (_: Exception) { }
                            }
                        }
                    }
                }
            }
        } catch (_: Exception) { }

        // ARCore availability check
        val hasArCore = pm.hasSystemFeature("com.google.ar.core") ||
                try {
                    pm.getPackageInfo("com.google.ar.core", 0)
                    true
                } catch (_: PackageManager.NameNotFoundException) {
                    false
                }

        // GPS check
        val hasGps = pm.hasSystemFeature(PackageManager.FEATURE_LOCATION_GPS)

        // Connectivity checks
        val hasBluetooth = pm.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)
        val hasNfc = pm.hasSystemFeature(PackageManager.FEATURE_NFC)
        val hasUwb = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            pm.hasSystemFeature(PackageManager.FEATURE_UWB)
        } else false
        val hasMicrophone = pm.hasSystemFeature(PackageManager.FEATURE_MICROPHONE)

        // Battery level
        val batteryManager = ctx.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) / 100.0

        // RAM
        val runtime = Runtime.getRuntime()
        val activityManager = ctx.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val memInfo = android.app.ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)
        val ramMb = (memInfo.totalMem / (1024 * 1024)).toInt()

        // CPU cores
        val cpuCores = runtime.availableProcessors()

        // Storage available
        val stat = StatFs(Environment.getDataDirectory().path)
        val storageAvailableMb = (stat.availableBlocksLong * stat.blockSizeLong / (1024 * 1024)).toInt()

        // Display resolution
        val wm = ctx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val displayMetrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        wm.defaultDisplay.getRealMetrics(displayMetrics)
        val displayResolution = "${displayMetrics.widthPixels}x${displayMetrics.heightPixels}"

        // Network type
        val connectivityManager = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val networkType = try {
            val activeNetwork = connectivityManager.activeNetwork
            val networkCaps = connectivityManager.getNetworkCapabilities(activeNetwork)
            when {
                networkCaps == null -> "none"
                networkCaps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                networkCaps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
                else -> "none"
            }
        } catch (_: Exception) { "none" }

        // OS version
        val osVersion = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"

        // AI accelerator (NNAPI available on API 27+)
        val hasAiAccelerator = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1

        // GPU is assumed available on all modern Android devices
        val hasGpu = true

        // Sensor accuracy heuristic
        val sensorAccuracy = when {
            hasGyroscope && hasAccelerometer && hasCompass && hasBarometer -> "high"
            hasGyroscope && hasAccelerometer && hasCompass -> "medium"
            hasAccelerometer -> "low"
            else -> "uncalibrated"
        }

        // Thermal state (requires API 29+)
        val thermalState = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val powerManager = ctx.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                when (powerManager.currentThermalStatus) {
                    android.os.PowerManager.THERMAL_STATUS_NONE,
                    android.os.PowerManager.THERMAL_STATUS_LIGHT -> "nominal"
                    android.os.PowerManager.THERMAL_STATUS_MODERATE -> "fair"
                    android.os.PowerManager.THERMAL_STATUS_SEVERE -> "serious"
                    android.os.PowerManager.THERMAL_STATUS_CRITICAL,
                    android.os.PowerManager.THERMAL_STATUS_EMERGENCY,
                    android.os.PowerManager.THERMAL_STATUS_SHUTDOWN -> "critical"
                    else -> "nominal"
                }
            } catch (_: Exception) { "nominal" }
        } else "nominal"

        // Camera calibration check
        val cameraCalibrated = try {
            val cameraManager = ctx.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            var calibrated = false
            for (cameraId in cameraManager.cameraIdList) {
                val chars = cameraManager.getCameraCharacteristics(cameraId)
                val facing = chars.get(CameraCharacteristics.LENS_FACING)
                if (facing == CameraCharacteristics.LENS_FACING_BACK) {
                    val intrinsics = chars.get(CameraCharacteristics.LENS_INTRINSIC_CALIBRATION)
                    if (intrinsics != null) {
                        calibrated = true
                    }
                    break
                }
            }
            calibrated
        } catch (_: Exception) { false }

        // Permissions check (camera + location)
        val permissionsGranted =
            ctx.checkSelfPermission(android.Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED &&
            ctx.checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

        return mapOf(
            "hasLidar" to hasLidar,
            "hasDepthSensor" to hasDepthSensor,
            "hasArCore" to hasArCore,
            "hasArKit" to false, // ARKit is iOS-only
            "hasCamera" to hasCamera,
            "hasGps" to hasGps,
            "hasCompass" to hasCompass,
            "hasGyroscope" to hasGyroscope,
            "hasAccelerometer" to hasAccelerometer,
            "hasBarometer" to hasBarometer,
            "hasBluetooth" to hasBluetooth,
            "hasNfc" to hasNfc,
            "hasUwb" to hasUwb,
            "hasFlash" to hasFlash,
            "hasMicrophone" to hasMicrophone,
            "hasGpu" to hasGpu,
            "hasAiAccelerator" to hasAiAccelerator,
            "cameraCalibrated" to cameraCalibrated,
            "ramMb" to ramMb,
            "cpuCores" to cpuCores,
            "storageAvailableMb" to storageAvailableMb,
            "displayResolution" to displayResolution,
            "osVersion" to osVersion,
            "batteryLevel" to batteryLevel,
            "thermalState" to thermalState,
            "sensorAccuracy" to sensorAccuracy,
            "networkType" to networkType,
            "permissionsGranted" to permissionsGranted
        )
    }
}
