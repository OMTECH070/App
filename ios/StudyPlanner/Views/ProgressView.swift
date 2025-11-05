import SwiftUI
import Charts

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var progressViewModel = ProgressViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overview Cards
                    OverviewSection(viewModel: progressViewModel)

                    // Weekly Chart
                    WeeklyChartSection(viewModel: progressViewModel)

                    // Subject Breakdown
                    SubjectBreakdownSection(viewModel: progressViewModel)

                    // Recent Achievements
                    AchievementsSection(viewModel: progressViewModel)
                }
                .padding()
            }
            .navigationTitle("Progress")
            .onAppear {
                progressViewModel.loadProgressData(context: viewContext)
            }
            .refreshable {
                progressViewModel.loadProgressData(context: viewContext)
            }
        }
    }
}

struct OverviewSection: View {
    @ObservedObject var viewModel: ProgressViewModel

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            OverviewCard(
                title: "Total Study Time",
                value: viewModel.formattedTotalTime,
                subtitle: "This week",
                icon: "clock.fill",
                color: .blue
            )

            OverviewCard(
                title: "Study Streak",
                value: "\(viewModel.currentStreak)",
                subtitle: "Days in a row",
                icon: "flame.fill",
                color: .orange
            )

            OverviewCard(
                title: "Sessions Completed",
                value: "\(viewModel.completedSessions)",
                subtitle: "This week",
                icon: "checkmark.circle.fill",
                color: .green
            )

            OverviewCard(
                title: "Average Daily",
                value: viewModel.formattedAverageTime,
                subtitle: "Study time",
                icon: "chart.bar.fill",
                color: .purple
            )
        }
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WeeklyChartSection: View {
    @ObservedObject var viewModel: ProgressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
                .fontWeight(.semibold)

            Chart(viewModel.weeklyData) { data in
                BarMark(
                    x: .value("Day", data.day.prefix(3)),
                    y: .value("Hours", data.hours)
                )
                .foregroundStyle(Color.blue.gradient)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisValueLabel() {
                        Text("\($0.as(Int.self) ?? 0)h")
                            .font(.caption)
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

struct SubjectBreakdownSection: View {
    @ObservedObject var viewModel: ProgressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subject Breakdown")
                .font(.headline)
                .fontWeight(.semibold)

            ForEach(viewModel.subjectBreakdown, id: \.subject) { data in
                SubjectBreakdownRow(data: data)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SubjectBreakdownRow: View {
    let data: SubjectBreakdownData

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(data.subject)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(data.formattedTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: data.percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: data.color)))
                .scaleEffect(x: 1, y: 0.8)
        }
    }
}

struct AchievementsSection: View {
    @ObservedObject var viewModel: ProgressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Achievements")
                .font(.headline)
                .fontWeight(.semibold)

            if viewModel.achievements.isEmpty {
                Text("Keep studying to unlock achievements!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(viewModel.achievements.prefix(4), id: \.id) { achievement in
                        AchievementCard(achievement: achievement)
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

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? achievement.color : .gray)

            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)

            if achievement.isUnlocked {
                Text("Unlocked")
                    .font(.caption2)
                    .foregroundColor(achievement.color)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(achievement.isUnlocked ? achievement.color.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.isUnlocked ? achievement.color : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    ProgressView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}