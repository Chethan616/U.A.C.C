package com.example.uacc.dynamicisland.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import com.example.uacc.dynamicisland.model.*
import com.example.uacc.dynamicisland.service.IslandOverlayService
import com.example.uacc.dynamicisland.ui.theme.BlackTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun IslandApp(
    islandOverlayService: IslandOverlayService
) {
    val context = LocalContext.current
    LaunchedEffect(Unit) {
        // Initialize settings if needed
    }

    val islandView = islandOverlayService.islandState
    val activePlugins = PluginManager.activePlugins
    val transcriptPlugin = activePlugins.firstOrNull { it is CallTranscriptPlugin } as? CallTranscriptPlugin
    val callPlugin = activePlugins.firstOrNull { it is CallPlugin } as? CallPlugin
    val bindedPlugin = transcriptPlugin ?: activePlugins.firstOrNull()
    val leftOpenedPlugin = callPlugin ?: bindedPlugin
    val rightOpenedPlugin = transcriptPlugin ?: bindedPlugin
    val pulseSource = when {
        bindedPlugin?.isPulsing == true -> bindedPlugin
        callPlugin?.isPulsing == true -> callPlugin
        transcriptPlugin?.isPulsing == true -> transcriptPlugin
        else -> activePlugins.firstOrNull { it.isPulsing }
    }
    
    // Auto-close functionality for plugins with timer (only if not fully expanded)
    LaunchedEffect(bindedPlugin?.id, bindedPlugin?.isActive, islandView.state) {
        bindedPlugin?.let { plugin ->
            if (plugin.autoCloseAfterSeconds > 0 && plugin.isActive) {
                delay(plugin.autoCloseAfterSeconds * 1000L)
                // Only auto-close if not in expanded state (user manually expanded)
                if (plugin.isActive && islandView.state != IslandStates.Expanded) {
                    islandOverlayService.closeToCircle()
                }
            }
        }
    }
    
    // Dynamic color pulse animation for calls
    val isPulsing = pulseSource?.isPulsing == true
    val pulseColor = pulseSource?.pulseColor ?: Color.Green
    
    // Debug: Force pulse for testing (remove in production)
    // val isPulsing = true
    // val pulseColor = Color.Green
    
    // Breathing-like pulsing animation (slower and more organic)
    val pulseAlpha by animateFloatAsState(
        targetValue = if (isPulsing) 0.7f else 0.0f,
        animationSpec = if (isPulsing) {
            infiniteRepeatable(
                animation = tween(durationMillis = 1500, easing = CubicBezierEasing(0.4f, 0.0f, 0.6f, 1.0f)), // Breathing curve
                repeatMode = RepeatMode.Reverse
            )
        } else {
            tween(durationMillis = 500)
        },
        label = "pulse_alpha"
    )
    
    val pulseBorderAlpha by animateFloatAsState(
        targetValue = if (isPulsing) 0.9f else 0.3f,
        animationSpec = if (isPulsing) {
            infiniteRepeatable(
                animation = tween(durationMillis = 1800, easing = CubicBezierEasing(0.4f, 0.0f, 0.6f, 1.0f)), // Slower breathing
                repeatMode = RepeatMode.Reverse
            )
        } else {
            tween(durationMillis = 400)
        },
        label = "pulse_border_alpha"
    )
    
    // 🌊 Smooth Bouncy Dynamic Island with Vertical Drop 🌊
    // Width: Bouncy expansion for all states
    val width by animateDpAsState(
        targetValue = islandView.width,
        animationSpec = spring(
            dampingRatio = 0.65f,        // Nice bounce for width
            stiffness = 280f,            // Responsive expansion
            visibilityThreshold = 0.05.dp
        ),
        label = "bouncy_width"
    )
    
    // Height: Bouncy expansion for all states  
    val height by animateDpAsState(
        targetValue = islandView.height,
        animationSpec = spring(
            dampingRatio = 0.7f,         // Smooth height bounce
            stiffness = 220f,            // Nice vertical expansion
            visibilityThreshold = 0.05.dp
        ),
        label = "bouncy_height"
    )
    
    // Corner morphing: Smooth bouncy corners
    val cornerPercentage by animateFloatAsState(
        targetValue = islandView.cornerPercentage,
        animationSpec = spring(
            dampingRatio = 0.75f,        // Controlled corner bounce
            stiffness = 300f,            // Nice corner morphing
            visibilityThreshold = 0.2f
        ),
        label = "bouncy_corners"
    )
    
    // Vertical drop: Clean drop animation when expanding
    val verticalOffset by animateDpAsState(
        targetValue = when (islandView.state) {
            IslandStates.Expanded -> 32.dp  // Drop down when expanded
            else -> 4.dp                    // Normal position
        },
        animationSpec = spring(
            dampingRatio = 0.68f,        // Nice drop bounce
            stiffness = 250f,            // Smooth vertical motion
            visibilityThreshold = 0.05.dp
        ),
        label = "vertical_drop"
    )

    val shape = RoundedCornerShape(cornerPercentage)
    val googleGradientColors = remember {
        listOf(
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335)
        )
    }
    val iosBlue = remember { Color(0xFF0A84FF) }
    val density = LocalDensity.current
    val hasActivePlugin by remember {
        derivedStateOf { activePlugins.isNotEmpty() }
    }
    val hasAiOutline by remember {
        derivedStateOf { activePlugins.any { it.hasAiContent } }
    }
    val aiOutlineProgress by animateFloatAsState(
        targetValue = if (hasAiOutline) 1f else 0f,
        animationSpec = tween(durationMillis = 900, easing = FastOutSlowInEasing),
        label = "ai_outline_progress"
    )
    val outlineFlowTransition = rememberInfiniteTransition(label = "outline_flow")
    val rawGradientShift by outlineFlowTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 5200, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "outline_shift"
    )
    val gradientShift = if (hasAiOutline) rawGradientShift else 0f
    val widthPx = remember(width, density) {
        with(density) { width.coerceAtLeast(1.dp).toPx() }
    }
    val outlineBrush: Brush = remember(
        aiOutlineProgress,
        googleGradientColors,
        iosBlue,
        gradientShift,
        widthPx
    ) {
        if (aiOutlineProgress <= 0.01f || widthPx <= 0f) {
            SolidColor(iosBlue)
        } else {
            val animatedColors = googleGradientColors.map { lerp(iosBlue, it, aiOutlineProgress) }
            val repeatedColors = animatedColors + animatedColors.first()
            val segmentPx = widthPx
            val shiftPx = segmentPx * gradientShift
            Brush.linearGradient(
                colors = repeatedColors,
                start = Offset(shiftPx, 0f),
                end = Offset(shiftPx + segmentPx, 0f),
                tileMode = TileMode.Repeated
            )
        }
    }
    val surfaceGradient = remember {
        Brush.verticalGradient(
            colors = listOf(
                Color(0xFF191C23),
                Color(0xFF101217)
            )
        )
    }
    val borderWidth = if (isPulsing) 2.dp else 1.4.dp

    // Center container
    Box(
        modifier = Modifier
            .fillMaxWidth(),
        contentAlignment = Alignment.TopCenter
    ) {
        MaterialTheme(
            colorScheme = BlackTheme
        ) {
            // Island wrapper centered
            Box(
                modifier = Modifier
                    .padding(top = verticalOffset)
                    .width(width)
                    .height(height),
                contentAlignment = Alignment.Center
            ) {
                // State holders for fade-in/out lifecycle
                var showExpandedContent by remember { mutableStateOf(false) }
                var isClosingExpanded by remember { mutableStateOf(false) }
                val scope = rememberCoroutineScope()
                val interactionSource = remember { MutableInteractionSource() }

                val clickModifier = if (islandView is IslandViewState.Opened || islandView is IslandViewState.Expanded) {
                    Modifier
                        .clip(shape)
                        .combinedClickable(
                            interactionSource = interactionSource,
                            indication = null,
                        onClick = {
                            when (islandView.state) {
                                IslandStates.Expanded -> {
                                    if (!isClosingExpanded) {
                                        isClosingExpanded = true
                                        showExpandedContent = false // triggers fade-out
                                        scope.launch {
                                            delay(120)
                                            islandOverlayService.shrink()
                                            isClosingExpanded = false
                                        }
                                    }
                                }
                                IslandStates.Opened -> islandOverlayService.hideIsland()
                                else -> bindedPlugin?.onClick()
                            }
                        },
                        onLongClick = {
                            val expandablePlugin = when {
                                transcriptPlugin?.canExpand() == true -> transcriptPlugin
                                bindedPlugin?.canExpand() == true -> bindedPlugin
                                callPlugin?.canExpand() == true -> callPlugin
                                else -> null
                            }

                            if (expandablePlugin != null && islandView.state == IslandStates.Opened) {
                                showExpandedContent = false
                                isClosingExpanded = false
                                islandOverlayService.expand()
                            }
                        }
                    )
                } else {
                    Modifier
                        .clip(shape)
                        .combinedClickable(
                            interactionSource = interactionSource,
                            indication = null,
                            onClick = {
                                // When in closed/circle state, only show pill if there are active plugins
                                if (PluginManager.activePlugins.isNotEmpty()) {
                                    islandOverlayService.showIsland()
                                }
                            }
                        )
                }

                Card(
                    shape = shape,
                    modifier = clickModifier
                        .fillMaxSize(),
                    colors = CardDefaults.cardColors(
                        containerColor = Color.Transparent,
                        contentColor = MaterialTheme.colorScheme.onSurface
                    ),
                    border = if (hasActivePlugin) {
                        BorderStroke(
                            width = borderWidth,
                            brush = outlineBrush
                        )
                    } else {
                        null
                    }
                ) {
                    // Manage delayed fade-in (skip if we are in closing phase)
                    LaunchedEffect(islandOverlayService.islandState.state) {
                        if (islandOverlayService.islandState.state == IslandStates.Expanded) {
                            if (!isClosingExpanded) {
                                showExpandedContent = false
                                delay(140)
                                if (!isClosingExpanded && islandOverlayService.islandState.state == IslandStates.Expanded) {
                                    showExpandedContent = true
                                }
                            }
                        } else {
                            showExpandedContent = false
                        }
                    }

                    val surfaceModifier = if (islandOverlayService.islandState.state == IslandStates.Closed) {
                        Modifier.background(Color.Black, shape)
                    } else {
                        Modifier.background(surfaceGradient, shape)
                    }

                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .then(surfaceModifier)
                            .padding(horizontal = 8.dp, vertical = 6.dp)
                    ) {
                        when (islandOverlayService.islandState.state) {
                            IslandStates.Opened -> {
                                val boxModifier = Modifier
                                    .fillMaxHeight()

                                Row(
                                    modifier = Modifier.fillMaxSize(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    // Left side
                                    Box(
                                        modifier = boxModifier,
                                        contentAlignment = Alignment.CenterEnd
                                    ) {
                                        leftOpenedPlugin?.LeftOpenedComposable()
                                    }

                                    // Right side
                                    Box(
                                        modifier = boxModifier,
                                        contentAlignment = Alignment.CenterStart
                                    ) {
                                        rightOpenedPlugin?.RightOpenedComposable()
                                    }
                                }
                            }
                            IslandStates.Expanded -> {
                                val alphaSpec: AnimationSpec<Float> = if (showExpandedContent) {
                                    tween(durationMillis = 260, easing = FastOutSlowInEasing)
                                } else {
                                    tween(durationMillis = 120, easing = FastOutSlowInEasing)
                                }
                                val scaleSpec: AnimationSpec<Float> = if (showExpandedContent) {
                                    tween(durationMillis = 300, easing = FastOutSlowInEasing)
                                } else {
                                    tween(durationMillis = 120, easing = FastOutSlowInEasing)
                                }
                                val expandedAlpha by animateFloatAsState(
                                    targetValue = if (showExpandedContent) 1f else 0f,
                                    animationSpec = alphaSpec,
                                    label = "expanded_alpha"
                                )
                                val scale by animateFloatAsState(
                                    targetValue = if (showExpandedContent) 1f else 0.94f,
                                    animationSpec = scaleSpec,
                                    label = "expanded_scale"
                                )
                                Box(
                                    modifier = Modifier
                                        .fillMaxSize()
                                        .graphicsLayer {
                                            alpha = expandedAlpha
                                            scaleX = scale
                                            scaleY = scale
                                        },
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (expandedAlpha > 0f) {
                                        bindedPlugin?.ExpandedComposable()
                                    }
                                }
                            }
                            IslandStates.Closed -> {
                                // No content in closed state (just the rounded surface)
                            }
                        }
                    }
                }
            }
        }
    }
}