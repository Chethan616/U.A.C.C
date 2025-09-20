package com.example.uacc

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.util.AttributeSet
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import kotlin.math.max
import kotlin.math.min

class DynamicIslandView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {
    
    companion object {
        private const val TAG = "DynamicIslandView"
        
        // Dimensions in dp
        private const val COMPACT_WIDTH = 120f
        private const val COMPACT_HEIGHT = 35f
        private const val EXPANDED_WIDTH = 320f
        private const val EXPANDED_HEIGHT = 120f
        private const val CORNER_RADIUS = 18f
        
        // Animation durations
        private const val EXPAND_DURATION = 300L
        private const val PULSE_DURATION = 1500L
    }
    
    // State
    private var isExpanded = false
    private var isTranscribing = false
    private var currentTranscript = ""
    
    // UI Components
    private lateinit var backgroundView: View
    private lateinit var transcriptText: TextView
    private lateinit var statusIndicator: View
    
    // Callbacks
    private var onExpandClickListener: (() -> Unit)? = null
    private var onTranscriptUpdateListener: ((String) -> Unit)? = null
    
    // Animation
    private var pulseAnimator: ValueAnimator? = null
    private var expandAnimator: AnimatorSet? = null
    
    // Gesture detection
    private lateinit var gestureDetector: GestureDetector
    
    init {
        setupView()
        setupGestureDetector()
    }
    
    private fun setupView() {
        // Set initial size and properties
        layoutParams = ViewGroup.LayoutParams(
            dpToPx(COMPACT_WIDTH).toInt(),
            dpToPx(COMPACT_HEIGHT).toInt()
        )
        
        // Create background view
        backgroundView = View(context).apply {
            background = createBackgroundDrawable(false)
        }
        addView(backgroundView, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        
        // Create status indicator (pulsing dot)
        statusIndicator = View(context).apply {
            background = createStatusIndicatorDrawable()
            layoutParams = LayoutParams(dpToPx(8f).toInt(), dpToPx(8f).toInt()).apply {
                leftMargin = dpToPx(12f).toInt()
                gravity = android.view.Gravity.CENTER_VERTICAL or android.view.Gravity.START
            }
            visibility = View.GONE
        }
        addView(statusIndicator)
        
        // Create transcript text
        transcriptText = TextView(context).apply {
            textSize = 12f
            setTextColor(Color.WHITE)
            alpha = 0.9f
            maxLines = 3
            ellipsize = android.text.TextUtils.TruncateAt.END
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                leftMargin = dpToPx(12f).toInt()
                rightMargin = dpToPx(12f).toInt()
                topMargin = dpToPx(8f).toInt()
                gravity = android.view.Gravity.CENTER_VERTICAL
            }
            visibility = View.GONE
        }
        addView(transcriptText)
        
        // Set initial state
        setCompactState()
    }
    
