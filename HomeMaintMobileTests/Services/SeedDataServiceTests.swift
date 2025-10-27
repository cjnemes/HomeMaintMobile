import XCTest
@testable import HomeMaintMobile
import GRDB

final class SeedDataServiceTests: XCTestCase {

    var seedService: SeedDataService!
    var homeRepo: HomeRepository!
    var categoryRepo: CategoryRepository!
    var locationRepo: LocationRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        seedService = SeedDataService.shared
        homeRepo = HomeRepository()
        categoryRepo = CategoryRepository()
        locationRepo = LocationRepository()
    }

    override func tearDownWithError() throws {
        // Clean up test data
        try? DatabaseService.shared.resetAllData()

        seedService = nil
        homeRepo = nil
        categoryRepo = nil
        locationRepo = nil

        try super.tearDownWithError()
    }

    // MARK: - Seeding Tests

    func testSeedingCreatesDefaultCategoriesAndLocations() throws {
        // Given - clean database (done in setUp)

        // When
        let home = try seedService.seedIfNeeded()

        // Then
        XCTAssertNotNil(home.id, "Home should have an ID after creation")

        let categories = try categoryRepo.findByHomeId(home.id!)
        XCTAssertEqual(categories.count, 9, "Should create 9 default categories")

        let locations = try locationRepo.findByHomeId(home.id!)
        XCTAssertEqual(locations.count, 12, "Should create 12 default locations")
    }

    func testSeedIfNeeded_CalledTwice_ShouldNotDuplicateData() throws {
        // Given
        let home1 = try seedService.seedIfNeeded()

        // When - call again (should be idempotent)
        let home2 = try seedService.seedIfNeeded()

        // Then
        XCTAssertEqual(home1.id, home2.id, "Should return same home")

        let categories = try categoryRepo.findByHomeId(home1.id!)
        XCTAssertEqual(categories.count, 9, "Should still have exactly 9 categories")

        let locations = try locationRepo.findByHomeId(home1.id!)
        XCTAssertEqual(locations.count, 12, "Should still have exactly 12 locations")
    }

    func testGetOrCreateHome_WithNoExistingHome_ShouldSeedAndReturnHome() throws {
        // Given - empty database

        // When
        let home = try seedService.getOrCreateHome()

        // Then
        XCTAssertNotNil(home.id)
        XCTAssertEqual(home.name, "My Home")

        // Verify categories and locations were created
        let categories = try categoryRepo.findByHomeId(home.id!)
        XCTAssertEqual(categories.count, 9)

        let locations = try locationRepo.findByHomeId(home.id!)
        XCTAssertEqual(locations.count, 12)
    }

    func testGetOrCreateHome_WithExistingHome_ShouldReturnExistingHome() throws {
        // Given
        let originalHome = try seedService.seedIfNeeded()

        // When
        let returnedHome = try seedService.getOrCreateHome()

        // Then
        XCTAssertEqual(originalHome.id, returnedHome.id)
    }

    func testDefaultCategories_ShouldIncludeAllExpectedCategories() throws {
        // Given
        let home = try seedService.seedIfNeeded()

        // When
        let categories = try categoryRepo.findByHomeId(home.id!)

        // Then
        let expectedNames = ["HVAC", "Plumbing", "Electrical", "Appliances",
                            "Exterior", "Interior", "Landscaping", "Security", "Other"]
        let categoryNames = categories.map { $0.name }

        for expectedName in expectedNames {
            XCTAssertTrue(categoryNames.contains(expectedName),
                         "Categories should include \(expectedName)")
        }
    }

    func testDefaultLocations_ShouldIncludeAllExpectedLocations() throws {
        // Given
        let home = try seedService.seedIfNeeded()

        // When
        let locations = try locationRepo.findByHomeId(home.id!)

        // Then
        let expectedNames = ["Kitchen", "Living Room", "Dining Room",
                            "Master Bedroom", "Bedroom 2",
                            "Bathroom 1", "Bathroom 2",
                            "Garage", "Basement", "Attic", "Exterior", "Yard"]
        let locationNames = locations.map { $0.name }

        for expectedName in expectedNames {
            XCTAssertTrue(locationNames.contains(expectedName),
                         "Locations should include \(expectedName)")
        }
    }

    // MARK: - Self-Healing Tests

    func testSeedIfNeeded_WhenCategoriesMissing_ShouldRecreate() throws {
        // Given - seed initially
        let home = try seedService.seedIfNeeded()
        XCTAssertEqual(try categoryRepo.findByHomeId(home.id!).count, 9)

        // When - delete categories (simulating corruption/partial reset)
        try categoryRepo.deleteAll()
        XCTAssertEqual(try categoryRepo.findByHomeId(home.id!).count, 0)

        // When - call seedIfNeeded again
        _ = try seedService.seedIfNeeded()

        // Then - categories should be recreated
        let categories = try categoryRepo.findByHomeId(home.id!)
        XCTAssertEqual(categories.count, 9, "Categories should be recreated automatically")
    }

    func testSeedIfNeeded_WhenLocationsMissing_ShouldRecreate() throws {
        // Given - seed initially
        let home = try seedService.seedIfNeeded()
        XCTAssertEqual(try locationRepo.findByHomeId(home.id!).count, 12)

        // When - delete locations (simulating corruption/partial reset)
        try locationRepo.deleteAll()
        XCTAssertEqual(try locationRepo.findByHomeId(home.id!).count, 0)

        // When - call seedIfNeeded again
        _ = try seedService.seedIfNeeded()

        // Then - locations should be recreated
        let locations = try locationRepo.findByHomeId(home.id!)
        XCTAssertEqual(locations.count, 12, "Locations should be recreated automatically")
    }

    func testSeedIfNeeded_WhenBothMissing_ShouldRecreateBoth() throws {
        // Given - seed initially
        let home = try seedService.seedIfNeeded()

        // When - delete both (simulating severe corruption)
        try categoryRepo.deleteAll()
        try locationRepo.deleteAll()

        // When - call seedIfNeeded again
        _ = try seedService.seedIfNeeded()

        // Then - both should be recreated
        let categories = try categoryRepo.findByHomeId(home.id!)
        let locations = try locationRepo.findByHomeId(home.id!)

        XCTAssertEqual(categories.count, 9, "Categories should be recreated")
        XCTAssertEqual(locations.count, 12, "Locations should be recreated")
    }
}
