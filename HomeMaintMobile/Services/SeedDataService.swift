import Foundation

/// Service for seeding initial data
/// Creates default home, categories, and locations on first launch
class SeedDataService {

    static let shared = SeedDataService()

    private let homeRepo = HomeRepository()
    private let categoryRepo = CategoryRepository()
    private let locationRepo = LocationRepository()

    private init() {}

    // MARK: - Main Seed Function

    /// Seed database with initial data (idempotent - safe to call multiple times)
    /// Returns the created/existing home
    @discardableResult
    func seedIfNeeded() throws -> Home {
        // Get or create home
        let home: Home
        if let existingHome = try homeRepo.getFirst() {
            home = existingHome
            print("✅ Found existing home: \(existingHome.name)")
        } else {
            print("🌱 Creating new home...")
            home = try createDefaultHome()
        }

        // Ensure home has an ID
        guard let homeId = home.id else {
            throw SeedDataError.missingHomeId
        }

        // Check and create categories if needed
        let existingCategories = try categoryRepo.findByHomeId(homeId)
        if existingCategories.isEmpty {
            print("🌱 Seeding categories...")
            try createDefaultCategories(homeId: homeId)
        } else {
            print("✅ Found \(existingCategories.count) existing categories")
        }

        // Check and create locations if needed
        let existingLocations = try locationRepo.findByHomeId(homeId)
        if existingLocations.isEmpty {
            print("🌱 Seeding locations...")
            try createDefaultLocations(homeId: homeId)
        } else {
            print("✅ Found \(existingLocations.count) existing locations")
        }

        print("✅ Database seeding complete")
        return home
    }

    // MARK: - Private Seed Methods

    private func createDefaultHome() throws -> Home {
        return try homeRepo.create(
            name: "My Home",
            address: nil,
            purchaseDate: nil,
            squareFootage: nil
        )
    }

    private func createDefaultCategories(homeId: Int64) throws {
        let categories = [
            ("HVAC", "thermometer"),
            ("Plumbing", "drop"),
            ("Electrical", "bolt"),
            ("Appliances", "washer"),
            ("Exterior", "house"),
            ("Interior", "paintbrush"),
            ("Landscaping", "leaf"),
            ("Security", "lock"),
            ("Other", "ellipsis")
        ]

        for (name, icon) in categories {
            _ = try categoryRepo.create(homeId: homeId, name: name, icon: icon)
        }

        print("  ✓ Created \(categories.count) default categories")
    }

    private func createDefaultLocations(homeId: Int64) throws {
        let locations = [
            ("Kitchen", "1"),
            ("Living Room", "1"),
            ("Dining Room", "1"),
            ("Master Bedroom", "2"),
            ("Bedroom 2", "2"),
            ("Bathroom 1", "1"),
            ("Bathroom 2", "2"),
            ("Garage", "1"),
            ("Basement", "B"),
            ("Attic", "3"),
            ("Exterior", nil),
            ("Yard", nil)
        ]

        for (name, floor) in locations {
            _ = try locationRepo.create(homeId: homeId, name: name, floor: floor)
        }

        print("  ✓ Created \(locations.count) default locations")
    }

    // MARK: - Utility Methods

    /// Get or create home (auto-recovery helper)
    func getOrCreateHome() throws -> Home {
        if let home = try homeRepo.getFirst() {
            return home
        }
        return try seedIfNeeded()
    }
}

// MARK: - Error Types

enum SeedDataError: Error {
    case missingHomeId

    var localizedDescription: String {
        switch self {
        case .missingHomeId:
            return "Home does not have a valid ID"
        }
    }
}
