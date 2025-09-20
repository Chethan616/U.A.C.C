package com.example.uacc

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class TaskManager(private val context: Context) {
    
    private val prefs: SharedPreferences = context.getSharedPreferences("tasks", Context.MODE_PRIVATE)
    private val gson = Gson()
    
    private val mockTasks = listOf(
        mapOf(
            "id" to "1",
            "title" to "Call client about project update",
            "description" to "Discuss the new requirements and timeline",
            "dueDate" to (System.currentTimeMillis() + 2 * 60 * 60 * 1000), // 2 hours from now
            "completed" to false,
            "priority" to "high",
            "notes" to "Important client call",
            "createdAt" to (System.currentTimeMillis() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
            "updatedAt" to null
        ),
        mapOf(
            "id" to "2",
            "title" to "Review presentation slides",
            "description" to "Check formatting and content for tomorrow's meeting",
            "dueDate" to (System.currentTimeMillis() + 5 * 60 * 60 * 1000), // 5 hours from now
            "completed" to false,
            "priority" to "normal",
            "notes" to null,
            "createdAt" to (System.currentTimeMillis() - 24 * 60 * 60 * 1000), // 1 day ago
            "updatedAt" to null
        ),
        mapOf(
            "id" to "3",
            "title" to "Book flight tickets",
            "description" to "For the business trip next month",
            "dueDate" to (System.currentTimeMillis() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
            "completed" to false,
            "priority" to "normal",
            "notes" to null,
            "createdAt" to (System.currentTimeMillis() - 6 * 60 * 60 * 1000), // 6 hours ago
            "updatedAt" to null
        ),
        mapOf(
            "id" to "4",
            "title" to "Grocery shopping",
            "description" to "Milk, bread, eggs, vegetables",
            "dueDate" to (System.currentTimeMillis() + 24 * 60 * 60 * 1000), // 1 day from now
            "completed" to false,
            "priority" to "low",
            "notes" to null,
            "createdAt" to (System.currentTimeMillis() - 3 * 60 * 60 * 1000), // 3 hours ago
            "updatedAt" to null
        ),
        mapOf(
            "id" to "5",
            "title" to "Pay electricity bill",
            "description" to "Due amount: ₹2,450",
            "dueDate" to (System.currentTimeMillis() + 12 * 60 * 60 * 1000), // 12 hours from now
            "completed" to false,
            "priority" to "urgent",
            "notes" to null,
            "createdAt" to (System.currentTimeMillis() - 8 * 60 * 60 * 1000), // 8 hours ago
            "updatedAt" to null
        ),
        mapOf(
            "id" to "6",
            "title" to "Doctor appointment",
            "description" to "Annual health checkup",
            "dueDate" to (System.currentTimeMillis() + 5 * 24 * 60 * 60 * 1000), // 5 days from now
            "completed" to true,
            "priority" to "high",
            "notes" to null,
            "createdAt" to (System.currentTimeMillis() - 3 * 24 * 60 * 60 * 1000), // 3 days ago
            "updatedAt" to (System.currentTimeMillis() - 24 * 60 * 60 * 1000) // 1 day ago
        ),
        mapOf(
            "id" to "7",
            "title" to "Finish project documentation",
            "description" to "Complete API documentation and user guide",
            "dueDate" to (System.currentTimeMillis() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
            "completed" to false,
            "priority" to "high",
            "notes" to null,
            "createdAt" to (System.currentTimeMillis() - 24 * 60 * 60 * 1000), // 1 day ago
            "updatedAt" to null
        ),
        mapOf(
            "id" to "8",
            "title" to "Team meeting preparation",
            "description" to "Prepare agenda and reports",
            "dueDate" to (System.currentTimeMillis() - 2 * 60 * 60 * 1000), // 2 hours ago (overdue)
            "completed" to false,
            "priority" to "urgent",
            "notes" to null,
            "createdAt" to (System.currentTimeMillis() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
            "updatedAt" to null
        )
    )
    
    fun getTasks(): List<Map<String, Any?>> {
        return try {
            val tasksJson = prefs.getString("tasks_list", null)
            if (tasksJson != null) {
                val type = object : TypeToken<List<Map<String, Any?>>>() {}.type
                gson.fromJson(tasksJson, type) ?: mockTasks
            } else {
                mockTasks
            }
        } catch (e: Exception) {
            mockTasks
        }
    }
    
    fun createTask(taskData: Map<String, Any?>): Map<String, Any?> {
        val tasks = getTasks().toMutableList()
        val newTask = taskData.toMutableMap()
        newTask["id"] = generateTaskId()
        
        tasks.add(newTask)
        saveTasks(tasks)
        
        return newTask
    }
    
    fun updateTask(taskData: Map<String, Any?>): Boolean {
        val tasks = getTasks().toMutableList()
        val taskId = taskData["id"] as? String ?: return false
        
        val index = tasks.indexOfFirst { (it["id"] as? String) == taskId }
        if (index >= 0) {
            tasks[index] = taskData
            saveTasks(tasks)
            return true
        }
        return false
    }
    
    fun deleteTask(taskId: String): Boolean {
        val tasks = getTasks().toMutableList()
        val index = tasks.indexOfFirst { (it["id"] as? String) == taskId }
        if (index >= 0) {
            tasks.removeAt(index)
            saveTasks(tasks)
            return true
        }
        return false
    }
    
    fun getTaskStats(): Map<String, Int> {
        val tasks = getTasks()
        val now = System.currentTimeMillis()
        val startOfDay = now - (now % (24 * 60 * 60 * 1000))
        
        var totalTasks = tasks.size
        var completedTasks = 0
        var pendingTasks = 0
        var overdueTasks = 0
        var todayTasks = 0
        
        for (task in tasks) {
            val completed = task["completed"] as? Boolean ?: false
            val dueDate = task["dueDate"] as? Long
            
            if (completed) {
                completedTasks++
            } else {
                pendingTasks++
                
                if (dueDate != null && dueDate < now) {
                    overdueTasks++
                }
                
                if (dueDate != null && dueDate >= startOfDay && dueDate < startOfDay + 24 * 60 * 60 * 1000) {
                    todayTasks++
                }
            }
        }
        
        return mapOf(
            "totalTasks" to totalTasks,
            "completedTasks" to completedTasks,
            "pendingTasks" to pendingTasks,
            "overdueTasks" to overdueTasks,
            "todayTasks" to todayTasks
        )
    }
    
    private fun saveTasks(tasks: List<Map<String, Any?>>) {
        try {
            val tasksJson = gson.toJson(tasks)
            prefs.edit().putString("tasks_list", tasksJson).apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun generateTaskId(): String {
        return "task_${System.currentTimeMillis()}_${(1000..9999).random()}"
    }
}