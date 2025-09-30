package com.example.uacc.dynamicisland.model

import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import android.content.Context
import android.telephony.TelephonyManager
import android.telephony.PhoneStateListener
import android.service.notification.StatusBarNotification
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import com.example.uacc.dynamicisland.service.*
import com.example.uacc.dynamicisland.service.IslandOverlayService
import com.example.uacc.dynamicisland.service.NotificationSummaryService
import com.airbnb.lottie.LottieAnimationView
import com.airbnb.lottie.LottieDrawable

abstract class BasePlugin {
    abstract val id: String
    abstract val name: String
    abstract val description: String
    
    var isActive: Boolean = false
    var isPulsing: Boolean = false  // New: indicates if plugin should pulse
    var pulseColor: Color = Color.Green  // New: color for pulsing animation
    var autoCloseAfterSeconds: Int = 0  // New: auto-close timer (0 = no auto-close)
    open val hasAiContent: Boolean
        get() = false
    
    abstract fun canExpand(): Boolean
    abstract fun onCreate(context: IslandOverlayService?)
    
    @Composable
    abstract fun ExpandedComposable()
    
    abstract fun onClick()
    abstract fun onDestroy()
    
    @Composable
    abstract fun LeftOpenedComposable()
    
    @Composable
    abstract fun RightOpenedComposable()
}

class CallPlugin : BasePlugin() {
    override val id: String = "call_plugin"
    override val name: String = "Call Monitor"
    override val description: String = "Dynamic Island plugin for incoming/outgoing calls"
    
    private var callState by mutableStateOf(TelephonyManager.CALL_STATE_IDLE)
    private var phoneNumber by mutableStateOf("")
    private var telephonyManager: TelephonyManager? = null
    private var overlayService: IslandOverlayService? = null
    
    // Manual state for testing - remove this in production
    private var isTestPulsing by mutableStateOf(false)
    
    private val phoneStateListener = object : PhoneStateListener() {
        override fun onCallStateChanged(state: Int, phoneNumber: String?) {
            callState = state
            this@CallPlugin.phoneNumber = phoneNumber ?: ""
            
            when (state) {
                TelephonyManager.CALL_STATE_RINGING -> {
                    // Incoming call - softer green pulse (more breathing-like)
                    isPulsing = true
                    pulseColor = Color(0xFF4CAF50) // Softer Material Green instead of bright lime
                    isActive = true
                    // Force update the overlay service
                    overlayService?.let { service ->
                        service.showIsland()
                    }
                }
                TelephonyManager.CALL_STATE_OFFHOOK -> {
                    // Call in progress - blue pulse (keep this)
                    isPulsing = true
                    pulseColor = Color(0xFF2196F3) // Material Blue
                    isActive = true
                }
                TelephonyManager.CALL_STATE_IDLE -> {
                    // No call - stop pulsing and hide island
                    isPulsing = false
                    isActive = isTestPulsing // Keep active if test pulsing
                    
                    // Auto-minimize to circle when call ends
                    if (!isTestPulsing) {
                        overlayService?.hideIsland()
                    }
                }
            }
            
            // Force re-initialization of plugins to update UI
            overlayService?.let { service ->
                PluginManager.refreshActivePlugins(service)
            }
        }
    }
    
    // Test method to manually trigger pulse
    fun startTestPulse(color: Color = Color(0xFF4CAF50)) { // Softer green for test
        isTestPulsing = true
        isPulsing = true
        pulseColor = color
        isActive = true
        callState = TelephonyManager.CALL_STATE_RINGING
        phoneNumber = "Test Call"
        
        overlayService?.let { service ->
            service.showIsland()
            PluginManager.refreshActivePlugins(service)
        }
    }
    
    fun stopTestPulse() {
        isTestPulsing = false
        isPulsing = false
        isActive = false
        callState = TelephonyManager.CALL_STATE_IDLE
        phoneNumber = ""
        
        // Auto-minimize to circle when test pulse stops
        overlayService?.let { service ->
            service.hideIsland()
            PluginManager.refreshActivePlugins(service)
        }
    }
    
    override fun canExpand(): Boolean = isActive
    
    override fun onCreate(context: IslandOverlayService?) {
        overlayService = context
        context?.let { service ->
            val androidContext = service.applicationContext
            telephonyManager = androidContext.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            
            try {
                telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
            } catch (e: SecurityException) {
                // Handle permission error - start test pulse to show functionality
                startTestPulse(Color(0xFF00FF00)) // Green test pulse
            }
        }
    }
    