    private fun setupGestureDetector() {
        gestureDetector = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
            override fun onSingleTapUp(e: MotionEvent): Boolean {
                toggle()
                onExpandClickListener?.invoke()
                return true
            }
            
            override fun onLongPress(e: MotionEvent) {
                // Long press could trigger additional actions
                super.onLongPress(e)
            }
        })
    }
    
    override fun onTouchEvent(event: MotionEvent): Boolean {
        return gestureDetector.onTouchEvent(event) || super.onTouchEvent(event)
    }
    
    fun toggle() {
        if (isExpanded) {
            collapse()
        } else {
            expand()
        }
    }
    
    fun expand() {
        if (isExpanded) return
        
        isExpanded = true
        animateToExpanded()
    }
    
    fun collapse() {
        if (!isExpanded) return
        
        isExpanded = false
        animateToCompact()
    }
    
    fun updateTranscript(transcript: String) {
        currentTranscript = transcript
        
        post {
            transcriptText.text = if (transcript.isNotEmpty()) {
                transcript
            } else {
                "Listening..."
            }
            
            // Auto-expand if we have content and not already expanded
            if (transcript.isNotEmpty() && !isExpanded) {
                expand()
            }
            
            onTranscriptUpdateListener?.invoke(transcript)
        }
    }
    
    fun clearTranscript() {
        currentTranscript = ""
        post {
            transcriptText.text = ""
            if (isExpanded) {
                collapse()
            }
            stopTranscribingState()
        }
    }
    
    fun startTranscribingState() {
        isTranscribing = true
        post {
            statusIndicator.visibility = View.VISIBLE
            startPulseAnimation()
        }
    }
    
    fun stopTranscribingState() {
        isTranscribing = false
        post {
            statusIndicator.visibility = View.GONE
            stopPulseAnimation()
        }
    }
    
    private fun setCompactState() {
        layoutParams.width = dpToPx(COMPACT_WIDTH).toInt()
        layoutParams.height = dpToPx(COMPACT_HEIGHT).toInt()
        transcriptText.visibility = View.GONE
        backgroundView.background = createBackgroundDrawable(false)
        requestLayout()
    }
    
    private fun setExpandedState() {
        layoutParams.width = dpToPx(EXPANDED_WIDTH).toInt()
        layoutParams.height = dpToPx(EXPANDED_HEIGHT).toInt()
        transcriptText.visibility = View.VISIBLE
        backgroundView.background = createBackgroundDrawable(true)
        requestLayout()
    }
    
    private fun animateToExpanded() {
        expandAnimator?.cancel()
        
        val widthAnimator = ValueAnimator.ofFloat(
            dpToPx(COMPACT_WIDTH),
            dpToPx(EXPANDED_WIDTH)
        ).apply {
            addUpdateListener { animation ->
                layoutParams.width = (animation.animatedValue as Float).toInt()
                requestLayout()
            }
        }
        
        val heightAnimator = ValueAnimator.ofFloat(
            dpToPx(COMPACT_HEIGHT),
            dpToPx(EXPANDED_HEIGHT)
        ).apply {
            addUpdateListener { animation ->
                layoutParams.height = (animation.animatedValue as Float).toInt()
                requestLayout()
            }
        }
        
        val fadeInAnimator = ObjectAnimator.ofFloat(transcriptText, "alpha", 0f, 1f).apply {
            startDelay = EXPAND_DURATION / 2
        }
        
        expandAnimator = AnimatorSet().apply {
            duration = EXPAND_DURATION
            interpolator = android.view.animation.DecelerateInterpolator()
            playTogether(widthAnimator, heightAnimator)
            play(fadeInAnimator).after(startDelay)
            
            start()
        }
        
        post {
            transcriptText.visibility = View.VISIBLE
            backgroundView.background = createBackgroundDrawable(true)
        }
    }
    
    private fun animateToCompact() {
        expandAnimator?.cancel()
        
        val fadeOutAnimator = ObjectAnimator.ofFloat(transcriptText, "alpha", 1f, 0f).apply {
            duration = EXPAND_DURATION / 2
        }
        
        val widthAnimator = ValueAnimator.ofFloat(
            dpToPx(EXPANDED_WIDTH),
            dpToPx(COMPACT_WIDTH)
        ).apply {
            startDelay = EXPAND_DURATION / 2
            addUpdateListener { animation ->
                layoutParams.width = (animation.animatedValue as Float).toInt()
                requestLayout()
            }
        }
        
        val heightAnimator = ValueAnimator.ofFloat(
            dpToPx(EXPANDED_HEIGHT),
            dpToPx(COMPACT_HEIGHT)
        ).apply {
            startDelay = EXPAND_DURATION / 2
            addUpdateListener { animation ->
                layoutParams.height = (animation.animatedValue as Float).toInt()
                requestLayout()
            }
        }
        
        expandAnimator = AnimatorSet().apply {
            duration = EXPAND_DURATION
            interpolator = android.view.animation.AccelerateInterpolator()
            play(fadeOutAnimator)
            play(widthAnimator).after(fadeOutAnimator)
            play(heightAnimator).with(widthAnimator)
            
            start()
        }
        
        postDelayed({
            transcriptText.visibility = View.GONE
            backgroundView.background = createBackgroundDrawable(false)
        }, EXPAND_DURATION / 2)
    }
    
    private fun startPulseAnimation() {
        stopPulseAnimation()
        
        pulseAnimator = ValueAnimator.ofFloat(0.4f, 1f, 0.4f).apply {
            duration = PULSE_DURATION
            repeatCount = ValueAnimator.INFINITE
            repeatMode = ValueAnimator.RESTART
            
            addUpdateListener { animation ->
                statusIndicator.alpha = animation.animatedValue as Float
            }
            
            start()
        }
    }
    
    private fun stopPulseAnimation() {
        pulseAnimator?.cancel()
        pulseAnimator = null
        statusIndicator.alpha = 1f
    }
    
    private fun createBackgroundDrawable(expanded: Boolean): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(CORNER_RADIUS)
            
            // Dynamic Island style gradient
            colors = intArrayOf(
                Color.parseColor("#1C1C1E"), // Dark gray
                Color.parseColor("#2C2C2E")  // Slightly lighter
            )
            gradientType = GradientDrawable.LINEAR_GRADIENT
            orientation = GradientDrawable.Orientation.TOP_BOTTOM
            
            // Add subtle border
            setStroke(1, Color.parseColor("#48484A"))
        }
    }
    
    private fun createStatusIndicatorDrawable(): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor("#FF3B30")) // Red color for recording
        }
    }
    
    private fun dpToPx(dp: Float): Float {
        return dp * context.resources.displayMetrics.density
    }
    
    // Public setters for callbacks
    fun setOnExpandClickListener(listener: () -> Unit) {
        onExpandClickListener = listener
    }
    
    fun setOnTranscriptUpdateListener(listener: (String) -> Unit) {
        onTranscriptUpdateListener = listener
    }
    
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        expandAnimator?.cancel()
        stopPulseAnimation()
    }
}