import SwiftUI

// AppDelegate to handle app lifecycle
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize database BEFORE any views are created
        do {
            try DatabaseService.shared.initialize()

            // Seed initial data if needed
            try SeedDataService.shared.seedIfNeeded()

            print("✅ App initialization complete")
        } catch {
            print("❌ Failed to initialize app: \(error)")
            fatalError("Database initialization failed: \(error)")
        }
        return true
    }
}

@main
struct HomeMaintMobileApp: App {

    // Use UIApplicationDelegateAdaptor to ensure database is initialized first
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
