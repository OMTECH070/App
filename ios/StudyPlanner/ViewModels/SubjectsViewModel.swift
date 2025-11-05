import Foundation
import CoreData
import SwiftUI

@MainActor
class SubjectsViewModel: ObservableObject {
    @Published var subjects: [UserSubject] = []
    @Published var showAddSubject = false

    func loadSubjects(context: NSManagedObjectContext) {
        let request: NSFetchRequest<UserSubject> = UserSubject.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \UserSubject.isActive, ascending: false),
            NSSortDescriptor(keyPath: \UserSubject.priority, ascending: true),
            NSSortDescriptor(keyPath: \UserSubject.name, ascending: true)
        ]

        do {
            self.subjects = try context.fetch(request)
        } catch {
            print("Error loading subjects: \(error)")
            self.subjects = []
        }
    }

    func addSubject(_ subject: UserSubject, context: NSManagedObjectContext) {
        do {
            try context.save()
            loadSubjects(context: context)
        } catch {
            print("Error adding subject: \(error)")
        }
    }

    func toggleSubjectActivation(subject: UserSubject) {
        subject.isActive.toggle()

        do {
            try subject.managedObjectContext?.save()
            if let context = subject.managedObjectContext {
                loadSubjects(context: context)
            }
        } catch {
            print("Error toggling subject activation: \(error)")
        }
    }

    func deleteSubjects(offsets: IndexSet) {
        for index in offsets {
            let subject = subjects[index]
            subject.managedObjectContext?.delete(subject)
        }

        do {
            try subjects.first?.managedObjectContext?.save()
            if let context = subjects.first?.managedObjectContext {
                loadSubjects(context: context)
            }
        } catch {
            print("Error deleting subjects: \(error)")
        }
    }
}