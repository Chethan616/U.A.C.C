package com.example.uacc

import android.annotation.SuppressLint
import android.content.Context
import android.database.Cursor
import android.provider.CallLog
import android.provider.ContactsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Date

@SuppressLint("Range")
class CallLogManager(private val context: Context) {
    
    fun getCallLogs(limit: Int): List<Map<String, Any?>> {
        val callLogs = mutableListOf<Map<String, Any?>>()
        
        try {
            val uri = CallLog.Calls.CONTENT_URI
            val projection = arrayOf(
                CallLog.Calls._ID,
                CallLog.Calls.NUMBER,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION,
                CallLog.Calls.TYPE
            )
            
            val sortOrder = "${CallLog.Calls.DATE} DESC"
            
            context.contentResolver.query(uri, projection, null, null, sortOrder)?.use { cursor ->
                var count = 0
                while (cursor.moveToNext() && count < limit) {
                    val id = cursor.getString(cursor.getColumnIndex(CallLog.Calls._ID))
                    val number = cursor.getString(cursor.getColumnIndex(CallLog.Calls.NUMBER)) ?: ""
                    val cachedName = cursor.getString(cursor.getColumnIndex(CallLog.Calls.CACHED_NAME))
                    val date = cursor.getLong(cursor.getColumnIndex(CallLog.Calls.DATE))
                    val duration = cursor.getInt(cursor.getColumnIndex(CallLog.Calls.DURATION))
                    val type = cursor.getInt(cursor.getColumnIndex(CallLog.Calls.TYPE))
                    
                    // Get contact photo
                    val photoUrl = getContactPhoto(number)
                    val contactName = cachedName ?: getContactName(number)
                    
                    val callType = when (type) {
                        CallLog.Calls.INCOMING_TYPE -> "incoming"
                        CallLog.Calls.OUTGOING_TYPE -> "outgoing"
                        CallLog.Calls.MISSED_TYPE -> "missed"
                        else -> "unknown"
                    }
                    
                    callLogs.add(mapOf(
                        "id" to id,
                        "phoneNumber" to number,
                        "contactName" to contactName,
                        "photoUrl" to photoUrl,
                        "timestamp" to date,
                        "duration" to duration,
                        "type" to callType,
                        "isRead" to true
                    ))
                    count++
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return callLogs
    }
    
    private fun getContactName(phoneNumber: String): String? {
        val uri = ContactsContract.PhoneLookup.CONTENT_FILTER_URI.buildUpon()
            .appendPath(phoneNumber).build()
        
        val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
        
        return try {
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME))
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    private fun getContactPhoto(phoneNumber: String): String? {
        val uri = ContactsContract.PhoneLookup.CONTENT_FILTER_URI.buildUpon()
            .appendPath(phoneNumber).build()
        
        val projection = arrayOf(ContactsContract.PhoneLookup.PHOTO_URI)
        
        return try {
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.PHOTO_URI))
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    fun getCallStats(): Map<String, Int> {
        val now = System.currentTimeMillis()
        val startOfDay = now - (now % (24 * 60 * 60 * 1000))
        
        var todayCalls = 0
        var totalCalls = 0
        var missedCalls = 0
        
        try {
            val uri = CallLog.Calls.CONTENT_URI
            val projection = arrayOf(CallLog.Calls.DATE, CallLog.Calls.TYPE)
            
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                while (cursor.moveToNext()) {
                    val date = cursor.getLong(cursor.getColumnIndex(CallLog.Calls.DATE))
                    val type = cursor.getInt(cursor.getColumnIndex(CallLog.Calls.TYPE))
                    
                    totalCalls++
                    
                    if (date >= startOfDay) {
                        todayCalls++
                    }
                    
                    if (type == CallLog.Calls.MISSED_TYPE) {
                        missedCalls++
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return mapOf(
            "todayCalls" to todayCalls,
            "totalCalls" to totalCalls,
            "missedCalls" to missedCalls
        )
    }
}