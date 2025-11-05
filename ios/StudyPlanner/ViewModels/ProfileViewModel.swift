import Foundation
import CoreData
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var displayName: String?
    @Published var email: String?
    @Published var profileImageURL: String?
    @Published var isPremium = false
    @Published var totalStudyDays = 0
    @Published var totalHours = 0
    @Published var currentStreak = 0
    @Published var dailyGoal = 6
    @Published var weeklyGoal = 35
    @Published var preferredStudyTime = "Evening (7-9 PM)"
    @Published var notificationsEnabled = true
    @Published var focusModeEnabled = false

    @Published var showEditDailyGoal = false
    @Published var showEditWeeklyGoal = false
    @Published var showEditPreferredTime = false
    @Published var showPremiumUpgrade = false

    func loadProfileData(context: NSManagedObjectContext) {
        // Load user profile data
        loadUserData(context: context)
        loadStudyStats(context: context)
        loadUserPreferences(context: context)
    }

    private func loadUserData(context: NSManagedObjectContext) {
        // In a real app, this would load from Firebase Auth and Core Data
        self.displayName = "Study Planner User"
        self.email = "user@studyplanner.app"
        self.profileImageURL = nil
        self.isPremium = false // This would be loaded from user's subscription status
    }

    private func loadStudyStats(context: NSManagedObjectContext) {
        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == true")

        do {
            let sessions = try context.fetch(request)

            // Calculate total hours
            let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
            self.totalHours = Int(totalSeconds / 3600)

            // Calculate study days
            let uniqueDays = Set(sessions.compactMap { session in
                guard let completedAt = session.completedAt else { return nil }
                return Calendar.current.startOfDay(for: completedAt)
            })
            self.totalStudyDays = uniqueDays.count

            // Calculate current streak
            self.currentStreak = calculateCurrentStreak(sessions: sessions)

        } catch {
            print("Error loading study stats: \(error)")
        }
    }

    private func calculateCurrentStreak(sessions: [StudySession]) -> Int {
        let completedSessions = sessions.filter { $0.completedAt != nil }
        guard !completedSessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDates = completedSessions
            .compactMap { $0.completedAt }
            .map { calendar.startOfDay(for: $0) }
            .sorted { $0 > $1 }

        guard let today = calendar.startOfDay(for: Date()) else { return 0 }

        var streak = 0
        var currentDate = today

        for date in sortedDates {
            let daysBetween = calendar.dateComponents([.day], from: date, to: currentDate).day ?? 0

            if daysBetween == 0 {
                streak += 1
            } else if daysBetween == 1 {
                streak += 1
                currentDate = date
            } else {
                break
            }
        }

        return streak
    }

    private func loadUserPreferences(context: NSManagedObjectContext) {
        // In a real app, this would load from Core Data or Firebase
        self.dailyGoal = 6
        self.weeklyGoal = 35
        self.preferredStudyTime = "Evening (7-9 PM)"
        self.notificationsEnabled = true
        self.focusModeEnabled = false
    }

    func toggleNotifications() {
        notificationsEnabled.toggle()
        saveUserPreferences()
    }

    func toggleFocusMode() {
        focusModeEnabled.toggle()
        saveUserPreferences()
    }

    func updateDailyGoal(_ newGoal: Int) {
        dailyGoal = newGoal
        saveUserPreferences()
    }

    func updateWeeklyGoal(_ newGoal: Int) {
        weeklyGoal = newGoal
        saveUserPreferences()
    }

    func updatePreferredStudyTime(_ newTime: String) {
        preferredStudyTime = newTime
        saveUserPreferences()
    }

    private func saveUserPreferences() {
        // In a real app, this would save to Core Data or Firebase
        print("Saving user preferences...")
    }

    func upgradeToPremium() {
        // In a real app, this would trigger the subscription flow
        // For now, we'll just simulate it
        isPremium = true
        showPremiumUpgrade = false
    }
}