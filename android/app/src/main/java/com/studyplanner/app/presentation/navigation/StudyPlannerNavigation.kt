package com.studyplanner.app.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.studyplanner.app.presentation.ui.auth.AuthScreen
import com.studyplanner.app.presentation.ui.auth.AuthViewModel
import com.studyplanner.app.presentation.ui.home.HomeScreen
import com.studyplanner.app.presentation.ui.profile.ProfileScreen
import com.studyplanner.app.presentation.ui.progress.ProgressScreen
import com.studyplanner.app.presentation.ui.schedule.ScheduleScreen
import com.studyplanner.app.presentation.ui.subjects.SubjectsScreen

@Composable
fun StudyPlannerNavigation(
    navController: NavHostController = rememberNavController()
) {
    val authViewModel: AuthViewModel = hiltViewModel()
    val isAuthenticated by authViewModel.isAuthenticated.collectAsState()

    NavHost(
        navController = navController,
        startDestination = if (isAuthenticated) "main" else "auth"
    ) {
        composable("auth") {
            AuthScreen(
                onAuthSuccess = {
                    navController.navigate("main") {
                        popUpTo("auth") { inclusive = true }
                    }
                }
            )
        }

        composable("main") {
            MainNavigation()
        }
    }
}

@Composable
fun MainNavigation() {
    val navController = rememberNavController()

    NavHost(
        navController = navController,
        startDestination = "home"
    ) {
        composable("home") {
            HomeScreen()
        }
        composable("schedule") {
            ScheduleScreen()
        }
        composable("subjects") {
            SubjectsScreen()
        }
        composable("progress") {
            ProgressScreen()
        }
        composable("profile") {
            ProfileScreen()
        }
    }
}