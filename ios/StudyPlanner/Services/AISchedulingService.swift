import Foundation
import CoreData

class AISchedulingService {
    static let shared = AISchedulingService()

    private init() {}

    func generateDailyInsight(context: NSManagedObjectContext) async throws -> AIInsight {
        // Simulate AI processing delay
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let insights = [
            AIInsight(
                title: "Peak Performance Time",
                description: "Your study efficiency is highest between 7-9 PM. Schedule important topics during this time.",
                actionableTip: "Move Mathematics to 7:30 PM for better retention."
            ),
            AIInsight(
                title: "Study Pattern Analysis",
                description: "You've been consistent with daily study sessions this week. Keep up the great work!",
                actionableTip: "Consider adding a 30-minute review session on weekends."
            ),
            AIInsight(
                title: "Subject Balance",
                description: "You're spending 60% more time on Physics than other subjects. Consider balancing your schedule.",
                actionableTip: "Dedicate equal time to Chemistry and Biology this week."
            ),
            AIInsight(
                title: "Burnout Prevention",
                description: "You've studied for 6 consecutive days. Consider taking a rest day tomorrow.",
                actionableTip: "A rest day can improve retention by 20%."
            ),
            AIInsight(
                title: "Optimal Session Length",
                description: "Your 45-minute sessions have the highest completion rates.",
                actionableTip: "Break longer study blocks into 45-minute chunks with 10-minute breaks."
            )
        ]

        return insights.randomElement() ?? insights[0]
    }

    func generateOptimalSchedule(for user: User, in context: NSManagedObjectContext) async throws -> [StudySession] {
        // This is a simplified version - the actual AI would consider:
        // - User's historical performance data
        // - Subject difficulty and mastery levels
        // - Optimal study times based on circadian rhythm
        // - Spaced repetition intervals
        // - Upcoming exam dates

        let subjects = try getUserSubjects(user: user, in: context)
        var sessions: [StudySession] = []

        let calendar = Calendar.current
        let today = Date()

        for (index, subject) in subjects.enumerated() {
            let session = StudySession(context: context)
            session.id = UUID()
            session.subject = subject.name
            session.user = user
            session.createdAt = Date()
            session.isCompleted = false

            // Schedule based on subject priority and optimal times
            let baseTime = calendar.date(byAdding: .hour, value: 9 + (index * 2), to: today)!
            session.scheduledFor = baseTime
            session.duration = TimeInterval(subject.masteryLevel < 0.5 ? 3600 : 2700) // Longer sessions for difficult subjects

            // Generate topics based on subject
            session.topics = generateTopicsForSubject(subject.name)

            sessions.append(session)
        }

        return sessions
    }

    private func getUserSubjects(user: User, in context: NSManagedObjectContext) throws -> [UserSubject] {
        let request: NSFetchRequest<UserSubject> = UserSubject.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND isActive == true", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserSubject.priority, ascending: true)]

        return try context.fetch(request)
    }

    private func generateTopicsForSubject(_ subject: String?) -> String {
        guard let subject = subject else { return "General Topics" }

        let topics: [String] = {
            switch subject {
            case "Mathematics":
                return ["Calculus", "Linear Algebra", "Statistics", "Geometry"]
            case "Physics":
                return ["Mechanics", "Thermodynamics", "Electromagnetism", "Quantum Physics"]
            case "Chemistry":
                return ["Organic Chemistry", "Inorganic Chemistry", "Physical Chemistry", "Analytical Chemistry"]
            case "Biology":
                return ["Cell Biology", "Genetics", "Ecology", "Human Anatomy"]
            default:
                return ["Topic 1", "Topic 2", "Topic 3"]
            }
        }()

        return topics.shuffled().prefix(2).joined(separator: ", ")
    }

    func adjustScheduleBasedOnPerformance(sessions: [StudySession], context: NSManagedObjectContext) async {
        // Analyze recent performance and adjust future sessions
        for session in sessions where !session.isCompleted {
            // Check if session is overdue and needs rescheduling
            if let scheduledFor = session.scheduledFor, scheduledFor < Date() {
                // Reschedule to next available time slot
                let newTime = Calendar.current.date(byAdding: .hour, value: 24, to: scheduledFor)!
                session.scheduledFor = newTime
            }
        }

        do {
            try context.save()
        } catch {
            print("Error adjusting schedule: \(error)")
        }
    }

    func predictExamPerformance(for subject: String, user: User, in context: NSManagedObjectContext) async -> ExamPrediction {
        // Analyze study patterns, session completion rates, and subject mastery
        // to predict exam performance

        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND subject == %@ AND isCompleted == true", user, subject)

        do {
            let sessions = try context.fetch(request)
            let totalStudyTime = sessions.reduce(0) { $0 + $1.duration }
            let averageSessionQuality = sessions.reduce(0) { $0 + ($1.qualityRating ?? 3) } / Double(sessions.count)

            let score = min(100, max(0, (totalStudyTime / 36000 * 50) + (averageSessionQuality / 5.0 * 50)))

            return ExamPrediction(
                subject: subject,
                predictedScore: Int(score),
                confidenceLevel: sessions.count > 10 ? 0.8 : 0.5,
                recommendedStudyTime: max(0, 20000 - totalStudyTime),
                weakAreas: identifyWeakAreas(for: subject, sessions: sessions)
            )
        } catch {
            return ExamPrediction(
                subject: subject,
                predictedScore: 0,
                confidenceLevel: 0.0,
                recommendedStudyTime: 20000,
                weakAreas: []
            )
        }
    }

    private func identifyWeakAreas(for subject: String, sessions: [StudySession]) -> [String] {
        // This would analyze performance data to identify weak areas
        // For now, return generic areas based on subject
        switch subject {
        case "Mathematics":
            return ["Calculus", "Statistics"]
        case "Physics":
            return ["Quantum Mechanics", "Thermodynamics"]
        case "Chemistry":
            return ["Organic Chemistry", "Physical Chemistry"]
        default:
            return []
        }
    }
}

// MARK: - Data Models
struct AIInsight {
    let title: String
    let description: String
    let actionableTip: String?
}

struct ExamPrediction {
    let subject: String
    let predictedScore: Int
    let confidenceLevel: Double
    let recommendedStudyTime: TimeInterval
    let weakAreas: [String]

    var formattedRecommendedTime: String {
        let hours = Int(recommendedStudyTime / 3600)
        let minutes = Int((recommendedStudyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    var confidencePercentage: Int {
        Int(confidenceLevel * 100)
    }
}