package com.example.uacc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.example.uacc.services.CallMonitoringManager
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    
    private var callMonitoringManager: CallMonitoringManager? = null
    
    companion object {
        private const val PERMISSION_REQUEST_CODE = 123
        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.READ_CALL_LOG,
            Manifest.permission.READ_CONTACTS,
            Manifest.permission.SYSTEM_ALERT_WINDOW
        )
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize platform channels for native live activity communication
        LiveActivityChannel.setupChannels(flutterEngine, this)
        
        // Setup call monitoring
        setupCallMonitoring(flutterEngine)
        
        // Request permissions if needed
        requestPermissionsIfNeeded()
    }
    
    private fun setupCallMonitoring(flutterEngine: FlutterEngine) {
        val methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.uacc/call_monitoring"
        )
        
        val eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.uacc/call_state_events"
        )
        
        callMonitoringManager = CallMonitoringManager(
            context = this,
            methodChannel = methodChannel,
            eventChannel = eventChannel
        )
    }
    
    private fun requestPermissionsIfNeeded() {
        val permissionsToRequest = REQUIRED_PERMISSIONS.filter { permission ->
            ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED
        }.toTypedArray()
        
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest,
                PERMISSION_REQUEST_CODE
            )
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            if (allGranted) {
                println("All permissions granted for call monitoring")
            } else {
                println("Some permissions denied for call monitoring")
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        LiveActivityChannel.cleanup()
        callMonitoringManager?.cleanup()
    }
}
