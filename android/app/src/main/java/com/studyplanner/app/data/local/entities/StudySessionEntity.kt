package com.studyplanner.app.data.local.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.studyplanner.app.domain.models.StudySession
import java.util.*

@Entity(tableName = "study_sessions")
data class StudySessionEntity(
    @PrimaryKey
    val id: String,
    val subject: String,
    val topics: String?,
    val scheduledFor: Date,
    val duration: Long,
    val isCompleted: Boolean,
    val completedAt: Date?,
    val qualityRating: Int?,
    val notes: String?,
    val createdAt: Date,
    val userId: String
) {
    fun toDomainModel(): StudySession {
        return StudySession(
            id = id,
            subject = subject,
            topics = topics,
            scheduledFor = scheduledFor,
            duration = duration,
            isCompleted = isCompleted,
            completedAt = completedAt,
            qualityRating = qualityRating,
            notes = notes,
            createdAt = createdAt,
            userId = userId
        )
    }
}

fun StudySession.toEntity(): StudySessionEntity {
    return StudySessionEntity(
        id = id,
        subject = subject,
        topics = topics,
        scheduledFor = scheduledFor,
        duration = duration,
        isCompleted = isCompleted,
        completedAt = completedAt,
        qualityRating = qualityRating,
        notes = notes,
        createdAt = createdAt,
        userId = userId
    )
}