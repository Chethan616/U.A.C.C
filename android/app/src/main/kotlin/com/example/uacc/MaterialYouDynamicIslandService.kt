package com.example.uacc

import android.accessibilityservice.AccessibilityService
import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.util.TypedValue
import android.view.*
import android.view.accessibility.AccessibilityEvent
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.OvershootInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.ImageView
import androidx.core.content.ContextCompat
import androidx.interpolator.view.animation.FastOutSlowInInterpolator
import kotlin.math.roundToInt

/**
 * MaterialYou Dynamic Island Service
 * iOS-like Dynamic Island with Material Design 3 theming and fluid animations
 * Positioned in the notch area like a real Dynamic Island
 */
class MaterialYouDynamicIslandService : AccessibilityService() {

    companion object {
        private const val TAG = "MaterialYouDynamicIsland"
        private var instance: MaterialYouDynamicIslandService? = null
        
        fun getInstance(): MaterialYouDynamicIslandService? = instance
    }

    // UI Components
    private lateinit var windowManager: WindowManager
    private var overlayView: FrameLayout? = null
    private var dynamicIsland: FrameLayout? = null
    private var contentContainer: LinearLayout? = null
    private var titleText: TextView? = null
    private var subtitleText: TextView? = null
    private var iconView: ImageView? = null
    
    // Animation & State Management
    private var currentAnimator: AnimatorSet? = null
    private val handler = Handler(Looper.getMainLooper())
    private var currentState = IslandState.CLOSED
    private var isVisible = false
    
    // Island States
    private enum class IslandState {
        CLOSED, OPENED, EXPANDED
    }
    
    // Dimensions - Optimized for notch positioning like original MaterialYou
    private val closedWidth get() = dpToPx(34)
    private val closedHeight get() = dpToPx(34) 
    private val openedWidth get() = dpToPx(170) // Larger width for content
    private val openedHeight get() = dpToPx(34) // Same height as closed
    private val expandedWidth get() = dpToPx(300)
    private val expandedHeight get() = dpToPx(90) // Reduced height for more compact expanded state
    private val notchOffsetY get() = dpToPx(8) // Position in notch area

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        
        Log.d(TAG, "MaterialYou Dynamic Island Service Connected")
        
