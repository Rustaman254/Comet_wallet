package com.cometswitch.kenya

import android.app.Application
import android.util.Log

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Log.d("MainApplication", "Application onCreate started")
        // SmileID initialization is handled by the Dart plugin via SmileID.initializeWithConfig
        // The native SDK will be properly initialized when the Dart layer calls initializeWithConfig
        Log.d("MainApplication", "Application onCreate completed")
    }
}