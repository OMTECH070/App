import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var profileViewModel = ProfileViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderSection(viewModel: profileViewModel)

                    // Study Goals
                    StudyGoalsSection(viewModel: profileViewModel)

                    // Settings
                    SettingsSection(viewModel: profileViewModel)

                    // Premium Section
                    PremiumSection(viewModel: profileViewModel)

                    // About Section
                    AboutSection()

                    // Sign Out Button
                    SignOutSection()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .onAppear {
                profileViewModel.loadProfileData(context: viewContext)
            }
        }
    }
}

struct ProfileHeaderSection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: URL(string: viewModel.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(viewModel.displayName?.prefix(2)?.uppercased() ?? "U"))
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())

            // User Info
            VStack(spacing: 4) {
                Text(viewModel.displayName ?? "Study Planner User")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(viewModel.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Stats
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(viewModel.totalStudyDays)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Study Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(viewModel.totalHours)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Hours Studied")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(viewModel.currentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Day Streak")
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

struct StudyGoalsSection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Goals")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                GoalRow(
                    title: "Daily Study Goal",
                    value: "\(viewModel.dailyGoal) hours",
                    icon: "target",
                    color: .blue
                ) {
                    viewModel.showEditDailyGoal = true
                }

                GoalRow(
                    title: "Weekly Study Goal",
                    value: "\(viewModel.weeklyGoal) hours",
                    icon: "calendar.badge.clock",
                    color: .green
                ) {
                    viewModel.showEditWeeklyGoal = true
                }

                GoalRow(
                    title: "Preferred Study Time",
                    value: viewModel.preferredStudyTime,
                    icon: "clock.fill",
                    color: .orange
                ) {
                    viewModel.showEditPreferredTime = true
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct GoalRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsSection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 0) {
                SettingRow(
                    title: "Notifications",
                    icon: "bell.fill",
                    color: .red,
                    isToggle: true,
                    isOn: viewModel.notificationsEnabled
                ) {
                    viewModel.toggleNotifications()
                }

                Divider()

                SettingRow(
                    title: "Focus Mode",
                    icon: "target",
                    color: .orange,
                    isToggle: true,
                    isOn: viewModel.focusModeEnabled
                ) {
                    viewModel.toggleFocusMode()
                }

                Divider()

                SettingRow(
                    title: "Study Reminders",
                    icon: "clock.badge.alarm",
                    color: .blue
                ) {
                    // Navigate to reminder settings
                }

                Divider()

                SettingRow(
                    title: "Data & Privacy",
                    icon: "lock.shield",
                    color: .green
                ) {
                    // Navigate to privacy settings
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SettingRow: View {
    let title: String
    let icon: String
    let color: Color
    let isToggle: Bool
    let isOn: Bool?
    let onTap: () -> Void

    init(title: String, icon: String, color: Color, isToggle: Bool = false, isOn: Bool = false, onTap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isToggle = isToggle
        self.isOn = isToggle ? isOn : nil
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if isToggle, let isOn = isOn {
                    Toggle("", isOn: Binding(
                        get: { isOn },
                        set: { _ in onTap() }
                    ))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PremiumSection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Premium Features")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if !viewModel.isPremium {
                    Button("Upgrade") {
                        viewModel.showPremiumUpgrade = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            if viewModel.isPremium {
                VStack(alignment: .leading, spacing: 8) {
                    PremiumFeatureRow(icon: "brain.head.profile", title: "AI Scheduling", isEnabled: true)
                    PremiumFeatureRow(icon: "chart.bar.2.xaxis", title: "Advanced Analytics", isEnabled: true)
                    PremiumFeatureRow(icon: "speaker.wave.3.fill", title: "Voice Notifications", isEnabled: true)
                    PremiumFeatureRow(icon: "doc.text.fill", title: "Export Reports", isEnabled: true)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    PremiumFeatureRow(icon: "brain.head.profile", title: "AI Scheduling", isEnabled: false)
                    PremiumFeatureRow(icon: "chart.bar.2.xaxis", title: "Advanced Analytics", isEnabled: false)
                    PremiumFeatureRow(icon: "speaker.wave.3.fill", title: "Voice Notifications", isEnabled: false)
                    PremiumFeatureRow(icon: "doc.text.fill", title: "Export Reports", isEnabled: false)
                }

                Button("Unlock All Premium Features") {
                    viewModel.showPremiumUpgrade = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(viewModel.isPremium ? Color.green.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.isPremium ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let isEnabled: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .green : .gray)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(isEnabled ? .primary : .secondary)

            Spacer()

            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
}

struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                AboutRow(title: "Version", value: "1.0.0")
                AboutRow(title: "Build", value: "1")
                AboutRow(title: "Developer", value: "Study Planner Team")
                AboutRow(title: "Contact", value: "support@studyplanner.app")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AboutRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

struct SignOutSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Button(action: {
            authViewModel.signOut()
        }) {
            Text("Sign Out")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red)
                .cornerRadius(12)
        }
        .padding(.top, 20)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}