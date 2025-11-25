package com.antarikshverse.talkwithsaints

import android.graphics.Color
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Allow the app content to draw edge-to-edge (replaces deprecated system UI flags)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Make status and navigation bars transparent so Flutter can draw behind them
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        // Control appearance (light/dark icons) and transient behavior via WindowInsetsControllerCompat
        val insetsController = WindowInsetsControllerCompat(window, window.decorView)
        // Set to true if your app draws a light background behind the status/navigation bars
        insetsController.isAppearanceLightStatusBars = false
        insetsController.isAppearanceLightNavigationBars = false

        // Let users swipe to reveal the system bars temporarily
        insetsController.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }
}
