import SwiftUI

@main
struct HomeMaintMobileApp: App {

    init() {
        // Initialize database on app launch
        do {
            try DatabaseService.shared.initialize()

            // Seed initial data if needed
            try SeedDataService.shared.seedIfNeeded()
        } catch {
            print("❌ Failed to initialize app: \(error)")
            // In production, show error UI to user
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
