import SwiftUI
import CoreData
import Firebase
import UserNotifications
import WidgetKit

@main
struct StudyPlannerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notificationManager = NotificationManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authViewModel)
                .environmentObject(notificationManager)
                .onAppear {
                    notificationManager.requestAuthorization()
                }
        }
    }

    // Widget configuration
    var widgetScene: some Scene {
        WidgetKitScene("widgets", configuration: .init(kind: "StudyPlannerWidget", intent: .none))
    }
}