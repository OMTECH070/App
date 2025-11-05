import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Overview Section
                    ProgressOverviewSection(viewModel: homeViewModel)

                    // Today's Schedule Section
                    TodayScheduleSection(viewModel: homeViewModel)

                    // Quick Actions Section
                    QuickActionsSection(viewModel: homeViewModel)

                    // AI Insights Section
                    AIInsightsSection(viewModel: homeViewModel)

                    // Motivational Section
                    MotivationalSection(viewModel: homeViewModel)
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        homeViewModel.startStudySession()
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                homeViewModel.loadTodayData(context: viewContext)
            }
            .refreshable {
                homeViewModel.loadTodayData(context: viewContext)
            }
        }
    }
}

struct ProgressOverviewSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Progress")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(viewModel.completedSessions)/\(viewModel.totalSessions) sessions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Streak indicator
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(viewModel.currentStreak)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }

            // Circular Progress Indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.progressPercentage)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.progressPercentage)

                VStack {
                    Text("\(Int(viewModel.progressPercentage * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct TodayScheduleSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Schedule")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("View All") {
                    // Navigate to full schedule
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            if viewModel.todaySessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title)
                        .foregroundColor(.gray)

                    Text("No study sessions planned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Plan Your Day") {
                        viewModel.openSchedulePlanner()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.todaySessions.prefix(3), id: \.id) { session in
                        StudySessionRow(session: session) {
                            viewModel.toggleSessionCompletion(session: session)
                        }
                    }

                    if viewModel.todaySessions.count > 3 {
                        Button("View \(viewModel.todaySessions.count - 3) more sessions") {
                            // Navigate to full schedule
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct StudySessionRow: View {
    let session: StudySession
    let onToggle: () -> Void

    var body: some View {
        HStack {
            // Completion checkbox
            Button(action: onToggle) {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(session.isCompleted ? .green : .gray)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.subject ?? "Unknown Subject")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(formatTime(session.scheduledFor))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let topics = session.topics, !topics.isEmpty {
                    Text(topics)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text("\(session.duration / 60) min")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if session.isCompleted {
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColorForSubject(session.subject))
                .opacity(0.1)
        )
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func backgroundColorForSubject(_ subject: String?) -> Color {
        switch subject {
        case "Mathematics": return .red
        case "Physics": return .blue
        case "Chemistry": return .green
        case "Biology": return .purple
        default: return .orange
        }
    }
}

struct QuickActionsSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "Start Study",
                icon: "play.fill",
                color: .blue
            ) {
                viewModel.startStudySession()
            }

            QuickActionButton(
                title: "Add Task",
                icon: "plus",
                color: .green
            ) {
                viewModel.addQuickTask()
            }

            QuickActionButton(
                title: "View Stats",
                icon: "chart.bar",
                color: .orange
            ) {
                viewModel.viewAnalytics()
            }

            QuickActionButton(
                title: "Focus Mode",
                icon: "target",
                color: .red
            ) {
                viewModel.startFocusMode()
            }
        }
        .padding(.horizontal)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AIInsightsSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)

                Text("AI Insights")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            if let insight = viewModel.currentInsight {
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let actionable = insight.actionableTip {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)

                            Text(actionable)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("Analyzing your study patterns...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MotivationalSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.purple)

                Text("Daily Motivation")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            VStack(spacing: 8) {
                Text(viewModel.motivationalQuote.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Text("— \(viewModel.motivationalQuote.author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NotificationManager())
}