package com.example.uacc

import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.util.Log

class FloatingTouchListener(
    private val params: WindowManager.LayoutParams,
    private val windowManager: WindowManager
) : View.OnTouchListener {

    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var isDragging = false

    companion object {
        private const val TAG = "FloatingTouchListener"
        private const val CLICK_DRAG_TOLERANCE = 10f // Tolerance for tap vs drag detection
    }

    override fun onTouch(v: View, event: MotionEvent): Boolean {
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                initialX = params.x
                initialY = params.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
                isDragging = false
                return true
            }
            
            MotionEvent.ACTION_MOVE -> {
                val deltaX = event.rawX - initialTouchX
                val deltaY = event.rawY - initialTouchY
                
                // Check if movement is significant enough to be considered dragging
                if (!isDragging && (Math.abs(deltaX) > CLICK_DRAG_TOLERANCE || Math.abs(deltaY) > CLICK_DRAG_TOLERANCE)) {
                    isDragging = true
                }
                
                if (isDragging) {
                    // Update position
                    params.x = initialX - deltaX.toInt()
                    params.y = initialY + deltaY.toInt()
                    
                    try {
                        windowManager.updateViewLayout(v, params)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error updating view layout", e)
                    }
                }
                return true
            }
            
            MotionEvent.ACTION_UP -> {
                if (!isDragging) {
                    // This was a tap, not a drag - handle click
                    handlePillClick(v)
                }
                return true
            }
        }
        return false
    }
    
    private fun handlePillClick(view: View) {
        Log.d(TAG, "Floating pill clicked")
        
        // Here you can add logic to:
        // 1. Open the main app
        // 2. Show an expanded transcript view
        // 3. Toggle pause/resume
        
        // For now, let's try to open the main app
        try {
            val context = view.context
            val packageManager = context.packageManager
            val intent = packageManager.getLaunchIntentForPackage(context.packageName)
            intent?.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TASK)
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening main app", e)
        }
    }
}