        // Register screen state receiver for power management
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenStateReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(screenStateReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Receiver not registered", e)
        }
        hideOverlay()
        instance = null
    }

    // Screen state management
    private val screenStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    // Hide island when screen turns off
                    hideOverlay()
                }
                Intent.ACTION_SCREEN_ON -> {
                    // Island will be shown when next content is displayed
                }
            }
        }
    }

    /**
     * Main entry point - Show Dynamic Island with content
     */
    fun show(title: String, subtitle: String? = null, type: String = "default") {
        handler.post {
            if (!isVisible) {
                createOverlay()
                isVisible = true
                animateEntry()
            }
            updateContent(title, subtitle, type)
            animateToOpened()
            
            // Auto-hide after delay
            scheduleAutoHide(5000)
        }
    }

    /**
     * Update island content without state change
     */
    fun update(title: String, subtitle: String? = null, type: String = "default") {
        if (isVisible) {
            handler.post {
                updateContent(title, subtitle, type)
            }
        }
    }

    /**
     * Hide the Dynamic Island
     */
    fun hide() {
        handler.post {
            cancelAutoHide()
            animateExit()
        }
    }

    /**
     * Create the overlay with proper notch positioning
     */
    private fun createOverlay() {
        if (overlayView != null) return

        // Window layout parameters for notch positioning
        val layoutParams = WindowManager.LayoutParams(
            closedWidth,
            closedHeight,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        ).apply {
            // Position in notch area - TOP CENTER
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = notchOffsetY
        }

        // Create island view
        overlayView = createIslandView()
        
        try {
            windowManager.addView(overlayView, layoutParams)
            Log.d(TAG, "Dynamic Island overlay created and positioned")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create overlay", e)
        }
    }

    /**
     * Create the actual Dynamic Island view with Material You styling
     */
    private fun createIslandView(): FrameLayout {
        val container = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        // Main Dynamic Island
        dynamicIsland = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                closedWidth,
                closedHeight,
                Gravity.CENTER
            )
            
            // Material You background with glassmorphism
            background = createMaterialYouBackground()
            elevation = dpToPx(8).toFloat()
            
            // Enable hardware acceleration for smooth animations
            setLayerType(View.LAYER_TYPE_HARDWARE, null)
            
            // Touch handling with haptic feedback
            setOnClickListener {
                performHapticFeedback()
                when (currentState) {
                    IslandState.CLOSED -> animateToOpened()
                    IslandState.OPENED -> animateToExpanded()
                    IslandState.EXPANDED -> animateToOpened()
                }
            }
        }

        // Content container
        contentContainer = LinearLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
        }

        // Icon (dynamic based on content type)
        iconView = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(16), dpToPx(16)).apply {
                marginEnd = dpToPx(6)
            }
            visibility = View.GONE
            scaleType = ImageView.ScaleType.CENTER_INSIDE
        }

        // Title text
        titleText = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
            )
            textSize = 12f
            setTextColor(Color.WHITE)
            maxLines = 1
            gravity = Gravity.CENTER_VERTICAL
            alpha = 0.95f
        }

        // Subtitle text
        subtitleText = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            textSize = 10f
            setTextColor(Color.WHITE)
            alpha = 0.8f
            maxLines = 1
            visibility = View.GONE
        }

        // Build hierarchy
        contentContainer?.apply {
            addView(iconView)
            addView(titleText)
            addView(subtitleText)
        }
        
        dynamicIsland?.addView(contentContainer)
        container.addView(dynamicIsland)
        
        return container
    }

    /**
     * Create Material You background with proper pill shape (100% corner radius)
     */
    private fun createMaterialYouBackground(): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            // Use height/2 for perfect pill shape (100% corner radius)
            cornerRadius = (closedHeight / 2).toFloat()
            
            // Material You dynamic color with glassmorphism
            val backgroundColor = try {
                ContextCompat.getColor(this@MaterialYouDynamicIslandService, android.R.color.system_accent1_600)
            } catch (e: Exception) {
                Color.parseColor("#3F51B5") // Fallback color
            }
            
            setColor(backgroundColor)
            alpha = 240 // 94% opacity for glassmorphism
        }
    }

    /**
     * Update island content and styling based on type
     */
    private fun updateContent(title: String, subtitle: String?, type: String) {
        titleText?.text = title
        
        // Handle subtitle
        if (subtitle.isNullOrEmpty()) {
            subtitleText?.visibility = View.GONE
        } else {
            subtitleText?.text = subtitle
            subtitleText?.visibility = View.VISIBLE
        }
        
        // Update styling based on type
        val backgroundColor = when (type) {
            "call" -> Color.parseColor("#4CAF50") // Green for calls
            "ongoing_call" -> Color.parseColor("#FF9800") // Orange for ongoing
            "notification" -> Color.parseColor("#2196F3") // Blue for notifications
            "music" -> Color.parseColor("#9C27B0") // Purple for music
            else -> try {
                ContextCompat.getColor(this, android.R.color.system_accent1_600)
            } catch (e: Exception) {
                Color.parseColor("#1C1B1F") // Material You surface dark
            }
        }
        
        val iconResId = when (type) {
            "call", "ongoing_call" -> android.R.drawable.ic_menu_call
            "notification" -> android.R.drawable.ic_dialog_info
            "music" -> android.R.drawable.ic_media_play
            else -> android.R.drawable.ic_dialog_info
        }
        
        // Update background - create new gradient drawable with enhanced curvature
        val background = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            val currentHeight = dynamicIsland?.layoutParams?.height ?: closedHeight
            
            // Enhanced curvature for expanded state - more rounded corners
            cornerRadius = when (currentHeight) {
                expandedHeight -> (currentHeight * 0.65f) // 65% corner radius for extra curved expanded state
                else -> (currentHeight / 2).toFloat() // 100% corner radius for pill shape (closed/opened)
            }
            
            setColor(backgroundColor)
            alpha = 240 // Glassmorphism opacity
        }
        dynamicIsland?.background = background
        
        // Update icon
        iconView?.apply {
            setImageResource(iconResId)
            setColorFilter(Color.WHITE)
            visibility = View.VISIBLE
        }
    }

    /**
     * Animate island entry with bounce effect
     */
    private fun animateEntry() {
        dynamicIsland?.apply {
            scaleX = 0.3f
            scaleY = 0.3f
            alpha = 0f
            
            animate()
                .scaleX(1f)
                .scaleY(1f)
                .alpha(1f)
                .setDuration(400)
                .setInterpolator(OvershootInterpolator(1.2f))
                .start()
        }
    }

    /**
     * Animate to opened state with spring physics
     */
    private fun animateToOpened() {
        if (currentState == IslandState.OPENED) return
        
        currentAnimator?.cancel()
        currentState = IslandState.OPENED
        
        dynamicIsland?.let { island ->
            val widthAnimator = createSizeAnimator(island, "width", openedWidth)
            val heightAnimator = createSizeAnimator(island, "height", openedHeight)
            val cornerAnimator = createCornerAnimator(openedHeight) // Pass height for pill shape
            val bounceAnimator = createBounceAnimator(island)
            
            currentAnimator = AnimatorSet().apply {
                playTogether(widthAnimator, heightAnimator, cornerAnimator, bounceAnimator)
                duration = 500
                interpolator = OvershootInterpolator(0.8f)
                start()
            }
        }
        
        scheduleAutoHide(6000)
    }

    /**
     * Animate to expanded state
     */
    private fun animateToExpanded() {
        if (currentState == IslandState.EXPANDED) return
        
        currentAnimator?.cancel()
        currentState = IslandState.EXPANDED
        
        dynamicIsland?.let { island ->
            val widthAnimator = createSizeAnimator(island, "width", expandedWidth)
            val heightAnimator = createSizeAnimator(island, "height", expandedHeight)
            val cornerAnimator = createCornerAnimator(expandedHeight) // Pass height for rounded rect
            val elevationAnimator = createElevationAnimator(island, dpToPx(12).toFloat())
            
            currentAnimator = AnimatorSet().apply {
                playTogether(widthAnimator, heightAnimator, cornerAnimator, elevationAnimator)
                duration = 450
                interpolator = FastOutSlowInInterpolator()
                start()
            }
        }
        
        // Auto-collapse after longer delay
        scheduleAutoHide(10000)
    }

    /**
     * Animate island exit
     */
    private fun animateExit() {
        dynamicIsland?.animate()
            ?.scaleX(0.3f)
            ?.scaleY(0.3f)
            ?.alpha(0f)
            ?.setDuration(300)
            ?.setInterpolator(AccelerateDecelerateInterpolator())
            ?.setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    hideOverlay()
                }
            })
            ?.start()
    }

    /**
     * Create smooth size animator
     */
    private fun createSizeAnimator(view: View, property: String, targetSize: Int): ValueAnimator {
        val currentSize = if (property == "width") view.layoutParams.width else view.layoutParams.height
        return ValueAnimator.ofInt(currentSize, targetSize).apply {
            addUpdateListener { animator ->
                val value = animator.animatedValue as Int
                val params = view.layoutParams
                if (property == "width") params.width = value else params.height = value
                view.layoutParams = params
            }
        }
    }

    /**
     * Create corner radius animator - maintains pill shape
     */
    private fun createCornerAnimator(targetHeight: Int): ValueAnimator {
        val background = dynamicIsland?.background as? GradientDrawable
        val currentHeight = dynamicIsland?.layoutParams?.height ?: closedHeight
        val currentRadius = (currentHeight / 2).toFloat()
        
        // Enhanced curvature for expanded state - more rounded corners
        val targetRadius = when (targetHeight) {
            expandedHeight -> (targetHeight * 0.65f) // 65% corner radius for extra curved expanded state
            else -> (targetHeight / 2).toFloat() // 100% corner radius for pill shape (closed/opened)
        }
        
        return ValueAnimator.ofFloat(currentRadius, targetRadius).apply {
            addUpdateListener { animator ->
                val value = animator.animatedValue as Float
                background?.cornerRadius = value
            }
        }
    }

    /**
     * Create elevation animator
     */
    private fun createElevationAnimator(view: View, targetElevation: Float): ValueAnimator {
        return ValueAnimator.ofFloat(view.elevation, targetElevation).apply {
            addUpdateListener { animator ->
                view.elevation = animator.animatedValue as Float
            }
        }
    }

    /**
     * Create bounce effect animator
     */
    private fun createBounceAnimator(view: View): ObjectAnimator {
        return ObjectAnimator.ofFloat(view, "scaleX", 1f, 1.05f, 1f).apply {
            duration = 200
            repeatCount = 1
        }
    }

    /**
     * Auto-hide scheduling
     */
    private val autoHideRunnable = Runnable { animateExit() }
    
    private fun scheduleAutoHide(delayMs: Long) {
        cancelAutoHide()
        handler.postDelayed(autoHideRunnable, delayMs)
    }
    
    private fun cancelAutoHide() {
        handler.removeCallbacks(autoHideRunnable)
    }

    /**
     * Hide overlay and clean up
     */
    private fun hideOverlay() {
        try {
            overlayView?.let { view ->
                windowManager.removeView(view)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error removing overlay", e)
        }
        
        overlayView = null
        dynamicIsland = null
        contentContainer = null
        titleText = null
        subtitleText = null
        iconView = null
        isVisible = false
        currentState = IslandState.CLOSED
    }

    /**
     * Haptic feedback
     */
    private fun performHapticFeedback() {
        try {
            dynamicIsland?.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
        } catch (e: Exception) {
            // Haptic feedback not available
        }
    }

    /**
     * Convert dp to pixels
     */
    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            resources.displayMetrics
        ).roundToInt()
    }

    // Demo and convenience methods
    fun showIncomingCall(callerName: String, phoneNumber: String) {
        show("📞 $callerName", phoneNumber, "call")
    }

    fun showOngoingCall(callerName: String, duration: String) {
        show("📞 $callerName", "⏱️ $duration", "ongoing_call")
    }

    fun showNotification(appName: String, content: String) {
        show(appName, content, "notification")
    }

    fun showMusic(title: String, artist: String) {
        show("🎵 $title", "by $artist", "music")
    }

    /**
     * Run comprehensive demo sequence
     */
    fun runDemo() {
        handler.post {
            show("Welcome!", "MaterialYou Dynamic Island")
        }
        
        handler.postDelayed({
            showIncomingCall("John Doe", "+1 234 567 8900")
        }, 2500)
        
        handler.postDelayed({
            showOngoingCall("John Doe", "02:34")
        }, 6000)
        
        handler.postDelayed({
            showMusic("Bohemian Rhapsody", "Queen")
        }, 10000)
        
        handler.postDelayed({
            showNotification("Messages", "New message from Alice")
        }, 14000)
        
        handler.postDelayed({
            hide()
        }, 18000)
    }

    // Accessibility service implementation
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}