    @Composable
    override fun ExpandedComposable() {
        val callStateText = when {
            isTestPulsing -> "🧪 Test Pulse Active"
            callState == TelephonyManager.CALL_STATE_RINGING -> "📞 Incoming Call"
            callState == TelephonyManager.CALL_STATE_OFFHOOK -> "📞 Call Active"
            else -> "📞 Call"
        }
        
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = callStateText,
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                if (phoneNumber.isNotEmpty()) {
                    Text(
                        text = if (isTestPulsing) "Tap to stop test" else phoneNumber,
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.8f),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }
    }
    
    override fun onClick() {
        // If test pulsing, stop it
        if (isTestPulsing) {
            stopTestPulse()
        }
        // Could add call actions here (answer, decline, etc.)
    }
    
    override fun onDestroy() {
        telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
        stopTestPulse()
        isActive = false
        isPulsing = false
    }
    
    @Composable
    override fun LeftOpenedComposable() {
        val callIcon = when (callState) {
            TelephonyManager.CALL_STATE_RINGING -> "📞"
            TelephonyManager.CALL_STATE_OFFHOOK -> "📱"
            else -> "📞"
        }
        
        Row(
            modifier = Modifier.padding(horizontal = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = callIcon,
                fontSize = 16.sp
            )
        }
    }
    
