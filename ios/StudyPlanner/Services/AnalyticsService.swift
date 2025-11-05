import Foundation
import CoreData

class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    func calculateStudyProgress(for user: User, in context: NSManagedObjectContext) -> StudyProgress {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND scheduledFor >= %@ AND scheduledFor < %@", user, startOfDay as NSDate, endOfDay as NSDate)

        do {
            let sessions = try context.fetch(request)
            let completedSessions = sessions.filter { $0.isCompleted }
            let totalStudyTime = completedSessions.reduce(0) { $0 + $1.duration }

            return StudyProgress(
                completedSessions: completedSessions.count,
                totalSessions: sessions.count,
                totalStudyTime: totalStudyTime,
                progressPercentage: sessions.count > 0 ? Double(completedSessions.count) / Double(sessions.count) : 0.0
            )
        } catch {
            print("Error calculating study progress: \(error)")
            return StudyProgress(completedSessions: 0, totalSessions: 0, totalStudyTime: 0, progressPercentage: 0.0)
        }
    }

    func generateWeeklyAnalytics(for user: User, in context: NSManagedObjectContext) -> WeeklyAnalytics {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!

        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND scheduledFor >= %@ AND scheduledFor < %@", user, startOfWeek as NSDate, endOfWeek as NSDate)

        do {
            let sessions = try context.fetch(request)
            let completedSessions = sessions.filter { $0.isCompleted }
            let totalStudyTime = completedSessions.reduce(0) { $0 + $1.duration }

            // Group by subject
            let subjectGroups = Dictionary(grouping: completedSessions) { $0.subject ?? "Unknown" }
            let subjectBreakdown = subjectGroups.mapValues { sessions in
                sessions.reduce(0) { $0 + $1.duration }
            }

            return WeeklyAnalytics(
                totalStudyTime: totalStudyTime,
                completedSessions: completedSessions.count,
                totalSessions: sessions.count,
                subjectBreakdown: subjectBreakdown,
                averageDailyStudyTime: totalStudyTime / 7
            )
        } catch {
            print("Error generating weekly analytics: \(error)")
            return WeeklyAnalytics(totalStudyTime: 0, completedSessions: 0, totalSessions: 0, subjectBreakdown: [:], averageDailyStudyTime: 0)
        }
    }
}

// MARK: - Data Models
struct StudyProgress {
    let completedSessions: Int
    let totalSessions: Int
    let totalStudyTime: TimeInterval
    let progressPercentage: Double

    var formattedStudyTime: String {
        let hours = Int(totalStudyTime / 3600)
        let minutes = Int((totalStudyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

struct WeeklyAnalytics {
    let totalStudyTime: TimeInterval
    let completedSessions: Int
    let totalSessions: Int
    let subjectBreakdown: [String: TimeInterval]
    let averageDailyStudyTime: TimeInterval

    var formattedTotalTime: String {
        let hours = Int(totalStudyTime / 3600)
        let minutes = Int((totalStudyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    var formattedAverageTime: String {
        let hours = Int(averageDailyStudyTime / 3600)
        let minutes = Int((averageDailyStudyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}