package com.example.uacc.dynamicisland.model

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import com.example.uacc.dynamicisland.service.IslandOverlayService
import android.util.Log

/**
 * Real-time call transcript plugin for Dynamic Island
 * Displays color-coded speech transcription during calls
 * Blue for incoming caller, White for outgoing user
 */
class CallTranscriptPlugin(
    private val coroutineScope: CoroutineScope
) : BasePlugin() {
    
    override val id: String = "call_transcript_plugin"
    override val name: String = "Call Transcript"
    override val description: String = "Real-time call transcription with speaker identification"
    
    private var overlayService: IslandOverlayService? = null
    
    // Transcript state
    private var transcriptMessages by mutableStateOf<List<TranscriptMessage>>(emptyList())
    private var currentSpeaker by mutableStateOf<String?>(null)
    private var isTranscribing by mutableStateOf(false)
    
    // Real-time typing state
    private var currentPartialText by mutableStateOf("")
    private var isTyping by mutableStateOf(false)

    init {
        // Auto-activate when transcript starts
        isPulsing = true
        pulseColor = Color(0xFF00BCD4) // Cyan for transcription activity
        autoCloseAfterSeconds = 0 // Keep open during call
    }
    
    override fun canExpand(): Boolean = isActive && (
        transcriptMessages.isNotEmpty() ||
        currentPartialText.isNotEmpty() ||
        isTranscribing ||
        isTyping
    )
    
    override fun onCreate(context: IslandOverlayService?) {
        overlayService = context
        Log.d("CallTranscriptPlugin", "🎤 Call transcript plugin initialized")
    }
    
    /**
     * Start call transcription
     */
    fun startTranscript() {
        isActive = true
        isTranscribing = true
        isPulsing = true
        pulseColor = Color(0xFF4CAF50) // Green when actively transcribing
        transcriptMessages = emptyList()
        
        overlayService?.let { service ->
            service.showIsland()
            PluginManager.refreshActivePlugins(service)
        }
        
        Log.d("CallTranscriptPlugin", "🎤 Call transcript started")
    }
    
    /**
     * Stop call transcription
     */
    fun stopTranscript() {
        isTranscribing = false
        isPulsing = false
        isTyping = false
        currentPartialText = ""
        currentSpeaker = null
        
        // Auto-hide after 3 seconds when call ends
        coroutineScope.launch {
            delay(3000)
            if (!isTranscribing) {
                isActive = false
                overlayService?.hideIsland()
            }
        }
        
        Log.d("CallTranscriptPlugin", "🎤 Call transcript stopped")
    }
    
    /**
     * Add a new transcript message
     */
    fun addTranscriptMessage(
        text: String,
        speakerType: SpeakerType,
        isPartial: Boolean = false
    ) {
        val speaker = when (speakerType) {
            SpeakerType.INCOMING -> "Caller"
            SpeakerType.OUTGOING -> "You"
            SpeakerType.SYSTEM -> "System"
        }
        
        if (isPartial) {
            // Handle partial/typing text
            currentPartialText = text
            currentSpeaker = speaker
            isTyping = true
        } else {
            // Add final message to history
            val message = TranscriptMessage(
                text = text,
                speaker = speaker,
                speakerType = speakerType,
                timestamp = System.currentTimeMillis()
            )
            
            transcriptMessages = (transcriptMessages + message).takeLast(50) // Keep last 50 messages
            
            // Clear partial text
            currentPartialText = ""
            isTyping = false
            currentSpeaker = null
            
            Log.d("CallTranscriptPlugin", "💬 Added transcript: [$speaker] $text")
        }
        
        // Ensure island is visible when new content arrives
        if (!isActive) {
            isActive = true
            overlayService?.let { service ->
                service.showIsland()
                PluginManager.refreshActivePlugins(service)
            }
        }
    }
    
    /**
     * Clear all transcript messages
     */
    fun clearTranscript() {
        transcriptMessages = emptyList()
        currentPartialText = ""
        isTyping = false
        currentSpeaker = null
    }
    
    @Composable
    override fun ExpandedComposable() {
        val listState = rememberLazyListState()
        
        // Auto-scroll to bottom when new messages arrive
        LaunchedEffect(transcriptMessages.size, isTyping) {
            if (transcriptMessages.isNotEmpty() || isTyping) {
                listState.animateScrollToItem(
                    if (isTyping) transcriptMessages.size else transcriptMessages.size - 1
                )
            }
        }
        
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
            Icon(
                imageVector = Icons.Default.Call,
                contentDescription = "Transcript",
                tint = if (isTranscribing) Color(0xFF4CAF50) else Color.White.copy(alpha = 0.7f),
                modifier = Modifier.size(16.dp)
            )
            
            Spacer(modifier = Modifier.width(6.dp))
                
                Text(
                    text = if (isTranscribing) "Live Transcript" else "Call Ended",
                    color = Color.White,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
                
                if (isTranscribing) {
                    Spacer(modifier = Modifier.width(4.dp))
                    
                    // Pulse indicator
                    val pulseAlpha by animateFloatAsState(
                        targetValue = if (isTranscribing) 0.3f else 0.0f,
                        animationSpec = infiniteRepeatable(
                            animation = tween(1000),
                            repeatMode = RepeatMode.Reverse
                        ),
                        label = "pulse"
                    )
                    
                    Box(
                        modifier = Modifier
                            .size(6.dp)
                            .clip(RoundedCornerShape(50))
                            .background(Color(0xFF4CAF50).copy(alpha = pulseAlpha))
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Transcript content
            if (transcriptMessages.isEmpty() && !isTyping) {
                // Empty state
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = if (isTranscribing) "Listening..." else "No transcript available",
                        color = Color.White.copy(alpha = 0.6f),
                        fontSize = 12.sp,
                        textAlign = TextAlign.Center
                    )
                    
                    if (isTranscribing) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Start speaking to see transcript",
                            color = Color.White.copy(alpha = 0.4f),
                            fontSize = 10.sp,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            } else {
                // Message list
                LazyColumn(
                    state = listState,
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    items(transcriptMessages) { message ->
                        TranscriptMessageItem(message = message)
                    }
                    
                    // Typing indicator for partial text
                    if (isTyping && currentPartialText.isNotEmpty()) {
                        item {
                            TypingMessageItem(
                                text = currentPartialText,
                                speaker = currentSpeaker ?: "Speaker"
                            )
                        }
                    }
                }
            }
        }
    }
    
    @Composable
    private fun TranscriptMessageItem(message: TranscriptMessage) {
        val textColor = when (message.speakerType) {
            SpeakerType.INCOMING -> Color(0xFF2196F3) // Blue for incoming
            SpeakerType.OUTGOING -> Color.White        // White for outgoing
            SpeakerType.SYSTEM -> Color(0xFFFF9800)   // Orange for system
        }

        val highlightBrush = gradientHighlightBrush()
    val annotatedMessage = rememberAiHighlightedText(message.text, highlightBrush)
        
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = if (message.speakerType == SpeakerType.OUTGOING) 
                Alignment.End else Alignment.Start
        ) {
            // Speaker label
            Text(
                text = message.speaker,
                color = textColor.copy(alpha = 0.7f),
                fontSize = 9.sp,
                fontWeight = FontWeight.Medium
            )
            
            // Message text
            Text(
                text = annotatedMessage,
                color = textColor,
                fontSize = 11.sp,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(top = 1.dp)
            )
        }
    }
    
    @Composable
    private fun TypingMessageItem(text: String, speaker: String) {
        val typingAlpha by animateFloatAsState(
            targetValue = 0.8f,
            animationSpec = infiniteRepeatable(
                animation = tween(800),
                repeatMode = RepeatMode.Reverse
            ),
            label = "typing"
        )
        
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.Start
        ) {
            // Speaker label with typing indicator
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = speaker,
                    color = Color(0xFF2196F3).copy(alpha = 0.7f),
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Medium
                )
                
                Text(
                    text = " •••",
                    color = Color(0xFF2196F3).copy(alpha = typingAlpha),
                    fontSize = 9.sp
                )
            }
            
            // Partial message text
            val highlightBrush = gradientHighlightBrush()
            val annotatedPartial = rememberAiHighlightedText(text, highlightBrush, typingAlpha)
            val typingDisplay = remember(annotatedPartial) {
                buildAnnotatedString {
                    append(annotatedPartial)
                    append("...")
                }
            }

            Text(
                text = typingDisplay,
                color = Color(0xFF2196F3).copy(alpha = typingAlpha),
                fontSize = 11.sp,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(top = 1.dp)
            )
        }
    }
    
    override fun onClick() {
        // Toggle between transcript view and minimal view
        overlayService?.let { service ->
            when (service.islandState.state) {
                IslandStates.Opened -> service.expand()
                IslandStates.Expanded -> service.shrink()
                else -> service.showIsland()
            }
        }
    }
    
    override fun onDestroy() {
        stopTranscript()
        isActive = false
        isPulsing = false
    }

    @Composable
    private fun gradientHighlightBrush(): Brush {
        return rememberGoogleGradientBrush()
    }
    
    @Composable
    override fun LeftOpenedComposable() {
        Row(
            modifier = Modifier.padding(horizontal = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = if (isTranscribing) Icons.Default.Info else Icons.Default.Call,
                contentDescription = "Transcript",
                tint = if (isTranscribing) Color(0xFF4CAF50) else Color.White,
                modifier = Modifier.size(14.dp)
            )
        }
    }
    
    @Composable
    override fun RightOpenedComposable() {
        Row(
            modifier = Modifier
                .padding(horizontal = 4.dp)
                .widthIn(max = 120.dp), // Constrain width for pill view
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.End
        ) {
            // Show live transcript text in pill form
            if (isTyping && currentPartialText.isNotEmpty()) {
                val highlightBrush = gradientHighlightBrush()
                val snippet = currentPartialText.take(20)
                val annotatedSnippet = rememberAiHighlightedText(snippet, highlightBrush)
                val displaySnippet = remember(annotatedSnippet, snippet) {
                    if (currentPartialText.length > 20) {
                        buildAnnotatedString {
                            append(annotatedSnippet)
                            append("...")
                        }
                    } else {
                        annotatedSnippet
                    }
                }

                Text(
                    text = displaySnippet,
                    fontSize = 10.sp,
                    color = Color(0xFF4CAF50), // Green for live speech
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false)
                )
            } else if (transcriptMessages.isNotEmpty()) {
                // Show last message text
                val lastMessage = transcriptMessages.last()
                val highlightBrush = gradientHighlightBrush()
                val snippet = lastMessage.text.take(20)
                val annotatedSnippet = rememberAiHighlightedText(snippet, highlightBrush)
                val displaySnippet = remember(annotatedSnippet, snippet) {
                    if (lastMessage.text.length > 20) {
                        buildAnnotatedString {
                            append(annotatedSnippet)
                            append("...")
                        }
                    } else {
                        annotatedSnippet
                    }
                }
                Text(
                    text = displaySnippet,
                    fontSize = 10.sp,
                    color = when (lastMessage.speakerType) {
                        SpeakerType.INCOMING -> Color(0xFF2196F3) // Blue for caller
                        SpeakerType.OUTGOING -> Color.White        // White for you
                        SpeakerType.SYSTEM -> Color(0xFFFF9800)   // Orange for system
                    },
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false)
                )
            } else if (isTranscribing) {
                // Show listening indicator
                Text(
                    text = "Listening...",
                    fontSize = 10.sp,
                    color = Color.White.copy(alpha = 0.6f),
                    maxLines = 1
                )
            }
            
            // Live indicator dot
            if (isTranscribing) {
                Spacer(modifier = Modifier.width(4.dp))
                
                val liveAlpha by animateFloatAsState(
                    targetValue = 0.9f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(1200),
                        repeatMode = RepeatMode.Reverse
                    ),
                    label = "live"
                )
                
                Box(
                    modifier = Modifier
                        .size(4.dp)
                        .clip(RoundedCornerShape(50))
                        .background(Color(0xFF4CAF50).copy(alpha = liveAlpha))
                )
            }
        }
    }
}

/**
 * Transcript message data class
 */
data class TranscriptMessage(
    val text: String,
    val speaker: String,
    val speakerType: SpeakerType,
    val timestamp: Long
)

/**
 * Speaker types for color coding
 */
enum class SpeakerType {
    INCOMING,  // Blue - incoming caller speech
    OUTGOING,  // White - user/outgoing speech  
    SYSTEM     // Orange - system messages
}
