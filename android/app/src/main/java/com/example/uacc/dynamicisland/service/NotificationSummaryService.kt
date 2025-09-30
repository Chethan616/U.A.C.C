package com.example.uacc.dynamicisland.service

import android.util.Log
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import org.json.JSONArray
import java.io.IOException
import java.util.Locale

data class NotificationSummary(
    val summary: String,
    val actionItems: List<String> = emptyList(),
    val scheduledItems: List<ScheduledItem> = emptyList(),
    val priority: Priority = Priority.NORMAL
)

data class ScheduledItem(
    val type: String, // "event", "task", "deadline", "reminder"
    val title: String,
    val description: String,
    val dateTime: String? = null,
    val priority: Priority = Priority.NORMAL
)

enum class Priority {
    LOW, NORMAL, HIGH, URGENT
}

class NotificationSummaryService {
    companion object {
        private const val TAG = "NotificationSummaryService"
        private const val GEMINI_API_KEY = "AIzaSyDiGqWVL5rVjQvqYWvvcrVQNHQPkFzbptM"
        private const val GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
        
        private val client = OkHttpClient.Builder()
            .connectTimeout(8, java.util.concurrent.TimeUnit.SECONDS)
            .readTimeout(15, java.util.concurrent.TimeUnit.SECONDS)
            .writeTimeout(8, java.util.concurrent.TimeUnit.SECONDS)
            .build()

        /**
         * Analyze notification and extract actionable insights as an AI agent
         * @param title The notification title
         * @param text The notification text/content
         * @param appName The app name that sent the notification
         * @return A comprehensive AI-generated analysis with tasks, events, deadlines
         */
        suspend fun analyzeNotificationAsAgent(
            title: String, 
            text: String, 
            appName: String
        ): NotificationSummary = withContext(Dispatchers.IO) {
            try {
                // Create comprehensive content for AI agent analysis
                val notificationContent = buildString {
                    append("App: $appName")
                    if (title.isNotEmpty()) append("\nTitle: $title")
                    if (text.isNotEmpty()) append("\nContent: $text")
                }
                
                val prompt = """
                    You are an intelligent AI assistant agent. Analyze this notification and:
                    1. Create a 3-line summary (max 40 chars per line) with key info
                    2. Extract any tasks, events, deadlines, or action items
                    3. Identify scheduling opportunities 
                    4. Determine priority level
                    
                    Format response as JSON:
                    {
                        "summary": ["Line 1", "Line 2", "Line 3"],
                        "actionItems": ["action1", "action2"],
                        "scheduledItems": [
                            {"type": "task/event/deadline", "title": "...", "description": "...", "dateTime": "...", "priority": "HIGH/NORMAL/LOW"}
                        ],
                        "priority": "HIGH/NORMAL/LOW"
                    }
                    
                    Notification: $notificationContent
                """.trimIndent()
                
                // Create request body
                val requestBody = JSONObject().apply {
                    put("contents", JSONArray().apply {
                        put(JSONObject().apply {
                            put("parts", JSONArray().apply {
                                put(JSONObject().apply {
                                    put("text", prompt)
                                })
                            })
                        })
                    })
                    put("generationConfig", JSONObject().apply {
                        put("maxOutputTokens", 200) // Enough for JSON response
                        put("temperature", 0.4) // Balanced for structured output
                        put("candidateCount", 1)
                    })
                    put("safetySettings", JSONArray()) // Skip safety for speed
                }
                
                val request = Request.Builder()
                    .url(GEMINI_URL)
                    .addHeader("Content-Type", "application/json")
                    .addHeader("X-Goog-Api-Key", GEMINI_API_KEY)
                    .post(requestBody.toString().toRequestBody("application/json".toMediaTypeOrNull()))
                    .build()

                // Execute with timeout
                val response = withTimeoutOrNull(12000) { // 12 second timeout for comprehensive analysis
                    client.newCall(request).execute()
                }
                
                response?.use { resp ->
                    if (resp.isSuccessful) {
                        val responseBody = resp.body?.string()
                        responseBody?.let { body ->
                            val jsonResponse = JSONObject(body)
                            val candidates = jsonResponse.optJSONArray("candidates")
                            if (candidates != null && candidates.length() > 0) {
                                val firstCandidate = candidates.getJSONObject(0)
                                val content = firstCandidate.optJSONObject("content")
                                val parts = content?.optJSONArray("parts")
                                if (parts != null && parts.length() > 0) {
                                    val aiText = parts.getJSONObject(0).optString("text", "")
                                    if (aiText.isNotEmpty()) {
                                        val result = parseAIResponse(aiText, title, text, appName)
                                        Log.d(TAG, "🤖 AI Agent Analysis: $result")
                                        return@withContext result
                                    }
                                }
                            }
                        }
                    } else {
                        Log.w(TAG, "⚠️ Gemini API error: ${resp.code} ${resp.message}")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error generating AI analysis", e)
            }
            
            // Fallback: Create smart analysis from available data
            return@withContext createFallbackAnalysis(title, text, appName)
        }

        /**
         * Legacy method for simple summarization (backward compatibility)
         */
        suspend fun summarizeNotification(
            title: String, 
            text: String, 
            appName: String
        ): String = withContext(Dispatchers.IO) {
            val analysis = analyzeNotificationAsAgent(title, text, appName)
            return@withContext analysis.summary
        }

        /**
         * Parse AI response from Gemini API
         */
        private fun parseAIResponse(aiText: String, title: String, text: String, appName: String): NotificationSummary {
            try {
                // Try to extract JSON from AI response
                val jsonStart = aiText.indexOf("{")
                val jsonEnd = aiText.lastIndexOf("}") + 1
                
                if (jsonStart >= 0 && jsonEnd > jsonStart) {
                    val jsonText = aiText.substring(jsonStart, jsonEnd)
                    val jsonObj = JSONObject(jsonText)
                    
                    // Parse summary lines
                    val summaryArray = jsonObj.optJSONArray("summary")
                    val summaryLines = mutableListOf<String>()
                    if (summaryArray != null) {
                        for (i in 0 until minOf(3, summaryArray.length())) {
                            val line = summaryArray.getString(i).take(40) // Max 40 chars per line
                            if (line.isNotBlank()) summaryLines.add(line)
                        }
                    }
                    
                    // Parse action items
                    val actionArray = jsonObj.optJSONArray("actionItems")
                    val actionItems = mutableListOf<String>()
                    if (actionArray != null) {
                        for (i in 0 until actionArray.length()) {
                            actionItems.add(actionArray.getString(i))
                        }
                    }
                    
                    // Parse scheduled items
                    val scheduledArray = jsonObj.optJSONArray("scheduledItems")
                    val scheduledItems = mutableListOf<ScheduledItem>()
                    if (scheduledArray != null) {
                        for (i in 0 until scheduledArray.length()) {
                            val item = scheduledArray.getJSONObject(i)
                            scheduledItems.add(
                                ScheduledItem(
                                    type = item.optString("type", "task"),
                                    title = item.optString("title", ""),
                                    description = item.optString("description", ""),
                                    dateTime = item.optString("dateTime"),
                                    priority = Priority.valueOf(item.optString("priority", "NORMAL"))
                                )
                            )
                        }
                    }
                    
                    // Parse priority
                    val priorityStr = jsonObj.optString("priority", "NORMAL")
                    val priority = try {
                        Priority.valueOf(priorityStr)
                    } catch (e: Exception) {
                        Priority.NORMAL
                    }
                    
                    return NotificationSummary(
                        summary = summaryLines.joinToString("\n"),
                        actionItems = actionItems,
                        scheduledItems = scheduledItems,
                        priority = priority
                    )
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to parse AI JSON response", e)
            }
            
            // Fallback parsing
            return createFallbackAnalysis(title, text, appName)
        }

        /**
         * Create a smart fallback analysis when AI API is unavailable
         */
    fun createFallbackAnalysis(title: String, text: String, appName: String): NotificationSummary {
            val summary = createFallbackSummaryText(title, text, appName)
            val lines = summary.split("\n").take(3)
            
            // Detect potential action items and scheduling needs
            val actionItems = mutableListOf<String>()
            val scheduledItems = mutableListOf<ScheduledItem>()
            val priority = detectPriority(title, text, appName)
            
            // Extract action items based on keywords
            val combinedText = "$title $text".lowercase()
            if (combinedText.contains("meeting") || combinedText.contains("appointment")) {
                actionItems.add("📅 Schedule meeting")
                scheduledItems.add(ScheduledItem("event", "Meeting", title, null, priority))
            }
            if (combinedText.contains("deadline") || combinedText.contains("due")) {
                actionItems.add("⏰ Set reminder")
                scheduledItems.add(ScheduledItem("deadline", "Deadline", title, null, Priority.HIGH))
            }
            if (combinedText.contains("task") || combinedText.contains("todo")) {
                actionItems.add("✅ Add to tasks")
                scheduledItems.add(ScheduledItem("task", "Task", title, null, priority))
            }
            if (combinedText.contains("payment") || combinedText.contains("bill")) {
                actionItems.add("💳 Review payment")
                scheduledItems.add(ScheduledItem("reminder", "Payment Due", title, null, Priority.HIGH))
            }
            
            return NotificationSummary(
                summary = lines.joinToString("\n"),
                actionItems = actionItems,
                scheduledItems = scheduledItems,
                priority = priority
            )
        }

        /**
         * Detect priority level based on content
         */
        private fun detectPriority(title: String, text: String, appName: String): Priority {
            val combinedText = "$title $text".lowercase()
            return when {
                combinedText.contains("urgent") || combinedText.contains("emergency") -> Priority.URGENT
                combinedText.contains("important") || combinedText.contains("deadline") -> Priority.HIGH
                combinedText.contains("reminder") || combinedText.contains("meeting") -> Priority.NORMAL
                else -> Priority.NORMAL
            }
        }

        private val timeRegex = Regex(
            pattern = "(?i)\\b((?:at\\s+)?(?:1[0-2]|0?[1-9])(?::[0-5][0-9])?\\s?(?:am|pm)|(?:[01]?\\d|2[0-3]):[0-5][0-9])\\b"
        )

        private val dayRegex = Regex(
            pattern = "(?i)\\b(today|tonight|tomorrow|day\\s+after\\s+tomorrow|this\\s+weekend|next\\s+(?:week|month|year)|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\\b"
        )

        private val dateRegexes = listOf(
            Regex("(?i)\\b(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\s+\\d{1,2}(?:,\\s*\\d{4})?\\b"),
            Regex("(?i)\\b\\d{1,2}/\\d{1,2}(?:/\\d{2,4})?\\b"),
            Regex("(?i)\\b\\d{4}-\\d{1,2}-\\d{1,2}\\b"),
            Regex("(?i)\\b\\d{1,2}(?:st|nd|rd|th)\\b")
        )

        private fun extractTimePhrase(text: String): String? = timeRegex.find(text)?.value?.trim()

        private fun extractDayPhrase(text: String): String? = dayRegex.find(text)?.value?.trim()

        private fun extractDatePhrase(text: String): String? {
            for (regex in dateRegexes) {
                val match = regex.find(text)
                if (match != null) {
                    return match.value.trim()
                }
            }
            return null
        }

        private fun combineSchedule(base: String, day: String?, date: String?, time: String?): String {
            val collected = mutableListOf<String>()
            val dateCandidate = when {
                !day.isNullOrBlank() -> day
                !date.isNullOrBlank() -> date
                else -> null
            }
            dateCandidate?.let { collected += it }
            time?.takeIf { it.isNotBlank() }?.let { collected += it }

            if (collected.isEmpty()) return base

            val unique = mutableListOf<String>()
            collected.forEach { candidate ->
                if (unique.none { it.equals(candidate, ignoreCase = true) }) {
                    unique += candidate
                }
            }

            return "$base ${unique.joinToString(" ")}".trim()
        }

        private fun truncateSummary(text: String, max: Int = 80): String {
            val trimmed = text.trim()
            if (trimmed.length <= max) return trimmed
            if (max <= 1) return "…"
            return trimmed.take(max - 1) + "…"
        }

        private fun generateSummaryHeadline(title: String, body: String, appName: String): String {
            val trimmedTitle = title.trim()
            val trimmedBody = body.trim()
            val combined = listOf(trimmedTitle, trimmedBody)
                .filter { it.isNotBlank() }
                .joinToString(" ")
                .trim()
            val evaluationText = if (combined.isNotEmpty()) combined else (trimmedTitle.ifEmpty { trimmedBody })
            if (evaluationText.isBlank()) {
                return truncateSummary("Update from $appName")
            }

            val lower = evaluationText.lowercase(Locale.getDefault())
            val normalizedApp = appName.lowercase(Locale.getDefault())
            val timePhrase = extractTimePhrase(evaluationText)
            val dayPhrase = extractDayPhrase(evaluationText)
            val datePhrase = extractDatePhrase(evaluationText)
            val contactName = trimmedTitle.takeIf { it.isNotBlank() }

            fun withSchedule(base: String): String = truncateSummary(
                combineSchedule(base, dayPhrase, datePhrase, timePhrase)
            )

            val summary = when {
                lower.contains("urgent") || lower.contains("asap") || lower.contains("immediately") -> withSchedule("Urgent update")
                lower.contains("meeting") || lower.contains("appointment") || lower.contains("session") -> withSchedule("Meeting reminder")
                lower.contains("call") && !lower.contains("recall") -> withSchedule("Call scheduled")
                lower.contains("deadline") || lower.contains("due") || lower.contains("submit") || lower.contains("expires") -> withSchedule("Deadline approaching")
                lower.contains("payment") || lower.contains("invoice") || lower.contains("bill") || normalizedApp.contains("bank") || normalizedApp.contains("pay") -> withSchedule("Payment due")
                lower.contains("exam") || lower.contains("test") || lower.contains("quiz") -> withSchedule("Exam reminder")
                lower.contains("class") || lower.contains("lecture") || lower.contains("lesson") -> withSchedule("Class reminder")
                lower.contains("task") || lower.contains("todo") || lower.contains("assignment") || lower.contains("project") -> withSchedule("Task to complete")
                lower.contains("event") || normalizedApp.contains("calendar") -> withSchedule("Event reminder")
                lower.contains("reminder") -> withSchedule("Reminder")
                contactName != null && (normalizedApp.contains("whatsapp") || normalizedApp.contains("telegram") || normalizedApp.contains("messages") || normalizedApp.contains("sms") || normalizedApp.contains("instagram")) -> {
                    val base = "Update from ${contactName.take(24)}"
                    truncateSummary(combineSchedule(base, dayPhrase, datePhrase, timePhrase))
                }
                trimmedTitle.isNotBlank() -> truncateSummary(trimmedTitle)
                else -> truncateSummary("Update from $appName")
            }

            return summary
        }

        /**
         * Create a smart fallback summary text when AI API is unavailable
         */
        private fun createFallbackSummaryText(title: String, text: String, appName: String): String {
            val sanitizedTitle = title.trim()
            val sanitizedBody = text.trim()
            val normalizedApp = appName.lowercase()

            val summaryLine = generateSummaryHeadline(sanitizedTitle, sanitizedBody, appName)

            val snippetSource = when {
                sanitizedBody.isNotEmpty() -> sanitizedBody
                sanitizedTitle.isNotEmpty() -> sanitizedTitle
                else -> ""
            }

            val snippet = snippetSource
                .replace("\n", " ")
                .replace("\\s+".toRegex(), " ")
                .takeIf { it.isNotEmpty() }
                ?.let { base ->
                    if (base.length > 80) base.take(77) + "…" else base
                }

            val lines = mutableListOf<String>()
            lines += summaryLine

            if (lines.size < 3 && !snippet.isNullOrBlank() && !snippet.equals(summaryLine, ignoreCase = true)) {
                lines += truncateSummary(snippet)
            }

            val actionHint = when {
                normalizedApp.contains("whatsapp") ||
                normalizedApp.contains("telegram") ||
                normalizedApp.contains("messages") -> "Reply or follow up when free"
                normalizedApp.contains("instagram") -> "Open Instagram to view the update"
                normalizedApp.contains("gmail") ||
                normalizedApp.contains("mail") ||
                normalizedApp.contains("outlook") -> "Schedule time to respond"
                normalizedApp.contains("calendar") -> "Check your schedule and prepare"
                else -> "Tap to view full details"
            }
            if (lines.size < 3 && lines.none { it.equals(actionHint, ignoreCase = true) }) {
                lines += actionHint
            }

            return lines
                .filter { it.isNotBlank() }
                .distinct()
                .take(3)
                .joinToString("\n")
        }
    }
}