    @Composable
    override fun RightOpenedComposable() {
        val callText = when (callState) {
            TelephonyManager.CALL_STATE_RINGING -> "Incoming"
            TelephonyManager.CALL_STATE_OFFHOOK -> "Active"
            else -> "Call"
        }
        
        Row(
            modifier = Modifier.padding(horizontal = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = callText,
                fontSize = 12.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

class DemoPlugin : BasePlugin() {
    override val id: String = "demo_plugin"
    override val name: String = "Demo Plugin"
    override val description: String = "A simple demo plugin for Dynamic Island"
    
    private var isExpanded by mutableStateOf(false)
    
    override fun canExpand(): Boolean = true

    override fun onCreate(context: IslandOverlayService?) {
        // Initialize plugin
    }

    @Composable
    override fun ExpandedComposable() {
        Text(
            text = "Demo Expanded Content",
            color = Color.White,
            modifier = Modifier.padding(16.dp)
        )
    }

    override fun onClick() {
        // Handle click
    }

    override fun onDestroy() {
        // Clean up
    }

    @Composable
    override fun LeftOpenedComposable() {
        Icon(
            imageVector = Icons.Default.Info,
            contentDescription = "Demo",
            tint = Color.White,
            modifier = Modifier
                .size(16.dp) // Reduced from 20.dp (20% smaller)
                .clip(CircleShape) // Make it circular
        )
    }

    @Composable
    override fun RightOpenedComposable() {
        Text(
            text = "D",
            color = Color.White,
            fontSize = 14.sp
        )
    }
}

class NotificationPlugin(
    private val notification: StatusBarNotification,
    private val context: IslandOverlayService?,
    private val coroutineScope: CoroutineScope
) : BasePlugin() {
    override val id = "notification_${notification.postTime}"
    override val name = notification.packageName
    override val description = "Notification from ${notification.packageName}"
    
    private val appName: String by lazy {
        val pm = context?.packageManager
        pm?.getApplicationInfo(notification.packageName, 0)
            ?.loadLabel(pm)?.toString() ?: notification.packageName
    }
    
    private val notificationTitle: String by lazy {
        notification.notification?.extras?.getString("android.title") ?: "Notification"
    }
    
    private val notificationText: String by lazy {
        notification.notification?.extras?.getString("android.text")?.toString() ?: ""
    }
    
    // AI-powered analysis state
    private var aiAnalysis by mutableStateOf<NotificationSummary?>(null)
    private var isLoadingAnalysis by mutableStateOf(true)

    override val hasAiContent: Boolean
        get() = !isLoadingAnalysis && aiAnalysis != null
    
    init {
        isPulsing = true
        pulseColor = Color(0xFF2196F3) // Blue for notifications
        autoCloseAfterSeconds = 10 // Slightly longer for AI processing
        
        // Generate AI analysis asynchronously
        generateAIAnalysis()
    }
    
    private fun generateAIAnalysis() {
        coroutineScope.launch {
            try {
                isLoadingAnalysis = true
                
                // Call the enhanced Gemini API for comprehensive analysis
                val analysis = NotificationSummaryService.analyzeNotificationAsAgent(
                    notificationTitle, 
                    notificationText, 
                    appName
                )
                
                aiAnalysis = analysis
                isLoadingAnalysis = false
                
                Log.d("NotificationPlugin", "🤖 AI Agent Analysis completed: ${analysis.summary}")
                Log.d("NotificationPlugin", "📋 Action items: ${analysis.actionItems}")
                Log.d("NotificationPlugin", "📅 Scheduled items: ${analysis.scheduledItems.size}")
                
                // Sync scheduled items to Google Calendar/Tasks if available
                syncScheduledItems(analysis.scheduledItems)
                
            } catch (e: Exception) {
                Log.e("NotificationPlugin", "❌ Error generating AI analysis", e)
                // Fallback to smart analysis
                val fallback = NotificationSummary(
                    summary = createSmartFallback(),
                    actionItems = emptyList(),
                    scheduledItems = emptyList(),
                    priority = Priority.NORMAL
                )
                aiAnalysis = fallback
                isLoadingAnalysis = false
            }
        }
    }
    
    private fun syncScheduledItems(items: List<ScheduledItem>) {
        // TODO: Integrate with Google Calendar/Tasks service
        // This will be implemented in the next step
        coroutineScope.launch {
            items.forEach { item ->
                Log.d("NotificationPlugin", "🔄 Scheduling: ${item.type} - ${item.title}")
                // Add to Google Calendar or Tasks based on type
            }
        }
    }
    
    private fun createSmartFallback(): String {
        val fallback = NotificationSummaryService.createFallbackAnalysis(
            notificationTitle,
            notificationText,
            appName
        )

        if (fallback.summary.isNotBlank()) {
            return fallback.summary
        }

        val sanitizedFallback = sequenceOf(notificationTitle, notificationText, appName)
            .firstOrNull { it.isNotBlank() }
            ?.trim()
            ?.let { base -> if (base.length > 80) base.take(77) + "…" else base }

        return sanitizedFallback ?: "Notification update"
    }

    override fun canExpand(): Boolean = true

    override fun onCreate(context: IslandOverlayService?) {
        // Auto-dismiss after 8 seconds (only if not expanded)
        coroutineScope.launch {
            delay(8000)
            if (isActive && context?.islandState?.state != IslandStates.Expanded) {
                context?.closeToCircle()
            }
        }
    }

    @Composable
    override fun ExpandedComposable() {
        Column(
            modifier = Modifier
                .padding(horizontal = 16.dp, vertical = 16.dp)  // Increased vertical padding
                .fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp)  // Added consistent spacing between elements
        ) {
            // App name at the top with priority indicator
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                val priorityIcon = when (aiAnalysis?.priority) {
                    Priority.URGENT -> "🔴"
                    Priority.HIGH -> "🟠"
                    Priority.NORMAL -> "🔵"
                    Priority.LOW -> "⚪"
                    else -> "📱"
                }
                
                Text(
                    text = "$priorityIcon $appName",
                    color = Color.White,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // AI Analysis with loading state
            if (isLoadingAnalysis) {
                // Animated loading indicator
                val alpha by animateFloatAsState(
                    targetValue = 0.5f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(durationMillis = 1200),
                        repeatMode = RepeatMode.Reverse
                    ),
                    label = "loading_alpha"
                )
                
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "🤖 AI Agent analyzing...",
                        color = Color.White.copy(alpha = alpha),
                        fontSize = 13.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = "Extracting tasks & events...",
                        color = Color.White.copy(alpha = alpha * 0.7f),
                        fontSize = 11.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            } else {
                aiAnalysis?.let { analysis ->
                    val highlightBrush = rememberGoogleGradientBrush()
                    val summaryParagraphs = analysis.summary
                        .split("\n")
                        .map { it.trim() }
                        .filter { it.isNotEmpty() }
                    val scrollState = rememberScrollState()

                    LaunchedEffect(summaryParagraphs) {
                        scrollState.scrollTo(0)
                        delay(1000)
                        if (scrollState.maxValue > 0) {
                            scrollState.animateScrollTo(
                                scrollState.maxValue,
                                animationSpec = tween(
                                    durationMillis = 1800,
                                    easing = LinearEasing
                                )
                            )
                        }
                    }

                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 64.dp, max = 220.dp)
                            .verticalScroll(scrollState)
                            .animateContentSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        summaryParagraphs.forEachIndexed { index, paragraph ->
                            val fontSize = when (index) {
                                0 -> 15.sp
                                1 -> 14.sp
                                else -> 13.sp
                            }
                            val alpha = when (index) {
                                0 -> 0.95f
                                1 -> 0.85f
                                else -> 0.75f
                            }

                            val annotatedParagraph = rememberAiHighlightedText(
                                text = paragraph,
                                highlightBrush = highlightBrush,
                                highlightAlpha = alpha
                            )

                            Text(
                                text = annotatedParagraph,
                                color = Color.White.copy(alpha = alpha),
                                fontSize = fontSize,
                                fontWeight = if (index == 0) FontWeight.Medium else FontWeight.Normal,
                                modifier = Modifier.fillMaxWidth(),
                                overflow = TextOverflow.Clip
                            )
                        }
                    }
                    
                    // Show action items count if any
                    if (analysis.actionItems.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "✅ ${analysis.actionItems.size} action${if (analysis.actionItems.size > 1) "s" else ""} • ${analysis.scheduledItems.size} scheduled",
                            color = Color.White.copy(alpha = 0.6f),
                            fontSize = 10.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
        }
    }

    override fun onClick() {
        // Open the notification's pending intent if available
        notification.notification?.contentIntent?.let { pendingIntent ->
            try {
                pendingIntent.send()
            } catch (e: Exception) {
                // Handle error
            }
        }
    }

    override fun onDestroy() {
        // Clean up if needed
    }

    @Composable
    override fun LeftOpenedComposable() {
        // Show app icon on the left with circular shape and 20% smaller size
        val appIcon = remember {
            try {
                context?.packageManager?.getApplicationIcon(notification.packageName)
            } catch (e: Exception) {
                null
            }
        }
        
        if (appIcon != null) {
            AndroidView(
                factory = { ctx ->
                    android.widget.ImageView(ctx).apply {
                        setImageDrawable(appIcon)
                        scaleType = android.widget.ImageView.ScaleType.CENTER_CROP
                    }
                },
                modifier = Modifier
                    .size(16.dp) // Reduced from 20.dp (20% smaller)
                    .clip(CircleShape) // Make it circular
            )
        } else {
            Icon(
                imageVector = Icons.Default.Notifications,
                contentDescription = "Notification",
                tint = Color.White,
                modifier = Modifier
                    .size(16.dp) // Reduced from 20.dp (20% smaller)
                    .clip(CircleShape) // Make it circular
            )
        }
    }

    @Composable
    override fun RightOpenedComposable() {
        // AI pulse animation using native Android Lottie
        AndroidView(
            factory = { context ->
                LottieAnimationView(context).apply {
                    setAnimation(com.example.uacc.R.raw.ai_pulse)
                    repeatCount = LottieDrawable.INFINITE
                    playAnimation()
                }
            },
            modifier = Modifier.size(16.dp)
        )
    }
}

object PluginManager {
    private val plugins = mutableListOf<BasePlugin>()
    val activePlugins = mutableStateListOf<BasePlugin>()
    private var callTranscriptPlugin: CallTranscriptPlugin? = null
    
    init {
        plugins.add(CallPlugin())  // Add call plugin first (higher priority)
        plugins.add(DemoPlugin())
    }
    
    fun initializePlugins(service: IslandOverlayService) {
        plugins.forEach { plugin ->
            plugin.onCreate(service)
            if (plugin.isActive) {
                addPlugin(plugin)
            }
        }
    }
    
    fun createCallTranscriptPlugin(coroutineScope: CoroutineScope): CallTranscriptPlugin {
        if (callTranscriptPlugin == null) {
            callTranscriptPlugin = CallTranscriptPlugin(coroutineScope)
            plugins.add(callTranscriptPlugin!!)
        }
        return callTranscriptPlugin!!
    }
    
    fun refreshActivePlugins(service: IslandOverlayService) {
        // Clear current active plugins
        activePlugins.clear()
        
        // Re-add active plugins in priority order
        plugins.forEach { plugin ->
            if (plugin.isActive) {
                addPlugin(plugin)
            }
        }
        
        // If no plugins are active, minimize to circle
        if (activePlugins.isEmpty()) {
            service.hideIsland()
        }
    }
    
    fun addPlugin(plugin: BasePlugin) {
        if (!activePlugins.contains(plugin)) {
            // Add to plugins list if it's a dynamic plugin (e.g., NotificationPlugin)
            if (!plugins.contains(plugin)) {
                plugins.add(plugin)
            }
            activePlugins.add(plugin)
        }
    }
    
    fun removePlugin(plugin: BasePlugin) {
        activePlugins.remove(plugin)
        plugins.remove(plugin)
    }
    
    fun removePlugin(pluginId: String) {
        activePlugins.removeAll { it.id == pluginId }
        plugins.removeAll { it.id == pluginId }
    }
    
    fun getFirstActivePlugin(): BasePlugin? {
        return activePlugins.firstOrNull()
    }
    
    fun getCallPlugin(): CallPlugin? {
        return plugins.filterIsInstance<CallPlugin>().firstOrNull()
    }
    
    fun getCallTranscriptPlugin(): CallTranscriptPlugin? {
        return callTranscriptPlugin
    }
}