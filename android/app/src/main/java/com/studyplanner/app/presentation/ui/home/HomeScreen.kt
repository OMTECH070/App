package com.studyplanner.app.presentation.ui.home

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.studyplanner.app.presentation.components.StudySessionCard
import com.studyplanner.app.presentation.components.QuickActionButton
import com.studyplanner.app.presentation.components.StreakCard
import com.studyplanner.app.presentation.components.AIInsightCard
import com.studyplanner.app.domain.models.StudySession

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    viewModel: HomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Today") },
                actions = {
                    IconButton(onClick = { viewModel.startStudySession() }) {
                        Icon(Icons.Default.PlayArrow, contentDescription = "Start Study")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { viewModel.openSchedulePlanner() }
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Session")
            }
        )
    { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                // Progress Overview Section
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Today's Progress",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = MaterialTheme.typography.headlineSmall.fontWeight
                        )
                        Text(
                            text = "${uiState.completedSessions}/${uiState.totalSessions} sessions completed",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    StreakCard(streak = uiState.currentStreak)
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Progress Bar
                LinearProgressIndicator(
                    progress = uiState.progressPercentage,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp),
                )
            }

            item {
                // Quick Actions
                Text(
                    text = "Quick Actions",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = MaterialTheme.typography.titleMedium.fontWeight
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    QuickActionButton(
                        text = "Start Study",
                        icon = Icons.Default.PlayArrow,
                        onClick = { viewModel.startStudySession() },
                        modifier = Modifier.weight(1f)
                    )
                    QuickActionButton(
                        text = "Add Task",
                        icon = Icons.Default.Add,
                        onClick = { viewModel.addQuickTask() },
                        modifier = Modifier.weight(1f)
                    )
                    QuickActionButton(
                        text = "View Stats",
                        icon = Icons.Default.BarChart,
                        onClick = { viewModel.viewAnalytics() },
                        modifier = Modifier.weight(1f)
                    )
                    QuickActionButton(
                        text = "Focus Mode",
                        icon = Icons.Default.Timer,
                        onClick = { viewModel.startFocusMode() },
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            item {
                // Today's Schedule
                Text(
                    text = "Today's Schedule",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = MaterialTheme.typography.titleMedium.fontWeight
                )
            }

            if (uiState.todaySessions.isEmpty()) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                Icons.Default.CalendarToday,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "No study sessions planned",
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = "Add your first study session to get started",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Button(onClick = { viewModel.openSchedulePlanner() }) {
                                Text("Plan Your Day")
                            }
                        }
                    }
                }
            } else {
                items(uiState.todaySessions) { session ->
                    StudySessionCard(
                        session = session,
                        onToggleComplete = { viewModel.toggleSessionCompletion(session) },
                        onStartSession = { viewModel.startSession(session) }
                    )
                }
            }

            item {
                // AI Insights
                uiState.currentInsight?.let { insight ->
                    AIInsightCard(insight = insight)
                }
            }

            item {
                // Motivational Quote
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Default.FormatQuote,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Daily Motivation",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = MaterialTheme.typography.titleMedium.fontWeight
                            )
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = uiState.motivationalQuote.text,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = MaterialTheme.typography.bodyMedium.fontWeight
                        )
                        Text(
                            text = "— ${uiState.motivationalQuote.author}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}