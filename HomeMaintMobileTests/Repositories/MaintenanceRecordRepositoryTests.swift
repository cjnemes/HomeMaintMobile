import XCTest
@testable import HomeMaintMobile

/// Tests for MaintenanceRecordRepository
/// Covers all CRUD operations, filtering, cost calculations, and edge cases
final class MaintenanceRecordRepositoryTests: XCTestCase {

    var repository: MaintenanceRecordRepository!
    var homeRepo: HomeRepository!
    var assetRepo: AssetRepository!
    var categoryRepo: CategoryRepository!
    var locationRepo: LocationRepository!
    var providerRepo: ServiceProviderRepository!

    var testHome: Home!
    var testAsset: Asset!
    var testProvider: ServiceProvider!

    override func setUp() async throws {
        try await super.setUp()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        // Initialize repositories
        repository = MaintenanceRecordRepository()
        homeRepo = HomeRepository()
        assetRepo = AssetRepository()
        categoryRepo = CategoryRepository()
        locationRepo = LocationRepository()
        providerRepo = ServiceProviderRepository()

        // Create test home
        testHome = try homeRepo.create(
            name: "Test Home",
            address: nil,
            purchaseDate: nil,
            squareFootage: nil
        )

        // Create test category and location for asset
        let category = try categoryRepo.create(
            homeId: testHome.id!,
            name: "HVAC",
            icon: "thermometer"
        )

        let location = try locationRepo.create(
            homeId: testHome.id!,
            name: "Basement",
            floor: "B"
        )

        // Create test asset
        testAsset = try assetRepo.create(
            homeId: testHome.id!,
            categoryId: category.id!,
            locationId: location.id!,
            name: "Furnace",
            manufacturer: "Carrier",
            modelNumber: "58MVC"
        )

        // Create test service provider
        testProvider = try providerRepo.create(
            homeId: testHome.id!,
            company: "HVAC Pros",
            name: "John Smith",
            phone: "555-1234"
        )
    }

    override func tearDown() async throws {
        try repository.deleteAll()
        try assetRepo.deleteAll()
        try providerRepo.deleteAll()
        try categoryRepo.deleteAll()
        try locationRepo.deleteAll()
        try homeRepo.deleteAll()

        repository = nil
        assetRepo = nil
        providerRepo = nil
        categoryRepo = nil
        locationRepo = nil
        homeRepo = nil
        testHome = nil
        testAsset = nil
        testProvider = nil

        try await super.tearDown()
    }

    // MARK: - Create Tests

    func testCreate_WithAllFields_ShouldSucceed() throws {
        let cost = Decimal(string: "299.99")!

        let record = try repository.create(
            assetId: testAsset.id!,
            serviceProviderId: testProvider.id!,
            maintenanceType: "Repair",
            description: "Fixed heating issue",
            cost: cost,
            performedAt: Date(),
            notes: "Replaced thermostat"
        )

        XCTAssertNotNil(record.id, "Record should have an ID after creation")
        XCTAssertEqual(record.assetId, testAsset.id!)
        XCTAssertEqual(record.serviceProviderId, testProvider.id!)
        XCTAssertEqual(record.maintenanceType, "Repair")
        XCTAssertEqual(record.description, "Fixed heating issue")
        XCTAssertEqual(record.cost, cost)
        XCTAssertEqual(record.notes, "Replaced thermostat")
    }

    func testCreate_WithMinimalFields_ShouldSucceed() throws {
        let record = try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Inspection",
            performedAt: Date()
        )

