package com.cometswitch.kenya

import android.app.Application
import android.util.Log
import com.smileidentity.SmileID

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Log.d("MainApplication", "Application onCreate started")

        // Initialize the Smile ID native SDK so that internal properties
        // (fileSavePath, offline-job dirs, etc.) are set before any
        // Flutter-side document-capture or selfie flow is launched.
        try {
            SmileID.initialize(
                context = this,
                useSandbox = true, // mirrors SmileIDConfig.useSandbox on Dart side
                enableCrashReporting = true,
            )
            Log.d("MainApplication", "SmileID native init succeeded")
        } catch (e: Exception) {
            Log.e("MainApplication", "SmileID native init failed", e)
        }
    }
}