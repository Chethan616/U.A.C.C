package com.example.uacc.dynamicisland.service

import android.accessibilityservice.AccessibilityService
import android.annotation.SuppressLint
import android.content.*
import android.content.Intent.ACTION_SCREEN_OFF
import android.content.Intent.ACTION_SCREEN_ON
import android.content.res.Configuration
import android.graphics.PixelFormat
import android.util.Log
import android.view.*
import android.view.WindowManager.LayoutParams.*
import android.view.accessibility.AccessibilityEvent
import androidx.compose.runtime.*
import androidx.compose.ui.platform.AndroidUiDispatcher
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.compositionContext
import androidx.lifecycle.*
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import com.example.uacc.dynamicisland.model.*
import com.example.uacc.dynamicisland.ui.IslandApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import android.app.Service
import android.telephony.TelephonyManager

class IslandOverlayService : AccessibilityService() {

    private val params = WindowManager.LayoutParams(
        WRAP_CONTENT,
        WRAP_CONTENT,
        TYPE_ACCESSIBILITY_OVERLAY,
        FLAG_LAYOUT_IN_SCREEN or FLAG_LAYOUT_NO_LIMITS or FLAG_NOT_TOUCH_MODAL or FLAG_NOT_FOCUSABLE,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
    }

    private val serviceScope = CoroutineScope(AndroidUiDispatcher.Main)
    
    // Overlay management
    private var overlayView: ComposeView? = null
    private var windowManager: WindowManager? = null
    private var isOverlayVisible = false

    // State of the overlay
    var islandState: IslandState by mutableStateOf(IslandViewState.Closed)
        private set
    
    // Call transcript plugin
    private var callTranscriptPlugin: CallTranscriptPlugin? = null
    
    // Call state tracking
    private var isInActiveCall = false
    private var telephonyManager: TelephonyManager? = null

    companion object {
        var instance: IslandOverlayService? = null
            private set
        private const val TAG = "IslandOverlayService"
    }

    private val broadcastReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                SETTINGS_CHANGED -> {
                    init()
                }
                ACTION_SCREEN_ON -> {
                    Island.isScreenOn = true
                    Log.d(TAG, "Screen turned ON")
                }
                ACTION_SCREEN_OFF -> {
                    Island.isScreenOn = false
                    Log.d(TAG, "Screen turned OFF")
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.getStringExtra("action")?.let { action ->
            when (action) {
                "startTranscript" -> startCallTranscript()
                "stopTranscript" -> stopCallTranscript()
                "addTranscriptMessage" -> {
                    val text = intent.getStringExtra("text") ?: ""
                    val speakerTypeStr = intent.getStringExtra("speakerType") ?: "OUTGOING"
                    val isPartial = intent.getBooleanExtra("isPartial", false)
                    val speakerType = when (speakerTypeStr) {
                        "INCOMING" -> SpeakerType.INCOMING
                        "OUTGOING" -> SpeakerType.OUTGOING
                        "SYSTEM" -> SpeakerType.SYSTEM
                        else -> SpeakerType.OUTGOING
                    }
                    addTranscriptMessage(text, speakerType, isPartial)
                }
                "expand" -> expand()
                "collapse" -> shrink()
                "updateTranscript" -> {
                    val transcript = intent.getStringExtra("transcript") ?: ""
                    updateTranscript(transcript)
                }
                "clearTranscript" -> clearTranscript()
            }
        }
        return START_STICKY
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "MaterialYou Dynamic Island Service Connected")
        instance = this

        // Register broadcast receiver
        val filter = IntentFilter().apply {
            addAction(SETTINGS_CHANGED)
            addAction(ACTION_SCREEN_ON)
            addAction(ACTION_SCREEN_OFF)
        }
        
        // Use RECEIVER_NOT_EXPORTED for Android 13+ compatibility
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(broadcastReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(broadcastReceiver, filter)
        }

