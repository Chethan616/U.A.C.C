package com.example.uacc.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.RadialGradient
import android.os.Build
import android.util.Log
import androidx.annotation.ColorInt
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.core.app.AlarmManagerCompat
import androidx.core.graphics.ColorUtils
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext

import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.currentState
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.background
import com.example.uacc.R
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.TextStyle as JavaTextStyle
import java.util.Locale
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.launch

/**
 * Material You expressive calendar widget with a 12-sided "cookie" illustration and
 * a squiggly progress indicator representing the current time of day.
 */
class CookieCalendarWidget : GlanceAppWidget() {

    override val stateDefinition = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<Preferences>()
            val day = prefs[PrefKeys.day] ?: LocalDate.now().dayOfMonth
            val month = prefs[PrefKeys.monthName]
                ?: LocalDate.now().month.getDisplayName(JavaTextStyle.SHORT, Locale.getDefault())
            val year = prefs[PrefKeys.year] ?: LocalDate.now().year
            val progress = prefs[PrefKeys.progress]?.coerceIn(0f, 1f) ?: 0f

            CookieCalendarWidgetContent(
                day = day,
                month = month,
                year = year,
                progress = progress,
                cookieColor = PRESET_COOKIE_COLOR,
                cookieTextColor = PRESET_COOKIE_TEXT_COLOR,
                progressTrackColor = PRESET_TRACK_COLOR_LIGHT,
                progressWaveColor = PRESET_ACCENT_GREEN
            )
        }
    }

    @Composable
    private fun CookieCalendarWidgetContent(
        day: Int,
        month: String,
        year: Int,
        progress: Float,
        cookieColor: Color,
        cookieTextColor: Color,
        progressTrackColor: Color,
        progressWaveColor: Color,
    ) {
        val context = LocalContext.current
        val configuration = context.resources.configuration
            val isDarkTheme = (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

        val resolvedCookieColor = cookieColor
        val resolvedProgressWaveColor = progressWaveColor
        val resolvedProgressTrackColor = if (isDarkTheme) PRESET_TRACK_COLOR_DARK else progressTrackColor
            val resolvedCookieTextColor = if (isDarkTheme) Color(0xFFB9FBC0) else Color.White

        val renderResult = runCatching {
            renderCookieCalendarBitmap(
                context = context,
                day = day,
                month = month,
                year = year,
                progress = progress,
                cookieColor = resolvedCookieColor.toArgb(),
                cookieTextColor = resolvedCookieTextColor.toArgb(),
                progressTrackColor = resolvedProgressTrackColor.toArgb(),
                progressWaveColor = resolvedProgressWaveColor.toArgb(),
            )
        }

        val bitmap = renderResult.getOrNull()
        if (bitmap == null) {
            renderResult.exceptionOrNull()?.let { throwable ->
                Log.e(TAG, "Failed to render cookie calendar widget", throwable)
            }

            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(Color(0xFF121212))),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Widget unavailable",
                    style = TextStyle(color = ColorProvider(Color(0xFF1C1B1F)))
                )
                Spacer(modifier = GlanceModifier.height(R.dimen.cookie_widget_spacing_medium))
                Text(
                    text = "Tap to refresh from the app",
                    style = TextStyle(color = ColorProvider(Color(0xFF625B71)))
                )
            }
            return
        }

        // Material 3 Expressive Container with dynamic shapes
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Image(
                provider = ImageProvider(bitmap),
                contentDescription = "Material 3 Expressive Cookie Calendar",
                modifier = GlanceModifier
            )
        }
    }

    private fun renderCookieCalendarBitmap(
        context: Context,
        day: Int,
        month: String,
        year: Int,
        progress: Float,
        @ColorInt cookieColor: Int,
        @ColorInt cookieTextColor: Int,
        @ColorInt progressTrackColor: Int,
        @ColorInt progressWaveColor: Int,
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val sizeDp = 180f
        val sizePx = (sizeDp * density).toInt()
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val centerX = sizePx / 2f
        val centerY = sizePx / 2f
        val outerRadius = sizePx * 0.40f
        val innerRadius = outerRadius * 0.75f
        val sides = 12

        // Enhanced cookie with gradient effect
        val cookiePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = cookieColor
            setShadowLayer(14f, 0f, 6f, ColorUtils.setAlphaComponent(android.graphics.Color.BLACK, 120))
        }
        cookiePaint.shader = LinearGradient(
            centerX - outerRadius,
            centerY - outerRadius,
            centerX + outerRadius,
            centerY + outerRadius,
            ColorUtils.blendARGB(cookieColor, android.graphics.Color.BLACK, 0.65f),
            ColorUtils.blendARGB(cookieColor, android.graphics.Color.BLACK, 0.35f),
            Shader.TileMode.CLAMP
        )

        // Material 3 expressive shape - use rounded rectangle with dynamic corner variations
        val cookiePath = Path()

        // Expressive widget container inspired by the catalog's floating toolbar curvature
        val maxCornerRadius = outerRadius
        val shapeRadii = floatArrayOf(
            (outerRadius * 0.92f).coerceAtMost(maxCornerRadius), (outerRadius * 0.92f).coerceAtMost(maxCornerRadius), // Top-left
            (outerRadius * 0.50f).coerceAtMost(maxCornerRadius), (outerRadius * 0.50f).coerceAtMost(maxCornerRadius), // Top-right
            (outerRadius * 0.82f).coerceAtMost(maxCornerRadius), (outerRadius * 0.82f).coerceAtMost(maxCornerRadius), // Bottom-right
            (outerRadius * 0.42f).coerceAtMost(maxCornerRadius), (outerRadius * 0.42f).coerceAtMost(maxCornerRadius), // Bottom-left
        )

        val rect = RectF(
            centerX - outerRadius,
            centerY - outerRadius, 
            centerX + outerRadius,
            centerY + outerRadius
        )

        // Create expressive rounded rect path
        cookiePath.addRoundRect(rect, shapeRadii, Path.Direction.CW)
        cookiePath.close()
        canvas.drawPath(cookiePath, cookiePaint)

        val highlightStartColor = ColorUtils.setAlphaComponent(android.graphics.Color.BLACK, 150)
        val highlightEndColor = ColorUtils.setAlphaComponent(cookieColor, 0)
        val highlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            shader = RadialGradient(
                centerX - outerRadius * 0.25f,
                centerY - outerRadius * 0.35f,
                outerRadius,
                intArrayOf(highlightStartColor, highlightEndColor),
                floatArrayOf(0f, 1f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(cookiePath, highlightPaint)

        val rimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = outerRadius * 0.12f
            color = ColorUtils.blendARGB(android.graphics.Color.BLACK, android.graphics.Color.BLACK, 0.25f)
            alpha = 140
        }
        canvas.drawPath(cookiePath, rimPaint)

        // Material 3 typography for day number
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = cookieTextColor
            textAlign = Paint.Align.CENTER
            textSize = sizePx * 0.35f
            typeface = android.graphics.Typeface.create("google-sans", android.graphics.Typeface.BOLD)
            letterSpacing = 0.01f
        }
        canvas.drawText(day.coerceIn(1, 31).toString(), centerX, centerY + textPaint.textSize / 3f, textPaint)

        // Subtle month indicator with Material 3 styling
        val monthPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ColorUtils.setAlphaComponent(cookieTextColor, 220)
            textAlign = Paint.Align.CENTER
            textSize = sizePx * 0.11f
            typeface = android.graphics.Typeface.create("google-sans", android.graphics.Typeface.NORMAL)
            alpha = 180
            letterSpacing = 0.05f
        }
        canvas.drawText(month.take(3).uppercase(), centerX, centerY + outerRadius * 0.65f, monthPaint)

        // Expressive clock markers
        val nowTime = LocalTime.now()
        val markerPalette = intArrayOf(
            0xFF333333.toInt(),
            0xFF555555.toInt(),
            0xFF777777.toInt(),
            0xFF999999.toInt()
        )
        val markerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }
        val markerHighlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            alpha = 210
        }
        val markerRadius = innerRadius * 0.92f
        val markerLength = outerRadius * 0.12f
        val markerWidth = outerRadius * 0.06f
        for (i in 0 until 12) {
            val angleDeg = i * 30f - 90f
            val angleRad = Math.toRadians(angleDeg.toDouble())
            val cosAngle = cos(angleRad).toFloat()
            val sinAngle = sin(angleRad).toFloat()
            val innerX = centerX + (markerRadius - markerLength) * cosAngle
            val innerY = centerY + (markerRadius - markerLength) * sinAngle
            val outerX = centerX + markerRadius * cosAngle
            val outerY = centerY + markerRadius * sinAngle

            markerPaint.color = markerPalette[i % markerPalette.size]
            markerPaint.setShadowLayer(6f, 0f, 2f, android.graphics.Color.argb(70, 0, 0, 0))

            canvas.save()
            canvas.translate(innerX, innerY)
            canvas.rotate(angleDeg)
            val rect = RectF(0f, -markerWidth / 2f, markerLength, markerWidth / 2f)
            canvas.drawRoundRect(rect, markerWidth / 2f, markerWidth / 2f, markerPaint)

            markerHighlightPaint.color = blendTowardColor(markerPaint.color, android.graphics.Color.WHITE, 0.65f)
            canvas.drawCircle(markerLength * 0.75f, -markerWidth * 0.15f, markerWidth * 0.30f, markerHighlightPaint)
            canvas.restore()

            val tickPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = blendTowardColor(markerPaint.color, android.graphics.Color.BLACK, 0.25f)
                style = Paint.Style.STROKE
                strokeWidth = outerRadius * 0.015f
                strokeCap = Paint.Cap.ROUND
                alpha = if (i % 3 == 0) 180 else 120
            }
            canvas.drawLine(innerX, innerY, outerX, outerY, tickPaint)
        }

        // Clock hands
    val hourAngle = ((nowTime.hour % 12) + nowTime.minute / 60f) * 30f - 90f
    val minuteAngle = (nowTime.minute + nowTime.second / 60f) * 6f - 90f

        val hourHandPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFF777777.toInt()
            style = Paint.Style.STROKE
            strokeWidth = outerRadius * 0.08f
            strokeCap = Paint.Cap.ROUND
            setShadowLayer(
                outerRadius * 0.09f,
                outerRadius * 0.02f,
                outerRadius * 0.02f,
                ColorUtils.setAlphaComponent(0xFF777777.toInt(), 90)
            )
        }
        val minuteHandPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFF999999.toInt()
            style = Paint.Style.STROKE
            strokeWidth = outerRadius * 0.05f
            strokeCap = Paint.Cap.ROUND
            setShadowLayer(
                outerRadius * 0.07f,
                outerRadius * 0.015f,
                outerRadius * 0.015f,
                ColorUtils.setAlphaComponent(0xFF999999.toInt(), 70)
            )
        }
        val minuteHighlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = outerRadius * 0.018f
            strokeCap = Paint.Cap.ROUND
            alpha = 175
        }

        fun drawHand(angleDeg: Float, length: Float, paint: Paint) {
            val angleRad = Math.toRadians(angleDeg.toDouble())
            val cosAngle = cos(angleRad).toFloat()
            val sinAngle = sin(angleRad).toFloat()
            val endX = centerX + length * cosAngle
            val endY = centerY + length * sinAngle
            canvas.drawLine(centerX, centerY, endX, endY, paint)
        }

        drawHand(hourAngle, innerRadius * 0.65f, hourHandPaint)
    drawHand(minuteAngle, innerRadius * 0.88f, minuteHandPaint)
    drawHand(minuteAngle, innerRadius * 0.72f, minuteHighlightPaint)

        val centerCapPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.WHITE
            style = Paint.Style.FILL
            setShadowLayer(6f, 1f, 1f, android.graphics.Color.argb(80, 0, 0, 0))
        }
        canvas.drawCircle(centerX, centerY, outerRadius * 0.10f, centerCapPaint)

        // Material 3 SimWave progress rail inspired by the expressive catalog
    val waveWidth = sizePx * 0.90f
    val waveHeight = sizePx * 0.06f
        val waveLeft = centerX - waveWidth / 2f
        val waveTop = centerY + outerRadius * 0.85f
        val waveCenterY = waveTop + waveHeight / 2f

        val normalizedProgress = progress.coerceIn(0f, 1f)
    val waveCycles = 7.5f

        // Enhanced background wave track with expressive styling
        val trackWavePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = progressTrackColor
            style = Paint.Style.STROKE
            strokeWidth = waveHeight * 0.5f
            strokeCap = Paint.Cap.ROUND
            alpha = 100
            pathEffect = android.graphics.CornerPathEffect(4f)
        }

        val trackWavePath = Path()
        val trackSamples = 160
        val trackAmplitude = waveHeight * 0.32f

        for (i in 0..trackSamples) {
            val t = i.toFloat() / trackSamples
            val x = waveLeft + waveWidth * t
            val y = calculateSineWaveY(
                normalizedPosition = t,
                centerY = waveCenterY,
                amplitude = trackAmplitude,
                cycles = waveCycles,
                phaseShift = 0f
            )
            if (i == 0) trackWavePath.moveTo(x, y) else trackWavePath.lineTo(x, y)
        }
        canvas.drawPath(trackWavePath, trackWavePaint)

        val shimmerGradient = LinearGradient(
            waveLeft,
            waveCenterY,
            waveLeft + waveWidth,
            waveCenterY,
            intArrayOf(
                blendTowardColor(progressTrackColor, cookieColor, 0.28f),
                progressTrackColor,
                blendTowardColor(progressTrackColor, cookieColor, 0.28f)
            ),
            floatArrayOf(0f, 0.5f, 1f),
            Shader.TileMode.CLAMP
        )
        val trackGlowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = waveHeight
            strokeCap = Paint.Cap.ROUND
            shader = shimmerGradient
            alpha = 70
        }
        canvas.drawPath(trackWavePath, trackGlowPaint)

        val basePhaseShift = (PI / 10f).toFloat()
        val trailingWavePath = Path()
        val trailingAmplitude = waveHeight * 0.5f
        for (i in 0..trackSamples) {
            val t = i.toFloat() / trackSamples
            val x = waveLeft + waveWidth * t
            val y = calculateSineWaveY(
                normalizedPosition = t,
                centerY = waveCenterY,
                amplitude = trailingAmplitude,
                cycles = waveCycles,
                phaseShift = -basePhaseShift * 1.6f
            )
            if (i == 0) trailingWavePath.moveTo(x, y) else trailingWavePath.lineTo(x, y)
        }
        val trailingPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = blendTowardColor(progressWaveColor, android.graphics.Color.WHITE, 0.5f)
            style = Paint.Style.STROKE
            strokeWidth = waveHeight * 0.55f
            strokeCap = Paint.Cap.ROUND
            alpha = 60
        }
        canvas.drawPath(trailingWavePath, trailingPaint)

        // Material 3 expressive progress wave (animated portion)
        val progressWidth = waveWidth * normalizedProgress
        if (progressWidth > waveHeight * 0.6f) {
            val progressWavePath = Path()
            val progressSamples = (trackSamples * normalizedProgress).toInt().coerceAtLeast(6)
            val progressAmplitude = waveHeight * 0.45f

            for (i in 0..progressSamples) {
                val fraction = if (progressSamples == 0) 0f else i.toFloat() / progressSamples
                val position = normalizedProgress * fraction
                val x = waveLeft + waveWidth * position
                val y = calculateSineWaveY(
                    normalizedPosition = position,
                    centerY = waveCenterY,
                    amplitude = progressAmplitude,
                    cycles = waveCycles,
                    phaseShift = basePhaseShift
                )
                if (i == 0) progressWavePath.moveTo(x, y) else progressWavePath.lineTo(x, y)
            }

            val waveStartColor = cookieTextColor
            val waveEndColor = ColorUtils.blendARGB(cookieTextColor, android.graphics.Color.BLACK, 0.5f)

            val progressWavePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = progressWaveColor
                style = Paint.Style.STROKE
                strokeWidth = waveHeight * 0.72f
                strokeCap = Paint.Cap.ROUND
                pathEffect = android.graphics.CornerPathEffect(6f)
                shader = LinearGradient(
                    waveLeft,
                    waveCenterY - progressAmplitude,
                    waveLeft + progressWidth,
                    waveCenterY + progressAmplitude,
                    intArrayOf(waveStartColor, waveEndColor),
                    floatArrayOf(0f, 1f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawPath(progressWavePath, progressWavePaint)

            val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = ColorUtils.setAlphaComponent(0xFF555555.toInt(), 110)
                style = Paint.Style.STROKE
                strokeWidth = waveHeight * 1.05f
                strokeCap = Paint.Cap.ROUND
                alpha = 160
                pathEffect = android.graphics.CornerPathEffect(9f)
            }
            canvas.drawPath(progressWavePath, glowPaint)

            if (normalizedProgress > 0.05f) {
                val endX = waveLeft + waveWidth * normalizedProgress
                val endY = calculateSineWaveY(
                    normalizedPosition = normalizedProgress,
                    centerY = waveCenterY,
                    amplitude = progressAmplitude,
                    cycles = waveCycles,
                    phaseShift = basePhaseShift
                )

                val indicatorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = 0xFF777777.toInt()
                    style = Paint.Style.FILL
                    setShadowLayer(6f, 1f, 1f, android.graphics.Color.argb(60, 0, 0, 0))
                }

                val indicatorRadius = waveHeight * 0.36f
                canvas.drawCircle(endX, endY, indicatorRadius, indicatorPaint)

                val highlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = android.graphics.Color.WHITE
                    style = Paint.Style.FILL
                    alpha = 140
                }
                canvas.drawCircle(
                    endX - indicatorRadius * 0.18f,
                    endY - indicatorRadius * 0.22f,
                    indicatorRadius * 0.42f,
                    highlightPaint,
                )
            }
        }

        return bitmap
    }

    object PrefKeys {
        val day = intPreferencesKey("cookie_calendar_day")
        val monthName = stringPreferencesKey("cookie_calendar_month")
        val year = intPreferencesKey("cookie_calendar_year")
        val progress = floatPreferencesKey("cookie_calendar_progress")
    }

    companion object {
        // Material 3 Dynamic Color tokens
    private val PRESET_COOKIE_COLOR = Color(0xFF121212)        // AMOLED near-black
    private val PRESET_COOKIE_TEXT_COLOR = Color(0xFFB9FBC0)   // Neon mint-green
    private val PRESET_TRACK_COLOR_LIGHT = Color(0xFF333333)   // Dark gray
    private val PRESET_TRACK_COLOR_DARK = Color(0xFF1B2E45)    // Deep navy for contrast
    private val PRESET_ACCENT_GREEN = Color(0xFF555555)        // Medium gray
    private val PRESET_ACCENT_PINK = Color(0xFF777777)         // Light gray
    private val PRESET_ACCENT_YELLOW = Color(0xFF999999)       // Lighter gray

    private const val TAG = "CookieCalendarWidget"
        
        // Material 3 Expressive Shapes Constants
        object MaterialExpressiveShapes {
            const val LARGE_CONTAINER = 28f           // Large container radius
            const val COOKIE_CONTAINER = 24f          // Cookie shape radius
            const val SMALL_CONTAINER = 16f           // Small elements
            const val CONTAINER_PADDING = 16f         // Standard padding
            const val INNER_PADDING = 12f             // Inner container padding
            const val SPACER_HEIGHT = 12f             // Standard spacer
            const val SMALL_SPACER = 6f               // Small spacer
            const val PROGRESS_HEIGHT = 6f            // Progress bar height
            const val TEXT_PADDING = 8f               // Text padding
        }


        suspend fun updateWidget(
            context: Context,
            day: Int,
            monthName: String,
            year: Int,
            progress: Float,
        ) {
            val manager = GlanceAppWidgetManager(context)
            val widget = CookieCalendarWidget()
            val ids = manager.getGlanceIds(CookieCalendarWidget::class.java)
            ids.forEach { glanceId ->
                updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                    prefs.toMutablePreferences().apply {
                        this[PrefKeys.day] = day
                        this[PrefKeys.monthName] = monthName
                        this[PrefKeys.year] = year
                        this[PrefKeys.progress] = progress.coerceIn(0f, 1f)
                    }
                }
                widget.update(context, glanceId)
            }
            CookieClockRealtimeUpdater.ensureRunning(context)
        }

        suspend fun clear(context: Context) {
            val manager = GlanceAppWidgetManager(context)
            val widget = CookieCalendarWidget()
            val ids = manager.getGlanceIds(CookieCalendarWidget::class.java)
            ids.forEach { glanceId ->
                updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
                    prefs.toMutablePreferences().apply { clear() }
                }
                widget.update(context, glanceId)
            }
        }

        internal suspend fun refreshAllWidgets(context: Context): Boolean {
            val manager = GlanceAppWidgetManager(context)
            val ids = manager.getGlanceIds(CookieCalendarWidget::class.java)
            if (ids.isEmpty()) {
                return false
            }
            val widget = CookieCalendarWidget()
            ids.forEach { glanceId ->
                widget.update(context, glanceId)
            }
            return true
        }
    }
}

class CookieCalendarWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CookieCalendarWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        CookieClockRealtimeUpdater.ensureRunning(context)
    }

    override fun onDisabled(context: Context) {
        CookieClockRealtimeUpdater.stop(context)
        super.onDisabled(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        CookieClockRealtimeUpdater.ensureRunning(context)
    }
}

class CookieWidgetAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        val appContext = context.applicationContext
        when (action) {
            CookieClockRealtimeUpdater.intentAction() -> CookieClockRealtimeUpdater.handleAlarm(appContext)
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> CookieClockRealtimeUpdater.ensureRunning(appContext)
        }
    }
}

private object CookieClockRealtimeUpdater {
    private const val ACTION_COOKIE_WIDGET_ALARM = "com.example.uacc.widgets.ACTION_COOKIE_WIDGET_ALARM"
    private const val REQUEST_CODE_COOKIE_ALARM = 8231

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    @Volatile
    private var isScheduled = false

    fun ensureRunning(context: Context) {
        val appContext = context.applicationContext
        val existing = createPendingIntent(appContext, PendingIntent.FLAG_NO_CREATE)
        if (existing == null) {
            scheduleNext(appContext)
        } else {
            isScheduled = true
        }
    }

    fun handleAlarm(context: Context) {
        val appContext = context.applicationContext
        scope.launch {
            val hasWidgets = runCatching {
                CookieCalendarWidget.refreshAllWidgets(appContext)
            }.onFailure {
                Log.w("CookieCalendarWidget", "Cookie widget refresh via alarm failed", it)
            }.getOrDefault(false)

            if (hasWidgets) {
                scheduleNext(appContext)
            } else {
                stop(appContext)
            }
        }
    }

