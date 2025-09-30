package com.example.uacc.dynamicisland.model

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight

private val rawAiKeywords = listOf(
    "digital assignment",
    "digital assignments",
    "assignment",
    "assignments",
    "schedule",
    "schedules",
    "calendar",
    "calendars",
    "calender",
    "calenders",
    "event",
    "events",
    "meeting",
    "meetings",
    "deadline",
    "deadlines",
    "reminder",
    "reminders",
    "time",
    "times",
    "class",
    "classes",
    "exam",
    "exams",
    "test",
    "tests",
    "homework",
    "task",
    "tasks",
    "appointment",
    "appointments",
    "prep",
    "prepare",
    "preparation",
    "preparaton",
    "prepping",
    "study",
    "study session",
    "study sessions",
    "revision",
    "project",
    "projects",
    "todo",
    "to-do",
    "milestone",
    "milestones",
    "today",
    "tonight",
    "tomorrow",
    "day after tomorrow",
    "next week",
    "next month",
    "next year",
    "this weekend",
    "morning",
    "afternoon",
    "evening",
    "night",
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday"
)

private val aiKeywordPattern: String = rawAiKeywords.joinToString(separator = "|") { keyword ->
    keyword.trim()
        .split("\\s+".toRegex())
        .joinToString(separator = "\\\\s+") { token -> Regex.escape(token) }
}

private val additionalHighlightPatterns = listOf(
    "\\b(?:mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)\\b",
    "\\b(?:today|tonight|tomorrow|day\\s+after\\s+tomorrow|this\\s+weekend|next\\s+(?:week|month|year))\\b",
    "\\b(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\\s+\\d{1,2}\\b",
    "\\b(?:[12]?\\d|3[01])(st|nd|rd|th)\\b",
    "\\b\\d{1,2}/\\d{1,2}(?:/\\d{2,4})?\\b",
    "\\b\\d{1,2}-\\d{1,2}(?:-\\d{2,4})?\\b",
    "\\b\\d{4}-\\d{1,2}-\\d{1,2}\\b",
    "\\b(?:1[0-2]|0?[1-9]):[0-5][0-9]\\s?(?:am|pm)\\b",
    "\\b(?:1[0-2]|0?[1-9])\\s?(?:am|pm)\\b",
    "\\b(?:[01]?\\d|2[0-3]):[0-5][0-9]\\b"
)

private val aiHighlightRegex = Regex(
    pattern = buildString {
        append("\\b($aiKeywordPattern)\\b")
        additionalHighlightPatterns.forEach { pattern ->
            append("|")
            append(pattern)
        }
    },
    option = RegexOption.IGNORE_CASE
)

private val googleGradientColors = listOf(
    Color(0xFF4285F4),
    Color(0xFF34A853),
    Color(0xFFFBBC05),
    Color(0xFFEA4335)
)

@Composable
fun rememberGoogleGradientBrush(): Brush {
    return remember { Brush.horizontalGradient(googleGradientColors) }
}

@Composable
fun rememberAiHighlightedText(
    text: String,
    highlightBrush: Brush = rememberGoogleGradientBrush(),
    highlightAlpha: Float = 1f
): AnnotatedString {
    return remember(text, highlightBrush, highlightAlpha) {
        if (!aiHighlightRegex.containsMatchIn(text)) {
            AnnotatedString(text)
        } else {
            val builder = AnnotatedString.Builder()
            var lastIndex = 0
            aiHighlightRegex.findAll(text).forEach { matchResult ->
                if (matchResult.range.first > lastIndex) {
                    builder.append(text.substring(lastIndex, matchResult.range.first))
                }
                builder.pushStyle(
                    SpanStyle(
                        brush = highlightBrush,
                        fontWeight = FontWeight.SemiBold,
                        alpha = highlightAlpha
                    )
                )
                builder.append(text.substring(matchResult.range))
                builder.pop()
                lastIndex = matchResult.range.last + 1
            }
            if (lastIndex < text.length) {
                builder.append(text.substring(lastIndex))
            }
            builder.toAnnotatedString()
        }
    }
}