        // Initialize
        init()

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        showOverlay(windowManager!!, params)
    }

    fun init() {
        // Reset island state
        islandState = IslandViewState.Closed

        // Initialize the plugin system
        PluginManager.initializePlugins(this)
        
        // Initialize call transcript plugin
        callTranscriptPlugin = PluginManager.createCallTranscriptPlugin(serviceScope)
        callTranscriptPlugin?.onCreate(this)
        
        // Initialize telephony manager for call state checking
        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        
        Log.d(TAG, "Dynamic Island initialized with call transcript plugin")
        
        // Check if we're already in a call and show island accordingly
        checkCallState()
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun showOverlay(
        windowManager: WindowManager,
        params: WindowManager.LayoutParams
    ) {
        // Remove existing overlay if present
        hideOverlay()
        
        overlayView = ComposeView(this)

        overlayView!!.setContent {
            // Listen for plugin changes
            LaunchedEffect(PluginManager.activePlugins.size) {
                islandState = if (PluginManager.activePlugins.isNotEmpty()) {
                    IslandViewState.Opened
                } else {
                    IslandViewState.Closed
                }
                Log.d(TAG, "Active plugins changed: ${PluginManager.activePlugins.size}")
            }

            IslandApp(
                islandOverlayService = this@IslandOverlayService,
            )
        }

        // Lifecycle setup for Compose in overlay
        val viewModelStore = ViewModelStore()
        val viewModelStoreOwner = object : ViewModelStoreOwner {
            override val viewModelStore: ViewModelStore
                get() = viewModelStore
        }

        val lifecycleOwner = MyLifecycleOwner()
        lifecycleOwner.performRestore(null)
        lifecycleOwner.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
        overlayView!!.setViewTreeLifecycleOwner(lifecycleOwner)
        overlayView!!.setViewTreeSavedStateRegistryOwner(lifecycleOwner)
        overlayView!!.setViewTreeViewModelStoreOwner(viewModelStoreOwner)

        // Make recomposition happen on the UI thread
        val coroutineContext = AndroidUiDispatcher.CurrentThread
        val runRecomposeScope = CoroutineScope(coroutineContext)
        val recomposer = Recomposer(coroutineContext)
        overlayView!!.compositionContext = recomposer
        runRecomposeScope.launch {
            recomposer.runRecomposeAndApplyChanges()
        }

        // Add the view to the window only if not in landscape
        if (resources.configuration.orientation != Configuration.ORIENTATION_LANDSCAPE) {
            addOverlayToWindow()
        }
    }
    
    private fun addOverlayToWindow() {
        overlayView?.let { view ->
            if (!isOverlayVisible && windowManager != null) {
                try {
                    // Add fade-in animation
                    view.alpha = 0f
                    view.animate()
                        .alpha(1f)
                        .setDuration(300)
                        .start()
                    
                    windowManager!!.addView(view, params)
                    isOverlayVisible = true
                    Log.d(TAG, "Dynamic Island overlay added to window with fade-in")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to add overlay to window", e)
                }
            }
        }
    }
    
    private fun removeOverlayFromWindow() {
        overlayView?.let { view ->
            if (isOverlayVisible && windowManager != null) {
                // Add fade-out animation before removal
                view.animate()
                    .alpha(0f)
                    .setDuration(300)
                    .withEndAction {
                        try {
                            windowManager!!.removeView(view)
                            isOverlayVisible = false
                            Log.d(TAG, "Dynamic Island overlay removed from window with fade-out")
                        } catch (e: Exception) {
                            Log.w(TAG, "Overlay already removed or not attached")
                        }
                    }
                    .start()
            }
        }
    }
    
    private fun hideOverlay() {
        overlayView?.let { view ->
            if (isOverlayVisible && windowManager != null) {
                try {
                    windowManager!!.removeView(view)
                    isOverlayVisible = false
                    Log.d(TAG, "Dynamic Island overlay immediately hidden")
                } catch (e: Exception) {
                    Log.w(TAG, "Overlay already removed or not attached")
                }
            }
        }
        overlayView = null
    }

    fun showIsland() {
        islandState = IslandViewState.Opened
        Log.d(TAG, "Dynamic Island shown")
    }

    fun hideIsland() {
        islandState = IslandViewState.Closed
        Log.d(TAG, "Dynamic Island hidden")
    }

    fun expand() {
        // Simple vertical drop expansion
        islandState = IslandViewState.Expanded(configuration = resources.configuration)
        Log.d(TAG, "Dynamic Island expanded with vertical drop")
    }

    fun shrink() {
        islandState = IslandViewState.Opened
        Log.d(TAG, "Dynamic Island shrunk")
    }
    
    fun closeToCircle() {
        // First deactivate all plugins
        PluginManager.activePlugins.forEach { plugin ->
            plugin.isActive = false
            plugin.isPulsing = false
        }
        PluginManager.activePlugins.clear()
        
        // Then set state to closed (circle)
        islandState = IslandViewState.Closed
        Log.d(TAG, "Dynamic Island closed to circle")
    }
    
    // Call state checking
    private fun checkCallState() {
        telephonyManager?.let { tm ->
            isInActiveCall = tm.callState == TelephonyManager.CALL_STATE_OFFHOOK
            Log.d(TAG, "Current call state: ${tm.callState}, isInActiveCall: $isInActiveCall")
            
            if (isInActiveCall) {
                // We're in an active call, start transcript service
                startCallTranscript()
            } else {
                // No active call, make sure island is hidden
                stopCallTranscript()
            }
        }
    }
    
    // Call Transcript Management Methods
    fun startCallTranscript() {
        // Only start transcript if we're actually in a call
        telephonyManager?.let { tm ->
            if (tm.callState == TelephonyManager.CALL_STATE_OFFHOOK) {
                isInActiveCall = true
                callTranscriptPlugin?.let { plugin ->
                    plugin.startTranscript()
                    PluginManager.addPlugin(plugin)
                    showIsland() // Show island only during active calls
                    Log.d(TAG, "🎤 Call transcript started - Dynamic Island visible")
                } ?: run {
                    Log.w(TAG, "Call transcript plugin not available")
                }
            } else {
                Log.w(TAG, "Cannot start transcript - not in active call (state: ${tm.callState})")
            }
        }
    }
    
    fun stopCallTranscript() {
        isInActiveCall = false
        callTranscriptPlugin?.let { plugin ->
            plugin.stopTranscript()
            // Remove the plugin from PluginManager to hide the Dynamic Island
            PluginManager.removePlugin(plugin)
            closeToCircle() // Ensure island is hidden
            Log.d(TAG, "🎤 Call transcript stopped and Dynamic Island hidden")
        }
    }
    
    fun addTranscriptMessage(text: String, speakerType: SpeakerType, isPartial: Boolean = false) {
        val plugin = callTranscriptPlugin

        if (plugin == null) {
            Log.w(TAG, "Transcript plugin unavailable, ignoring message")
            return
        }

        if (!plugin.isActive) {
            // If messages arrive before the plugin toggles active, activate on demand
            Log.d(TAG, "Transcript message received before activation; starting plugin")
            plugin.startTranscript()
            PluginManager.addPlugin(plugin)
            showIsland()
        }

        plugin.addTranscriptMessage(text, speakerType, isPartial)
        Log.d(TAG, "💬 Transcript message added: [$speakerType] $text (partial=$isPartial)")
    }
    
    fun updateTranscript(text: String) {
        // Legacy method for basic transcript updates
        callTranscriptPlugin?.let { plugin ->
            plugin.addTranscriptMessage(text, SpeakerType.OUTGOING, false)
        }
    }
    
    fun clearTranscript() {
        callTranscriptPlugin?.let { plugin ->
            plugin.clearTranscript()
            // After clearing, remove the plugin to hide the Dynamic Island
            PluginManager.removePlugin(plugin)
            Log.d(TAG, "🗑️ Transcript cleared and plugin removed")
        }
    }
    
    fun getCallTranscriptPlugin(): CallTranscriptPlugin? {
        return callTranscriptPlugin
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.d(TAG, "Dynamic Island Service unbound")
        instance = null
        hideOverlay() // Clean up overlay when service unbinds
        try {
            unregisterReceiver(broadcastReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Broadcast receiver not registered")
        }
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Dynamic Island Service destroyed")
        PluginManager.activePlugins.forEach { it.onDestroy() }
        hideOverlay() // Clean up overlay on service destroy
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        val wasInLandscape = Island.isInLandscape
        Island.isInLandscape = newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE
        
        Log.d(TAG, "Configuration changed - Landscape: ${Island.isInLandscape}")
        
        // Handle overlay visibility based on orientation
        when (newConfig.orientation) {
            Configuration.ORIENTATION_LANDSCAPE -> {
                if (!wasInLandscape) {
                    Log.d(TAG, "Switching to landscape - hiding overlay")
                    removeOverlayFromWindow()
                }
            }
            Configuration.ORIENTATION_PORTRAIT -> {
                if (wasInLandscape) {
                    Log.d(TAG, "Switching to portrait - showing overlay")
                    addOverlayToWindow()
                }
            }
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Handle accessibility events if needed
    }

    override fun onInterrupt() {
        // Handle service interruption
    }
}