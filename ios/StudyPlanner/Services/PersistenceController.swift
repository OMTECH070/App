import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for previews
        let user = User(context: viewContext)
        user.id = UUID()
        user.email = "test@example.com"
        user.displayName = "Test User"
        user.createdAt = Date()
        user.studyGoalHours = 8
        user.isPremium = true

        let subject = UserSubject(context: viewContext)
        subject.id = UUID()
        subject.name = "Mathematics"
        subject.color = "#FF6B6B"
        subject.priority = 1
        subject.difficulty = 3
        subject.isActive = true
        subject.user = user

        let session = StudySession(context: viewContext)
        session.id = UUID()
        session.subject = "Mathematics"
        session.scheduledFor = Date()
        session.duration = 3600 // 1 hour
        session.isCompleted = true
        session.createdAt = Date()
        session.completedAt = Date()
        session.user = user

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "StudyPlanner")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func saveBackground(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}