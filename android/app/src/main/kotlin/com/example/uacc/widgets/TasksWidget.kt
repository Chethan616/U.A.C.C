package com.example.uacc.widgets

import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.util.Log
import androidx.annotation.ColorInt
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.core.graphics.ColorUtils
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
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
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.example.uacc.R
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

class TasksWidget : GlanceAppWidget() {

	override val stateDefinition = PreferencesGlanceStateDefinition

	override suspend fun provideGlance(context: Context, id: GlanceId) {
			provideContent {
				val preferences = currentState<Preferences>()
				val rawTasksJson = preferences[PrefKeys.tasksJson]
				val decodedTasks = decodeTasks(rawTasksJson)
				val taskEntries = if (decodedTasks.isEmpty() && rawTasksJson.isNullOrBlank()) {
					TaskWidgetDefaults.sampleTasks()
				} else {
					decodedTasks
				}

			val totalTasks = preferences[PrefKeys.totalTasks] ?: taskEntries.size
			val completedTasks = preferences[PrefKeys.completedTasks]
				?: taskEntries.count { it.isCompleted }
			val overdueTasks = preferences[PrefKeys.overdueTasks] ?: 0
			val todayTasks = preferences[PrefKeys.todayTasks] ?: 0
			val header = preferences[PrefKeys.heroHeader]?.takeIf { it.isNotBlank() }
				?: TaskWidgetDefaults.DEFAULT_HEADER
			val accentColor = preferences[PrefKeys.accentColor]
				?: TaskWidgetDefaults.DEFAULT_ACCENT
			val secondaryAccent = preferences[PrefKeys.secondaryAccent]
				?: TaskWidgetDefaults.DEFAULT_SECONDARY
			val lastUpdated = preferences[PrefKeys.lastUpdatedEpochMillis]

			TasksWidgetContent(
				header = header,
				tasks = taskEntries,
				summary = TaskSummary(
					total = totalTasks,
					completed = completedTasks,
					overdue = overdueTasks,
					today = todayTasks,
					lastUpdatedEpochMillis = lastUpdated
				),
				accentColor = Color(accentColor),
				secondaryAccent = Color(secondaryAccent)
			)
		}
	}

	@Composable
	private fun TasksWidgetContent(
		header: String,
		tasks: List<TaskEntry>,
		summary: TaskSummary,
		accentColor: Color,
		secondaryAccent: Color,
	) {
		val context = LocalContext.current
		val configuration = context.resources.configuration
		val isDarkTheme = (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

		val renderResult = runCatching {
			renderTasksBitmap(
				context = context,
				header = header,
				tasks = tasks.take(TaskWidgetDefaults.MAX_VISIBLE_TASKS),
				summary = summary,
				accentColor = accentColor.toArgb(),
				secondaryAccent = secondaryAccent.toArgb(),
				isDarkTheme = isDarkTheme
			)
		}

		val bitmap = renderResult.getOrNull()
		if (bitmap == null) {
			renderResult.exceptionOrNull()?.let { throwable ->
				Log.e(TaskWidgetDefaults.TAG, "Failed to render tasks widget", throwable)
			}

			Column(
				modifier = GlanceModifier.fillMaxSize(),
				horizontalAlignment = Alignment.CenterHorizontally,
				verticalAlignment = Alignment.CenterVertically
			) {
				Text(
					text = "Tasks widget unavailable",
					style = TextStyle(color = ColorProvider(Color(0xFF1C1B1F)))
				)
				Spacer(modifier = GlanceModifier.height(R.dimen.cookie_widget_spacing_medium))
				Text(
					text = "Open Cairo to sync tasks",
					style = TextStyle(color = ColorProvider(Color(0xFF49454F)))
				)
			}
			return
		}

		Column(
			modifier = GlanceModifier.fillMaxSize(),
			horizontalAlignment = Alignment.CenterHorizontally,
			verticalAlignment = Alignment.CenterVertically
		) {
			Image(
				provider = ImageProvider(bitmap),
				contentDescription = "Material You Expressive Tasks",
				modifier = GlanceModifier
			)
		}
	}

	private fun renderTasksBitmap(
		context: Context,
		header: String,
		tasks: List<TaskEntry>,
		summary: TaskSummary,
		@ColorInt accentColor: Int,
		@ColorInt secondaryAccent: Int,
		isDarkTheme: Boolean,
	): Bitmap {
		val density = context.resources.displayMetrics.density
		val widthDp = 228f
		val heightDp = 172f
		val widthPx = (widthDp * density).toInt()
		val heightPx = (heightDp * density).toInt()
		val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
		val canvas = Canvas(bitmap)

		val backgroundColor = 0xFF121212.toInt()
		canvas.drawColor(backgroundColor)

		val padding = widthPx * 0.055f
		val cardRect = RectF(
			padding,
			padding * 0.6f,
			widthPx - padding,
			heightPx - padding * 0.75f
		)

		val containerPath = buildAuroraTicketPath(cardRect)

		val baseGradient = LinearGradient(
			cardRect.left,
			cardRect.top,
			cardRect.right,
			cardRect.bottom,
			intArrayOf(
				ColorUtils.setAlphaComponent(0xFF333333.toInt(), 240),
				ColorUtils.blendARGB(0xFF333333.toInt(), 0xFF121212.toInt(), 0.25f),
				ColorUtils.blendARGB(0xFF555555.toInt(), 0xFF121212.toInt(), 0.45f)
			),
			floatArrayOf(0f, 0.6f, 1f),
			Shader.TileMode.CLAMP
		)

		val containerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			style = Paint.Style.FILL
			shader = baseGradient
		}
		canvas.drawPath(containerPath, containerPaint)

		val irisHighlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			shader = RadialGradient(
				cardRect.centerX(),
				cardRect.top + cardRect.height() * 0.18f,
				cardRect.width() * 0.85f,
				ColorUtils.setAlphaComponent(ColorUtils.blendARGB(0xFF555555.toInt(), 0xFF777777.toInt(), 0.45f), 170),
				ColorUtils.setAlphaComponent(0xFF333333.toInt(), 0),
				Shader.TileMode.CLAMP
			)
		}
		canvas.drawPath(containerPath, irisHighlightPaint)

