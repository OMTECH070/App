import Foundation
import CoreData
import SwiftUI

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var sessions: [StudySession] = []
    @Published var showAddSession = false

    func loadSchedule(for date: Date, context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        request.predicate = NSPredicate(format: "scheduledFor >= %@ AND scheduledFor < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StudySession.scheduledFor, ascending: true)]

        do {
            self.sessions = try context.fetch(request)
        } catch {
            print("Error loading schedule: \(error)")
            self.sessions = []
        }
    }

    func addSession(_ session: StudySession, context: NSManagedObjectContext) {
        do {
            try context.save()
            loadSchedule(for: session.scheduledFor ?? Date(), context: context)
        } catch {
            print("Error adding session: \(error)")
        }
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
            if let context = session.managedObjectContext {
                loadSchedule(for: session.scheduledFor ?? Date(), context: context)
            }
        } catch {
            print("Error toggling session completion: \(error)")
        }
    }

    func deleteSessions(offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            session.managedObjectContext?.delete(session)
        }

        do {
            try sessions.first?.managedObjectContext?.save()
            if let context = sessions.first?.managedObjectContext {
                loadSchedule(for: Date(), context: context)
            }
        } catch {
            print("Error deleting sessions: \(error)")
        }
    }
}