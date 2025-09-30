package com.example.uacc.dynamicisland.model

import android.content.res.Configuration
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

interface IslandState {
    val yPosition: Dp
        get() = DEFAULT_POSITION_Y.dp
    val xPosition: Dp
        get() = DEFAULT_POSITION_X.dp
    val height: Dp
    val width: Dp
    val cornerPercentage: Float
    val state: IslandStates
}

sealed class IslandViewState : IslandState {

    object Closed : IslandViewState() {
        override val height: Dp = 34.dp
        override val width: Dp = 34.dp
        override val cornerPercentage: Float = 100f
        override val state: IslandStates = IslandStates.Closed
    }

    object Opened : IslandViewState() {
        override val height: Dp = 34.dp
        override val width: Dp = DEFAULT_WIDTH.dp
        override val cornerPercentage: Float = 100f
        override val state: IslandStates = IslandStates.Opened
    }

    class Expanded(configuration: Configuration) : IslandViewState() {
        override val height: Dp = DEFAULT_HEIGHT.dp
        override val width: Dp = (configuration.screenWidthDp * 0.75f).dp  // Decreased width to 75% of screen
        override val cornerPercentage: Float = 85f  // More rounded corners
        override val state: IslandStates = IslandStates.Expanded
    }
}

enum class IslandStates {
    Closed,
    Opened,
    Expanded
}

object Island {
    var isScreenOn: Boolean = true
    var isInLandscape: Boolean = false
}