    fun stop(context: Context) {
        cancelAlarm(context.applicationContext)
        scope.coroutineContext.cancelChildren()
        isScheduled = false
    }

    private fun scheduleNext(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
    val pendingIntent = createPendingIntent(context, PendingIntent.FLAG_UPDATE_CURRENT) ?: return
        val triggerAtMillis = System.currentTimeMillis() + millisUntilNextMinute()
        AlarmManagerCompat.setExactAndAllowWhileIdle(
            alarmManager,
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent
        )
        isScheduled = true
    }

    private fun cancelAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
    val existing = createPendingIntent(context, PendingIntent.FLAG_NO_CREATE)
        if (existing != null) {
            alarmManager.cancel(existing)
            existing.cancel()
        }
    }

    private fun createPendingIntent(context: Context, baseFlags: Int): PendingIntent? {
        val flags = baseFlags or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val intent = Intent(context, CookieWidgetAlarmReceiver::class.java).apply {
            action = ACTION_COOKIE_WIDGET_ALARM
        }
        return PendingIntent.getBroadcast(context, REQUEST_CODE_COOKIE_ALARM, intent, flags)
    }

    private fun millisUntilNextMinute(): Long {
        val now = System.currentTimeMillis()
        val remainder = now % 60_000L
        return if (remainder == 0L) 60_000L else 60_000L - remainder
    }

    fun intentAction(): String = ACTION_COOKIE_WIDGET_ALARM
}

private fun calculateSineWaveY(
    normalizedPosition: Float,
    centerY: Float,
    amplitude: Float,
    cycles: Float,
    phaseShift: Float,
): Float {
    val angle = (2 * PI * cycles * normalizedPosition) + phaseShift
    return centerY + amplitude * sin(angle).toFloat()
}

private fun blendTowardColor(@ColorInt color: Int, @ColorInt target: Int, ratio: Float): Int {
    return ColorUtils.blendARGB(color, target, ratio.coerceIn(0f, 1f))
}

