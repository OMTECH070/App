package com.studyplanner.app.domain.models

import android.os.Parcelable
import kotlinx.parcelize.Parcelize
import java.util.*

@Parcelize
data class StudySession(
    val id: String = UUID.randomUUID().toString(),
    val subject: String,
    val topics: String? = null,
    val scheduledFor: Date,
    val duration: Long, // in seconds
    val isCompleted: Boolean = false,
    val completedAt: Date? = null,
    val qualityRating: Int? = null, // 1-5 rating
    val notes: String? = null,
    val createdAt: Date = Date(),
    val userId: String
) : Parcelable

@Parcelize
data class StudyTask(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val subject: String,
    val description: String? = null,
    val dueDate: Date? = null,
    val estimatedDuration: Long? = null, // in seconds
    val priority: Int = 1, // 1-5
    val isCompleted: Boolean = false,
    val completedAt: Date? = null,
    val createdAt: Date = Date(),
    val userId: String
) : Parcelable

@Parcelize
data class UserSubject(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val color: String = "#007AFF",
    val difficulty: Int = 1, // 1-4
    val priority: Int = 1, // 1-5
    val isActive: Boolean = true,
    val masteryLevel: Double = 0.0, // 0.0-1.0
    val totalStudyTime: Long = 0, // in seconds
    val createdAt: Date = Date(),
    val userId: String
) : Parcelable

@Parcelize
data class User(
    val id: String,
    val email: String,
    val displayName: String? = null,
    val profilePhotoUrl: String? = null,
    val studyGoalHours: Int = 6, // daily goal in hours
    val timezone: String = "UTC",
    val isPremium: Boolean = false,
    val preferences: Map<String, Any> = emptyMap(),
    val createdAt: Date = Date()
) : Parcelable

@Parcelize
data class AIInsight(
    val title: String,
    val description: String,
    val actionableTip: String? = null
) : Parcelable

@Parcelize
data class MotivationalQuote(
    val text: String,
    val author: String
) : Parcelable

@Parcelize
data class Achievement(
    val id: String,
    val title: String,
    val description: String,
    val icon: String,
    val isUnlocked: Boolean = false,
    val unlockedAt: Date? = null
) : Parcelable

@Parcelize
data class StudyProgress(
    val completedSessions: Int,
    val totalSessions: Int,
    val totalStudyTime: Long, // in seconds
    val progressPercentage: Double
) : Parcelable

@Parcelize
data class WeeklyData(
    val day: String,
    val hours: Double
) : Parcelable

@Parcelize
data class SubjectBreakdown(
    val subject: String,
    val time: Long, // in seconds
    val percentage: Double,
    val color: String
) : Parcelable