        XCTAssertNotNil(record.id)
        XCTAssertEqual(record.assetId, testAsset.id!)
        XCTAssertEqual(record.maintenanceType, "Inspection")
        XCTAssertNil(record.serviceProviderId)
        XCTAssertNil(record.description)
        XCTAssertNil(record.cost)
        XCTAssertNil(record.notes)
    }

    func testCreate_WithZeroCost_ShouldSucceed() throws {
        let record = try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "DIY Repair",
            cost: Decimal(0),
            performedAt: Date()
        )

        XCTAssertNotNil(record.id)
        XCTAssertEqual(record.cost, Decimal(0))
    }

    func testCreate_WithPreciseCost_ShouldPreserveDecimal() throws {
        let preciseCost = Decimal(string: "1234.56")!

        let record = try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Service",
            cost: preciseCost,
            performedAt: Date()
        )

        let retrieved = try repository.findById(record.id!)
        XCTAssertEqual(retrieved?.cost, preciseCost, "Decimal cost should be preserved exactly")
    }

    // MARK: - Read Tests

    func testFindAll_ShouldReturnAllRecords() throws {
        try repository.create(assetId: testAsset.id!, maintenanceType: "Inspection", performedAt: Date())
        try repository.create(assetId: testAsset.id!, maintenanceType: "Repair", performedAt: Date())
        try repository.create(assetId: testAsset.id!, maintenanceType: "Service", performedAt: Date())

        let records = try repository.findAll()

        XCTAssertEqual(records.count, 3)
    }

    func testFindById_WhenExists_ShouldReturnRecord() throws {
        let created = try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Repair",
            description: "Test repair",
            performedAt: Date()
        )

        let found = try repository.findById(created.id!)

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, created.id)
        XCTAssertEqual(found?.description, "Test repair")
    }

    func testFindById_WhenNotExists_ShouldReturnNil() throws {
        let found = try repository.findById(99999)

        XCTAssertNil(found)
    }

    func testFindByAssetId_ShouldReturnOnlyMatchingRecords() throws {
        // Create second asset
        let category = try categoryRepo.findByHomeId(testHome.id!).first!
        let location = try locationRepo.findByHomeId(testHome.id!).first!
        let asset2 = try assetRepo.create(
            homeId: testHome.id!,
            categoryId: category.id!,
            locationId: location.id!,
            name: "Air Conditioner"
        )

        // Create records for both assets
        try repository.create(assetId: testAsset.id!, maintenanceType: "Inspection", performedAt: Date())
        try repository.create(assetId: testAsset.id!, maintenanceType: "Repair", performedAt: Date())
        try repository.create(assetId: asset2.id!, maintenanceType: "Service", performedAt: Date())

        let records = try repository.findByAssetId(testAsset.id!)

        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records.allSatisfy { $0.assetId == testAsset.id! })
    }

    func testFindByServiceProviderId_ShouldReturnOnlyMatchingRecords() throws {
        let provider2 = try providerRepo.create(
            homeId: testHome.id!,
            company: "Other Company"
        )

        try repository.create(
            assetId: testAsset.id!,
            serviceProviderId: testProvider.id!,
            maintenanceType: "Inspection",
            performedAt: Date()
        )
        try repository.create(
            assetId: testAsset.id!,
            serviceProviderId: testProvider.id!,
            maintenanceType: "Repair",
            performedAt: Date()
        )
        try repository.create(
            assetId: testAsset.id!,
            serviceProviderId: provider2.id!,
            maintenanceType: "Service",
            performedAt: Date()
        )

        let records = try repository.findByServiceProviderId(testProvider.id!)

        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records.allSatisfy { $0.serviceProviderId == testProvider.id! })
    }

    func testFindRecent_ShouldReturnLimitedRecordsOrderedByDate() throws {
        let now = Date()

        // Create records at different times
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Old",
            performedAt: now.addingTimeInterval(-60 * 60 * 24 * 30) // 30 days ago
        )
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Recent1",
            performedAt: now.addingTimeInterval(-60 * 60 * 24 * 7) // 7 days ago
        )
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Recent2",
            performedAt: now.addingTimeInterval(-60 * 60 * 24) // 1 day ago
        )
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Most Recent",
            performedAt: now
        )

        let recent = try repository.findRecent(limit: 2)

        XCTAssertEqual(recent.count, 2)
        XCTAssertEqual(recent[0].maintenanceType, "Most Recent")
        XCTAssertEqual(recent[1].maintenanceType, "Recent2")
    }

    func testFindByDateRange_ShouldReturnRecordsInRange() throws {
        let now = Date()
        let startDate = now.addingTimeInterval(-60 * 60 * 24 * 30) // 30 days ago
        let endDate = now.addingTimeInterval(-60 * 60 * 24 * 7) // 7 days ago

        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Too Old",
            performedAt: now.addingTimeInterval(-60 * 60 * 24 * 45) // 45 days ago
        )
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "In Range 1",
            performedAt: now.addingTimeInterval(-60 * 60 * 24 * 20) // 20 days ago
        )
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "In Range 2",
            performedAt: now.addingTimeInterval(-60 * 60 * 24 * 10) // 10 days ago
        )
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Too Recent",
            performedAt: now.addingTimeInterval(-60 * 60 * 24) // 1 day ago
        )

        let records = try repository.findByDateRange(startDate: startDate, endDate: endDate)

        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records.contains { $0.maintenanceType == "In Range 1" })
        XCTAssertTrue(records.contains { $0.maintenanceType == "In Range 2" })
    }

    // MARK: - Update Tests

    func testUpdate_ShouldModifyRecord() throws {
        var record = try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Inspection",
            description: "Original description",
            performedAt: Date()
        )

        record.maintenanceType = "Repair"
        record.description = "Updated description"
        record.cost = Decimal(string: "150.00")

        let updated = try repository.update(record)

        XCTAssertEqual(updated.maintenanceType, "Repair")
        XCTAssertEqual(updated.description, "Updated description")
        XCTAssertEqual(updated.cost, Decimal(string: "150.00"))

        // Verify in database
        let retrieved = try repository.findById(record.id!)
        XCTAssertEqual(retrieved?.maintenanceType, "Repair")
        XCTAssertEqual(retrieved?.description, "Updated description")
    }

    // MARK: - Delete Tests

    func testDelete_ShouldRemoveRecord() throws {
        let record = try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Inspection",
            performedAt: Date()
        )

        let deleted = try repository.delete(record.id!)

        XCTAssertTrue(deleted)
        XCTAssertNil(try repository.findById(record.id!))
    }

    func testDelete_WhenNotExists_ShouldReturnFalse() throws {
        let deleted = try repository.delete(99999)

        XCTAssertFalse(deleted)
    }

    func testDeleteAll_ShouldRemoveAllRecords() throws {
        try repository.create(assetId: testAsset.id!, maintenanceType: "Type1", performedAt: Date())
        try repository.create(assetId: testAsset.id!, maintenanceType: "Type2", performedAt: Date())
        try repository.create(assetId: testAsset.id!, maintenanceType: "Type3", performedAt: Date())

        try repository.deleteAll()

        let remaining = try repository.findAll()
        XCTAssertEqual(remaining.count, 0)
    }

    // MARK: - Cost Calculation Tests

    func testGetTotalCost_ForSingleAsset_ShouldSumCosts() throws {
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Repair",
            cost: Decimal(string: "100.00"),
            performedAt: Date()
        )
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Service",
            cost: Decimal(string: "50.50"),
            performedAt: Date()
        )
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Inspection",
            cost: Decimal(string: "25.00"),
            performedAt: Date()
        )

        let total = try repository.getTotalCost(forAssetId: testAsset.id!)

        XCTAssertEqual(total, Decimal(string: "175.50"))
    }

    func testGetTotalCost_WithNullCosts_ShouldIgnoreNulls() throws {
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Paid",
            cost: Decimal(string: "100.00"),
            performedAt: Date()
        )
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Free",
            cost: nil,
            performedAt: Date()
        )

        let total = try repository.getTotalCost(forAssetId: testAsset.id!)

        XCTAssertEqual(total, Decimal(string: "100.00"))
    }

    func testGetTotalCost_AllAssets_ShouldSumAllCosts() throws {
        // Create second asset
        let category = try categoryRepo.findByHomeId(testHome.id!).first!
        let location = try locationRepo.findByHomeId(testHome.id!).first!
        let asset2 = try assetRepo.create(
            homeId: testHome.id!,
            categoryId: category.id!,
            locationId: location.id!,
            name: "Air Conditioner"
        )

        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Repair",
            cost: Decimal(string: "100.00"),
            performedAt: Date()
        )
        try repository.create(
            assetId: asset2.id!,
            maintenanceType: "Service",
            cost: Decimal(string: "75.00"),
            performedAt: Date()
        )

        let total = try repository.getTotalCost()

        XCTAssertEqual(total, Decimal(string: "175.00"))
    }

    func testGetTotalCost_WhenNoRecords_ShouldReturnZero() throws {
        let total = try repository.getTotalCost(forAssetId: testAsset.id!)

        XCTAssertEqual(total, Decimal(0))
    }

    // MARK: - Count Tests

    func testCount_ShouldReturnCorrectNumber() throws {
        try repository.create(assetId: testAsset.id!, maintenanceType: "Type1", performedAt: Date())
        try repository.create(assetId: testAsset.id!, maintenanceType: "Type2", performedAt: Date())
        try repository.create(assetId: testAsset.id!, maintenanceType: "Type3", performedAt: Date())

        let count = try repository.count()

        XCTAssertEqual(count, 3)
    }

    // MARK: - Edge Cases

    func testCreate_WithVeryLargeCost_ShouldSucceed() throws {
        let largeCost = Decimal(string: "999999.99")!

        let record = try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Expensive",
            cost: largeCost,
            performedAt: Date()
        )

        XCTAssertEqual(record.cost, largeCost)
    }

    func testCreate_WithEmptyDescription_ShouldSucceed() throws {
        let record = try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Inspection",
            description: "",
            performedAt: Date()
        )

        XCTAssertEqual(record.description, "")
    }

    func testFindRecent_WithLimitZero_ShouldReturnEmpty() throws {
        try repository.create(assetId: testAsset.id!, maintenanceType: "Type1", performedAt: Date())

        let recent = try repository.findRecent(limit: 0)

        XCTAssertEqual(recent.count, 0)
    }

    func testFindByDateRange_WhenNoMatches_ShouldReturnEmpty() throws {
        let now = Date()
        try repository.create(
            assetId: testAsset.id!,
            maintenanceType: "Recent",
            performedAt: now
        )

        let pastStart = now.addingTimeInterval(-60 * 60 * 24 * 60) // 60 days ago
        let pastEnd = now.addingTimeInterval(-60 * 60 * 24 * 30) // 30 days ago

        let records = try repository.findByDateRange(startDate: pastStart, endDate: pastEnd)

        XCTAssertEqual(records.count, 0)
    }
}