		val overlayCut = Path().apply {
			moveTo(cardRect.right - cardRect.width() * 0.28f, cardRect.top - cardRect.height() * 0.12f)
			quadTo(
				cardRect.right + cardRect.width() * 0.04f,
				cardRect.top + cardRect.height() * 0.08f,
				cardRect.right - cardRect.width() * 0.04f,
				cardRect.top + cardRect.height() * 0.34f
			)
			lineTo(cardRect.right - cardRect.width() * 0.18f, cardRect.top + cardRect.height() * 0.46f)
			quadTo(
				cardRect.right - cardRect.width() * 0.32f,
				cardRect.top + cardRect.height() * 0.28f,
				cardRect.right - cardRect.width() * 0.42f,
				cardRect.top + cardRect.height() * 0.14f
			)
			close()
		}
		val overlayPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			style = Paint.Style.FILL
			shader = LinearGradient(
				cardRect.right,
				cardRect.top,
				cardRect.centerX(),
				cardRect.centerY(),
				ColorUtils.setAlphaComponent(ColorUtils.blendARGB(0xFF777777.toInt(), 0xFF555555.toInt(), 0.2f), 155),
				ColorUtils.setAlphaComponent(0xFF777777.toInt(), 0),
				Shader.TileMode.CLAMP
			)
		}
		canvas.drawPath(overlayCut, overlayPaint)

		val accentStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			style = Paint.Style.STROKE
			strokeWidth = cardRect.width() * 0.012f
			color = ColorUtils.setAlphaComponent(ColorUtils.blendARGB(0xFF555555.toInt(), 0xFFFFFFFF.toInt(), 0.65f), 180)
		}
		canvas.drawPath(containerPath, accentStrokePaint)

		drawAuroraOrbits(canvas, cardRect, secondaryAccent)

		val contentPadding = cardRect.width() * 0.08f
		val textLeft = cardRect.left + contentPadding

		val headerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			color = ColorUtils.setAlphaComponent(0xFFFFFFFF.toInt(), 235)
			textSize = cardRect.height() * 0.16f
			typeface = Typeface.create("google-sans", Typeface.BOLD)
		}
		val headerBaseline = cardRect.top + contentPadding + headerPaint.textSize
		canvas.drawText(header, textLeft, headerBaseline, headerPaint)

		val sublinePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			color = ColorUtils.setAlphaComponent(0xFFFFFFFF.toInt(), 210)
			textSize = cardRect.height() * 0.09f
			typeface = Typeface.create("google-sans", Typeface.NORMAL)
			letterSpacing = 0.05f
		}

		val summaryLine = buildSummaryLine(summary)
		val sublineBaseline = headerBaseline + sublinePaint.textSize * 1.4f
		canvas.drawText(summaryLine, textLeft, sublineBaseline, sublinePaint)

		summary.lastUpdatedEpochMillis?.let { timestamp ->
			val formatter = DateTimeFormatter.ofPattern("EEE, MMM d • HH:mm", Locale.getDefault())
			val text = formatter.format(Instant.ofEpochMilli(timestamp).atZone(ZoneId.systemDefault()))
			val metaPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
				color = ColorUtils.setAlphaComponent(0xFFFFFFFF.toInt(), 150)
				textSize = cardRect.height() * 0.075f
				typeface = Typeface.create("google-sans", Typeface.ITALIC)
			}
			canvas.drawText(text, textLeft, sublineBaseline + metaPaint.textSize * 1.2f, metaPaint)
		}

		val listTop = sublineBaseline + cardRect.height() * 0.18f
		val rowHeight = cardRect.height() * 0.20f
		val rowSpacing = rowHeight * 1.1f
		val rowRadius = rowHeight * 0.45f

		val tasksToRender = tasks.take(TaskWidgetDefaults.MAX_VISIBLE_TASKS)
		if (tasksToRender.isEmpty()) {
			val emptyTitlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
				color = ColorUtils.setAlphaComponent(0xFFFFFFFF.toInt(), 230)
				textSize = rowHeight * 0.68f
				typeface = Typeface.create("google-sans", Typeface.BOLD)
			}
			val emptySubtitlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
				color = ColorUtils.setAlphaComponent(0xFFFFFFFF.toInt(), 180)
				textSize = rowHeight * 0.45f
				typeface = Typeface.create("google-sans", Typeface.NORMAL)
			}
			canvas.drawText("You're all caught up!", textLeft, listTop + rowHeight * 0.85f, emptyTitlePaint)
			canvas.drawText("No open tasks right now", textLeft, listTop + rowHeight * 1.45f, emptySubtitlePaint)
			return bitmap
		}

		val rowBackgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			style = Paint.Style.FILL
			color = ColorUtils.setAlphaComponent(ColorUtils.blendARGB(secondaryAccent, 0xFF121212.toInt(), if (isDarkTheme) 0.65f else 0.35f), if (isDarkTheme) 170 else 210)
		}

		val completedIndicatorPaint = Paint(Paint.ANTI_ALIAS_FLAG)
		val pendingIndicatorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			style = Paint.Style.STROKE
			strokeWidth = rowHeight * 0.18f
			color = ColorUtils.setAlphaComponent(ColorUtils.blendARGB(0xFF555555.toInt(), 0xFFFFFFFF.toInt(), 0.62f), 220)
		}

		val titlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			color = 0xFFFFFFFF.toInt()
			textSize = rowHeight * 0.52f
			typeface = Typeface.create("google-sans", Typeface.NORMAL)
			isFakeBoldText = true
		}
		val subtitlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			color = ColorUtils.setAlphaComponent(0xFFFFFFFF.toInt(), 185)
			textSize = rowHeight * 0.38f
			typeface = Typeface.create("google-sans", Typeface.NORMAL)
		}

		tasksToRender.forEachIndexed { index, task ->
			val top = listTop + index * rowSpacing
			val rowRect = RectF(
				cardRect.left + contentPadding,
				top,
				cardRect.right - contentPadding,
				top + rowHeight
			)

			val backgroundAlpha = if (task.isCompleted) 165 else 200
			rowBackgroundPaint.alpha = backgroundAlpha
			canvas.drawRoundRect(rowRect, rowRadius, rowRadius, rowBackgroundPaint)

			val indicatorCenterX = rowRect.left + rowHeight * 0.42f
			val indicatorCenterY = rowRect.centerY()
			val indicatorRadius = rowHeight * 0.28f

			if (task.isCompleted) {
				completedIndicatorPaint.style = Paint.Style.FILL
				completedIndicatorPaint.color = ColorUtils.blendARGB(0xFF555555.toInt(), 0xFFFFFFFF.toInt(), 0.15f)
				completedIndicatorPaint.setShadowLayer(
					indicatorRadius * 0.45f,
					0f,
					indicatorRadius * 0.18f,
					ColorUtils.setAlphaComponent(0xFF555555.toInt(), 120)
				)
				canvas.drawCircle(indicatorCenterX, indicatorCenterY, indicatorRadius, completedIndicatorPaint)

				val checkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
					color = 0xFFFFFFFF.toInt()
					style = Paint.Style.STROKE
					strokeWidth = indicatorRadius * 0.32f
					strokeCap = Paint.Cap.ROUND
					strokeJoin = Paint.Join.ROUND
				}
				val checkPath = Path().apply {
					moveTo(indicatorCenterX - indicatorRadius * 0.6f, indicatorCenterY)
					lineTo(indicatorCenterX - indicatorRadius * 0.12f, indicatorCenterY + indicatorRadius * 0.45f)
					lineTo(indicatorCenterX + indicatorRadius * 0.68f, indicatorCenterY - indicatorRadius * 0.55f)
				}
				canvas.drawPath(checkPath, checkPaint)
			} else {
				pendingIndicatorPaint.color = task.highlightColor ?: pendingIndicatorPaint.color
				canvas.drawCircle(indicatorCenterX, indicatorCenterY, indicatorRadius, pendingIndicatorPaint)
			}

			val textStartX = rowRect.left + rowHeight * 0.85f
			val titleBaseline = rowRect.centerY() - (titlePaint.textSize * if (task.subtitle.isNullOrBlank()) 0.15f else 0.35f)
			canvas.drawText(task.title, textStartX, titleBaseline, titlePaint)

			if (!task.subtitle.isNullOrBlank()) {
				val subtitleBaseline = titleBaseline + subtitlePaint.textSize * 1.15f
				canvas.drawText(task.subtitle, textStartX, subtitleBaseline, subtitlePaint)
			}
		}

		return bitmap
	}

	private fun buildAuroraTicketPath(rect: RectF): Path {
		val w = rect.width()
		val h = rect.height()
		val maxCornerRadius = Math.min(w, h) * 0.15f
		val shapeRadii = floatArrayOf(
			maxCornerRadius * 0.8f, maxCornerRadius * 0.8f, // Top-left
			maxCornerRadius * 0.4f, maxCornerRadius * 0.4f, // Top-right
			maxCornerRadius * 0.6f, maxCornerRadius * 0.6f, // Bottom-right
			maxCornerRadius * 0.2f, maxCornerRadius * 0.2f, // Bottom-left
		)

		return Path().apply {
			addRoundRect(rect, shapeRadii, Path.Direction.CW)
		}
	}

	private fun drawAuroraOrbits(canvas: Canvas, rect: RectF, @ColorInt secondaryAccent: Int) {
		val orbitPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
			style = Paint.Style.STROKE
			strokeCap = Paint.Cap.ROUND
			strokeWidth = rect.width() * 0.012f
			color = ColorUtils.setAlphaComponent(ColorUtils.blendARGB(secondaryAccent, 0xFFFFFFFF.toInt(), 0.35f), 130)
		}

		val orbitCount = 4
		val centerX = rect.centerX()
		val centerY = rect.top + rect.height() * 0.4f
		val baseRadius = rect.width() * 0.18f

		repeat(orbitCount) { index ->
			val radius = baseRadius + rect.width() * 0.05f * index
			val angleOffset = index * (PI / 9.5)
			val startAngle = Math.toDegrees((-60 + angleOffset).toFloat().toDouble())
			val sweepAngle = 190 - index * 18

			val oval = RectF(
				centerX - radius,
				centerY - radius * 0.82f,
				centerX + radius * 1.12f,
				centerY + radius
			)
			canvas.drawArc(oval, startAngle.toFloat(), sweepAngle.toFloat(), false, orbitPaint)

			val cometX = centerX + radius * cos(angleOffset + PI / 4).toFloat()
			val cometY = centerY + radius * sin(angleOffset + PI / 4).toFloat()
			val cometPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
				shader = RadialGradient(
					cometX,
					cometY,
					rect.width() * 0.09f,
					ColorUtils.setAlphaComponent(secondaryAccent, 170),
					ColorUtils.setAlphaComponent(secondaryAccent, 0),
					Shader.TileMode.CLAMP
				)
			}
			canvas.drawCircle(cometX, cometY, rect.width() * 0.08f, cometPaint)
		}
	}

	private fun buildSummaryLine(summary: TaskSummary): String {
		val pending = (summary.total - summary.completed).coerceAtLeast(0)
		val parts = mutableListOf<String>()
		parts += "${summary.completed}/${summary.total} done"
		if (summary.today > 0) parts += "${summary.today} today"
		if (summary.overdue > 0) parts += "${summary.overdue} overdue"
		if (pending > 0 && summary.today == 0) parts += "$pending pending"
		return parts.joinToString(" • ")
	}

	private fun decodeTasks(json: String?): List<TaskEntry> {
		if (json.isNullOrBlank()) return emptyList()
		return runCatching { TaskJsonCodec.decode(json) }.getOrDefault(emptyList())
	}

	object PrefKeys {
		val tasksJson = stringPreferencesKey("tasks_widget_json")
		val totalTasks = intPreferencesKey("tasks_widget_total")
		val completedTasks = intPreferencesKey("tasks_widget_completed")
		val overdueTasks = intPreferencesKey("tasks_widget_overdue")
		val todayTasks = intPreferencesKey("tasks_widget_today")
		val heroHeader = stringPreferencesKey("tasks_widget_header")
		val accentColor = intPreferencesKey("tasks_widget_accent")
		val secondaryAccent = intPreferencesKey("tasks_widget_accent_secondary")
		val lastUpdatedEpochMillis = longPreferencesKey("tasks_widget_last_updated")
	}

	companion object {
		suspend fun updateWidget(
			context: Context,
			tasks: List<TaskEntry>,
			summary: TaskSummary,
			header: String?,
			@ColorInt accentColor: Int?,
			@ColorInt secondaryAccent: Int?,
		) {
			val manager = GlanceAppWidgetManager(context)
			val widget = TasksWidget()
			val ids = manager.getGlanceIds(TasksWidget::class.java)
			ids.forEach { glanceId ->
				updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
					val mutable = prefs.toMutablePreferences()
					mutable[PrefKeys.tasksJson] = TaskJsonCodec.encode(tasks)
					mutable[PrefKeys.totalTasks] = summary.total
					mutable[PrefKeys.completedTasks] = summary.completed
					mutable[PrefKeys.overdueTasks] = summary.overdue
					mutable[PrefKeys.todayTasks] = summary.today
					mutable[PrefKeys.lastUpdatedEpochMillis] = summary.lastUpdatedEpochMillis
						?: System.currentTimeMillis()
					header?.let { mutable[PrefKeys.heroHeader] = it }
					accentColor?.let { mutable[PrefKeys.accentColor] = it }
					secondaryAccent?.let { mutable[PrefKeys.secondaryAccent] = it }
					mutable
				}
				widget.update(context, glanceId)
			}
		}

		suspend fun clear(context: Context) {
			val manager = GlanceAppWidgetManager(context)
			val widget = TasksWidget()
			val ids = manager.getGlanceIds(TasksWidget::class.java)
			ids.forEach { glanceId ->
				updateAppWidgetState(context, PreferencesGlanceStateDefinition, glanceId) { prefs ->
					prefs.toMutablePreferences().apply { clear() }
				}
				widget.update(context, glanceId)
			}
		}
	}
}

