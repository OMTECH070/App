package com.studyplanner.app.data.local.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import android.content.Context
import com.studyplanner.app.data.local.converters.DateConverters
import com.studyplanner.app.data.local.entities.StudySessionEntity
import com.studyplanner.app.data.local.entities.StudyTaskEntity
import com.studyplanner.app.data.local.entities.UserSubjectEntity
import com.studyplanner.app.data.local.entities.UserEntity

@Database(
    entities = [
        StudySessionEntity::class,
        StudyTaskEntity::class,
        UserSubjectEntity::class,
        UserEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(DateConverters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun studySessionDao(): com.studyplanner.app.data.local.dao.StudySessionDao
    abstract fun studyTaskDao(): com.studyplanner.app.data.local.dao.StudyTaskDao
    abstract fun userSubjectDao(): com.studyplanner.app.data.local.dao.UserSubjectDao
    abstract fun userDao(): com.studyplanner.app.data.local.dao.UserDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "study_planner_database"
                )
                .addMigrations(MIGRATION_1_2)
                .build()
                INSTANCE = instance
                instance
            }
        }

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // Add new columns or tables in future migrations
            }
        }
    }
}