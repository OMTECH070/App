package com.studyplanner.app.di

import android.content.Context
import androidx.room.Room
import com.studyplanner.app.data.local.database.AppDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideAppDatabase(
        @ApplicationContext context: Context
    ): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "study_planner_database"
        ).build()
    }

    @Provides
    fun provideStudySessionDao(database: AppDatabase): com.studyplanner.app.data.local.dao.StudySessionDao {
        return database.studySessionDao()
    }

    @Provides
    fun provideStudyTaskDao(database: AppDatabase): com.studyplanner.app.data.local.dao.StudyTaskDao {
        return database.studyTaskDao()
    }

    @Provides
    fun provideUserSubjectDao(database: AppDatabase): com.studyplanner.app.data.local.dao.UserSubjectDao {
        return database.userSubjectDao()
    }

    @Provides
    fun provideUserDao(database: AppDatabase): com.studyplanner.app.data.local.dao.UserDao {
        return database.userDao()
    }
}