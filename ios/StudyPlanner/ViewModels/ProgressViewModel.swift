import Foundation
import CoreData
import SwiftUI

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var weeklyData: [WeeklyData] = []
    @Published var subjectBreakdown: [SubjectBreakdownData] = []
    @Published var achievements: [Achievement] = []
    @Published var totalTime: TimeInterval = 0
    @Published var completedSessions = 0
    @Published var currentStreak = 0
    @Published var averageTime: TimeInterval = 0

    private let analyticsService = AnalyticsService.shared

    func loadProgressData(context: NSManagedObjectContext) {
        loadWeeklyData(context: context)
        loadSubjectBreakdown(context: context)
        loadAchievements(context: context)
        loadOverviewStats(context: context)
    }

    private func loadWeeklyData(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()

        var weekData: [WeeklyData] = []

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: date)!

            let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
            request.predicate = NSPredicate(format: "isCompleted == true AND completedAt >= %@ AND completedAt < %@", date as NSDate, endOfDay as NSDate)

            do {
                let sessions = try context.fetch(request)
                let totalHours = sessions.reduce(0) { $0 + ($1.duration / 3600) }

                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"

                weekData.append(WeeklyData(
                    day: formatter.string(from: date),
                    hours: totalHours
                ))
            } catch {
                print("Error loading weekly data: \(error)")
                weekData.append(WeeklyData(day: formatter.string(from: date), hours: 0))
            }
        }

        self.weeklyData = weekData
    }

    private func loadSubjectBreakdown(context: NSManagedObjectContext) {
        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == true")

        do {
            let sessions = try context.fetch(request)
            let groupedSessions = Dictionary(grouping: sessions) { $0.subject ?? "Unknown" }

            let totalStudyTime = sessions.reduce(0) { $0 + $1.duration }

            var breakdown: [SubjectBreakdownData] = groupedSessions.map { subject, sessions in
                let subjectTime = sessions.reduce(0) { $0 + $1.duration }
                let percentage = totalStudyTime > 0 ? Double(subjectTime) / Double(totalStudyTime) : 0

                return SubjectBreakdownData(
                    subject: subject,
                    time: subjectTime,
                    percentage: percentage,
                    color: colorForSubject(subject)
                )
            }

            breakdown.sort { $0.time > $1.time }
            self.subjectBreakdown = breakdown
        } catch {
            print("Error loading subject breakdown: \(error)")
            self.subjectBreakdown = []
        }
    }

    private func loadAchievements(context: NSManagedObjectContext) {
        // In a real app, this would query from a dedicated Achievement entity
        // For now, we'll generate some sample achievements based on user data
        var achievements: [Achievement] = [
            Achievement(id: "first_session", title: "First Study Session", icon: "star.fill", color: .yellow, isUnlocked: false),
            Achievement(id: "week_streak", title: "7 Day Streak", icon: "flame.fill", color: .orange, isUnlocked: false),
            Achievement(id: "100_hours", title: "100 Hours Studied", icon: "clock.fill", color: .blue, isUnlocked: false),
            Achievement(id: "math_master", title: "Mathematics Master", icon: "brain.head.profile", color: .purple, isUnlocked: false),
            Achievement(id: "early_bird", title: "Early Bird", icon: "sunrise.fill", color: .green, isUnlocked: false),
            Achievement(id: "night_owl", title: "Night Owl", icon: "moon.fill", color: .indigo, isUnlocked: false)
        ]

        // Check achievements based on actual data
        checkAchievements(achievements: &achievements, context: context)

        self.achievements = achievements
    }

    private func checkAchievements(achievements: inout [Achievement], context: NSManagedObjectContext) {
        do {
            let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
            request.predicate = NSPredicate(format: "isCompleted == true")

            let sessions = try context.fetch(request)
            let totalHours = sessions.reduce(0) { $0 + ($1.duration / 3600) }
            let streak = calculateStreak(sessions: sessions)

            // Check achievements
            if !sessions.isEmpty {
                achievements[0].isUnlocked = true // First session
            }

            if streak >= 7 {
                achievements[1].isUnlocked = true // Week streak
            }

            if totalHours >= 100 {
                achievements[2].isUnlocked = true // 100 hours
            }

            // Check if user has studied Mathematics
            let mathSessions = sessions.filter { $0.subject == "Mathematics" }
            if mathSessions.reduce(0) { $0 + ($1.duration / 3600) } >= 50 {
                achievements[3].isUnlocked = true // Math master
            }

            // Check early bird (sessions before 9 AM)
            let earlySessions = sessions.filter { session in
                guard let completedAt = session.completedAt else { return false }
                let hour = Calendar.current.component(.hour, from: completedAt)
                return hour < 9
            }
            if earlySessions.count >= 10 {
                achievements[4].isUnlocked = true // Early bird
            }

            // Check night owl (sessions after 9 PM)
            let nightSessions = sessions.filter { session in
                guard let completedAt = session.completedAt else { return false }
                let hour = Calendar.current.component(.hour, from: completedAt)
                return hour >= 21
            }
            if nightSessions.count >= 10 {
                achievements[5].isUnlocked = true // Night owl
            }

        } catch {
            print("Error checking achievements: \(error)")
        }
    }

    private func loadOverviewStats(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!

        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == true AND completedAt >= %@ AND completedAt < %@", startOfWeek as NSDate, endOfWeek as NSDate)

        do {
            let sessions = try context.fetch(request)

            self.totalTime = sessions.reduce(0) { $0 + $1.duration }
            self.completedSessions = sessions.count
            self.currentStreak = calculateStreak(sessions: sessions)
            self.averageTime = totalTime / 7

        } catch {
            print("Error loading overview stats: \(error)")
        }
    }

    private func calculateStreak(sessions: [StudySession]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let completedDates = sessions.compactMap { $0.completedAt }
            .map { calendar.startOfDay(for: $0) }
            .sorted { $0 > $1 }

        guard let firstDate = completedDates.first else { return 0 }

        var streak = 1
        var currentDate = firstDate

        for date in completedDates.dropFirst() {
            let daysBetween = calendar.dateComponents([.day], from: date, to: currentDate).day ?? 0

            if daysBetween == 1 {
                streak += 1
                currentDate = date
            } else if daysBetween > 1 {
                break
            }
        }

        return streak
    }

    private func colorForSubject(_ subject: String) -> String {
        switch subject {
        case "Mathematics": return "#FF3B30"
        case "Physics": return "#007AFF"
        case "Chemistry": return "#34C759"
        case "Biology": return "#AF52DE"
        case "Computer Science": return "#FF9500"
        default: return "#8E8E93"
        }
    }

    // Computed properties for formatted values
    var formattedTotalTime: String {
        let hours = Int(totalTime / 3600)
        let minutes = Int((totalTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    var formattedAverageTime: String {
        let hours = Int(averageTime / 3600)
        let minutes = Int((averageTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Data Models
struct WeeklyData {
    let day: String
    let hours: Double
}

struct SubjectBreakdownData {
    let subject: String
    let time: TimeInterval
    let percentage: Double
    let color: String

    var formattedTime: String {
        let hours = Int(time / 3600)
        let minutes = Int((time.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

struct Achievement {
    let id: String
    let title: String
    let icon: String
    let color: Color
    var isUnlocked: Bool
}