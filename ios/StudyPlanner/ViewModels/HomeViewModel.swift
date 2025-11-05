import Foundation
import CoreData
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var todaySessions: [StudySession] = []
    @Published var completedSessions = 0
    @Published var totalSessions = 0
    @Published var currentStreak = 0
    @Published var progressPercentage: Double = 0.0
    @Published var currentInsight: AIInsight?
    @Published var motivationalQuote = MotivationalQuote(text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier")

    private let analyticsService = AnalyticsService()
    private let aiService = AISchedulingService()

    func loadTodayData(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "scheduledFor >= %@ AND scheduledFor < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StudySession.scheduledFor, ascending: true)]

        do {
            let sessions = try context.fetch(request)
            self.todaySessions = sessions

            self.totalSessions = sessions.count
            self.completedSessions = sessions.filter { $0.isCompleted }.count
            self.progressPercentage = totalSessions > 0 ? Double(completedSessions) / Double(totalSessions) : 0.0

            // Load streak data
            loadStreakData(context: context)

            // Generate AI insights
            generateAIInsight(context: context)

            // Load motivational content
            loadMotivationalContent()

        } catch {
            print("Error loading today's data: \(error)")
        }
    }

    private func loadStreakData(context: NSManagedObjectContext) {
        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StudySession.completedAt, ascending: false)]

        do {
            let sessions = try context.fetch(request)
            let completedSessions = sessions.filter { $0.isCompleted && $0.completedAt != nil }

            currentStreak = calculateStreak(from: completedSessions.map { $0.completedAt! })
        } catch {
            print("Error loading streak data: \(error)")
        }
    }

    private func calculateStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 1
        var currentDate = calendar.startOfDay(for: dates[0])

        for date in dates.dropFirst() {
            let nextDate = calendar.startOfDay(for: date)
            let daysBetween = calendar.dateComponents([.day], from: nextDate, to: currentDate).day ?? 0

            if daysBetween == 1 {
                streak += 1
                currentDate = nextDate
            } else if daysBetween > 1 {
                break
            }
        }

        return streak
    }

    private func generateAIInsight(context: NSManagedObjectContext) {
        Task {
            do {
                let insight = try await aiService.generateDailyInsight(context: context)
                DispatchQueue.main.async {
                    self.currentInsight = insight
                }
            } catch {
                print("Error generating AI insight: \(error)")
            }
        }
    }

    private func loadMotivationalContent() {
        let quotes = [
            MotivationalQuote(text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier"),
            MotivationalQuote(text: "The expert in anything was once a beginner.", author: "Helen Hayes"),
            MotivationalQuote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson"),
            MotivationalQuote(text: "The future depends on what you do today.", author: "Mahatma Gandhi"),
            MotivationalQuote(text: "Education is the most powerful weapon which you can use to change the world.", author: "Nelson Mandela")
        ]

        motivationalQuote = quotes.randomElement() ?? motivationalQuote
    }

    func startStudySession() {
        // Navigate to study session view
        NotificationCenter.default.post(name: .startStudySession, object: nil)
    }

    func addQuickTask() {
        // Navigate to add task view
        NotificationCenter.default.post(name: .addTask, object: nil)
    }

    func viewAnalytics() {
        // Navigate to analytics view
        NotificationCenter.default.post(name: .viewAnalytics, object: nil)
    }

    func startFocusMode() {
        // Start focus mode
        NotificationCenter.default.post(name: .startFocusMode, object: nil)
    }

    func openSchedulePlanner() {
        // Navigate to schedule planner
        NotificationCenter.default.post(name: .openSchedulePlanner, object: nil)
    }

    func toggleSessionCompletion(session: StudySession) {
        session.isCompleted.toggle()
        if session.isCompleted {
            session.completedAt = Date()
        } else {
            session.completedAt = nil
        }

        do {
            try session.managedObjectContext?.save()
            // Refresh data
            if let context = session.managedObjectContext {
                loadTodayData(context: context)
            }
        } catch {
            print("Error toggling session completion: \(error)")
        }
    }
}

// MARK: - Supporting Types
struct AIInsight {
    let title: String
    let description: String
    let actionableTip: String?
}

struct MotivationalQuote {
    let text: String
    let author: String
}

// MARK: - Notification Names
extension Notification.Name {
    static let startStudySession = Notification.Name("startStudySession")
    static let addTask = Notification.Name("addTask")
    static let viewAnalytics = Notification.Name("viewAnalytics")
    static let startFocusMode = Notification.Name("startFocusMode")
    static let openSchedulePlanner = Notification.Name("openSchedulePlanner")
}