data class TaskEntry(
	val title: String,
	val subtitle: String?,
	val isCompleted: Boolean,
	@ColorInt val highlightColor: Int? = null,
)

data class TaskSummary(
	val total: Int,
	val completed: Int,
	val overdue: Int,
	val today: Int,
	val lastUpdatedEpochMillis: Long? = null,
)

object TaskWidgetDefaults {
	const val TAG = "TasksWidget"
	const val MAX_VISIBLE_TASKS = 4
	const val DEFAULT_HEADER = "Flow state"
	val DEFAULT_ACCENT: Int = 0xFF555555.toInt()
	val DEFAULT_SECONDARY: Int = 0xFF777777.toInt()

	fun sampleTasks(): List<TaskEntry> = listOf(
		TaskEntry("Storyboard weekly demo", "Today • 4:30 PM", false, 0xFF777777.toInt()),
		TaskEntry("Draft investor summary", "Tomorrow", false, 0xFF999999.toInt()),
		TaskEntry("Sync with research", "Wed", true, null),
		TaskEntry("QA Material widget", "Fri", false, 0xFFBBBBBB.toInt())
	)
}

private object TaskJsonCodec {
	fun encode(tasks: List<TaskEntry>): String {
		val jsonTasks = org.json.JSONArray()
		tasks.forEach { task ->
			val json = org.json.JSONObject().apply {
				put("title", task.title)
				put("subtitle", task.subtitle)
				put("completed", task.isCompleted)
				task.highlightColor?.let { put("highlight", it) }
			}
			jsonTasks.put(json)
		}
		return jsonTasks.toString()
	}

	fun decode(json: String): List<TaskEntry> {
		val array = org.json.JSONArray(json)
		val tasks = mutableListOf<TaskEntry>()
		for (i in 0 until array.length()) {
			val obj = array.optJSONObject(i) ?: continue
			tasks += TaskEntry(
				title = obj.optString("title", "Untitled task"),
				subtitle = obj.optString("subtitle").takeIf { it.isNotBlank() },
				isCompleted = obj.optBoolean("completed", false),
				highlightColor = if (obj.has("highlight")) obj.optInt("highlight") else null
			)
		}
		return tasks
	}
}

class TasksWidgetReceiver : GlanceAppWidgetReceiver() {
	override val glanceAppWidget: GlanceAppWidget = TasksWidget()
}
