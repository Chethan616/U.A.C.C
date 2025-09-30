package com.example.uacc.dynamicisland.model

// Settings
const val SETTINGS_KEY = "UACCDynamicIslandSettings"
const val SETTINGS_CHANGED = "com.example.uacc.SETTINGS_CHANGED"
const val SETTINGS_THEME_INVERTED = "com.example.uacc.SETTINGS_THEME_INVERTED"
const val THEME_INVERTED = "theme_inverted"

// Plugin System
const val PLUGIN_ENABLED_PREFIX = "plugin_enabled_"

// Island Settings  
const val SETTING_POSITION_Y = "position_y"
const val SETTING_POSITION_X = "position_x"
const val SETTING_WIDTH = "width"
const val SETTING_HEIGHT = "height"
const val SETTING_CORNER_RADIUS = "corner_radius"
const val SETTING_SHOW_BORDERS = "show_borders"
const val SETTING_SHOW_ON_LOCK_SCREEN = "show_on_lock_screen"
const val SETTING_SHOW_IN_LANDSCAPE = "show_in_landscape"
const val SETTING_GRAVITY = "gravity"

// Default Values
const val DEFAULT_POSITION_Y = 12
const val DEFAULT_POSITION_X = 0
const val DEFAULT_WIDTH = 120
const val DEFAULT_HEIGHT = 140  // Increased height for better multi-line content visibility
const val DEFAULT_CORNER_RADIUS = 70   // Adjusted corner radius for proportional curves (50% of 140dp)
const val DEFAULT_SHOW_BORDERS = false
const val DEFAULT_SHOW_ON_LOCK_SCREEN = true
const val DEFAULT_SHOW_IN_LANDSCAPE = false
const val DEFAULT_GRAVITY = 0 // Center