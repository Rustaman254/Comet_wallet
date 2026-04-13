package com.asteropay.kenya

import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onResume() {
        super.onResume()
        // The SmileID SDK context is maintained by the Flutter plugin
        Log.d("MainActivity", "Activity resumed")
    }
}
