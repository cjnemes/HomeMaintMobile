import XCTest
@testable import HomeMaintMobile

/// Tests for MaintenanceRecordListViewModel
/// Covers loading, filtering, searching, and cost calculations
@MainActor
final class MaintenanceRecordListViewModelTests: XCTestCase {

    var viewModel: MaintenanceRecordListViewModel!
    var recordRepo: MaintenanceRecordRepository!
    var homeRepo: HomeRepository!
    var assetRepo: AssetRepository!
    var categoryRepo: CategoryRepository!
    var locationRepo: LocationRepository!
    var providerRepo: ServiceProviderRepository!

    var testHome: Home!
    var testAsset1: Asset!
    var testAsset2: Asset!
    var testProvider1: ServiceProvider!
    var testProvider2: ServiceProvider!

    override func setUp() async throws {
        try await super.setUp()

        // Initialize in-memory database
        try DatabaseService.shared.initialize(inMemory: true)

        // Initialize repositories
        recordRepo = MaintenanceRecordRepository()
        homeRepo = HomeRepository()
        assetRepo = AssetRepository()
        categoryRepo = CategoryRepository()
        locationRepo = LocationRepository()
        providerRepo = ServiceProviderRepository()

        // Create test data
        testHome = try homeRepo.create(name: "Test Home")

        let category = try categoryRepo.create(homeId: testHome.id!, name: "HVAC", icon: "thermometer")
        let location = try locationRepo.create(homeId: testHome.id!, name: "Basement", floor: "B")

        testAsset1 = try assetRepo.create(
            homeId: testHome.id!,
            categoryId: category.id!,
            locationId: location.id!,
            name: "Furnace"
        )

        testAsset2 = try assetRepo.create(
            homeId: testHome.id!,
            categoryId: category.id!,
            locationId: location.id!,
            name: "Air Conditioner"
        )

        testProvider1 = try providerRepo.create(homeId: testHome.id!, company: "HVAC Pros")
        testProvider2 = try providerRepo.create(homeId: testHome.id!, company: "Repair Co")

        // Initialize ViewModel
        viewModel = MaintenanceRecordListViewModel()
    }

    override func tearDown() async throws {
        try recordRepo.deleteAll()
        try assetRepo.deleteAll()
        try providerRepo.deleteAll()
        try categoryRepo.deleteAll()
        try locationRepo.deleteAll()
        try homeRepo.deleteAll()

        viewModel = nil
        recordRepo = nil
        assetRepo = nil
        providerRepo = nil
        categoryRepo = nil
        locationRepo = nil
        homeRepo = nil

        try await super.tearDown()
    }

    // MARK: - Load All Records Tests

    func testLoadRecords_WhenEmpty_ShouldReturnEmptyArray() async throws {
        await viewModel.loadRecords()

        XCTAssertEqual(viewModel.records.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadRecords_WithData_ShouldReturnAll() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Inspection", performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Repair", performedAt: Date())
        try recordRepo.create(assetId: testAsset2.id!, maintenanceType: "Service", performedAt: Date())

        await viewModel.loadRecords()

        XCTAssertEqual(viewModel.records.count, 3)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Filter by Asset Tests

    func testLoadRecords_ForSpecificAsset_ShouldReturnOnlyAssetRecords() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Inspection", performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Repair", performedAt: Date())
        try recordRepo.create(assetId: testAsset2.id!, maintenanceType: "Service", performedAt: Date())

        await viewModel.loadRecords(forAssetId: testAsset1.id!)

        XCTAssertEqual(viewModel.records.count, 2)
        XCTAssertTrue(viewModel.records.allSatisfy { $0.assetId == testAsset1.id! })
        XCTAssertEqual(viewModel.filterAssetId, testAsset1.id!)
    }

    func testLoadRecords_ForAsset_ShouldClearOtherFilters() async throws {
        viewModel.filterProviderId = testProvider1.id
        viewModel.startDate = Date()
        viewModel.endDate = Date()

        await viewModel.loadRecords(forAssetId: testAsset1.id!)

        XCTAssertEqual(viewModel.filterAssetId, testAsset1.id!)
        XCTAssertNil(viewModel.filterProviderId)
        XCTAssertNil(viewModel.startDate)
        XCTAssertNil(viewModel.endDate)
    }

    // MARK: - Filter by Provider Tests

    func testLoadRecords_ForSpecificProvider_ShouldReturnOnlyProviderRecords() async throws {
        try recordRepo.create(
            assetId: testAsset1.id!,
            serviceProviderId: testProvider1.id!,
            maintenanceType: "Inspection",
            performedAt: Date()
        )
        try recordRepo.create(
            assetId: testAsset1.id!,
            serviceProviderId: testProvider1.id!,
            maintenanceType: "Repair",
            performedAt: Date()
        )
        try recordRepo.create(
            assetId: testAsset2.id!,
            serviceProviderId: testProvider2.id!,
            maintenanceType: "Service",
            performedAt: Date()
        )

        await viewModel.loadRecords(forProviderId: testProvider1.id!)

        XCTAssertEqual(viewModel.records.count, 2)
        XCTAssertTrue(viewModel.records.allSatisfy { $0.serviceProviderId == testProvider1.id! })
        XCTAssertEqual(viewModel.filterProviderId, testProvider1.id!)
    }

    func testLoadRecords_ForProvider_ShouldClearOtherFilters() async throws {
        viewModel.filterAssetId = testAsset1.id
        viewModel.startDate = Date()
        viewModel.endDate = Date()

        await viewModel.loadRecords(forProviderId: testProvider1.id!)

        XCTAssertEqual(viewModel.filterProviderId, testProvider1.id!)
        XCTAssertNil(viewModel.filterAssetId)
        XCTAssertNil(viewModel.startDate)
        XCTAssertNil(viewModel.endDate)
    }

    // MARK: - Filter by Date Range Tests

    func testLoadRecords_WithDateRange_ShouldReturnRecordsInRange() async throws {
        let now = Date()
        let oldDate = now.addingTimeInterval(-60 * 60 * 24 * 45) // 45 days ago
        let inRangeDate = now.addingTimeInterval(-60 * 60 * 24 * 20) // 20 days ago
        let recentDate = now.addingTimeInterval(-60 * 60 * 24) // 1 day ago

        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Old", performedAt: oldDate)
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "In Range", performedAt: inRangeDate)
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Recent", performedAt: recentDate)

        let startDate = now.addingTimeInterval(-60 * 60 * 24 * 30) // 30 days ago
        let endDate = now.addingTimeInterval(-60 * 60 * 24 * 7) // 7 days ago

        await viewModel.loadRecords(from: startDate, to: endDate)

        XCTAssertEqual(viewModel.records.count, 1)
        XCTAssertEqual(viewModel.records.first?.maintenanceType, "In Range")
        XCTAssertEqual(viewModel.startDate, startDate)
        XCTAssertEqual(viewModel.endDate, endDate)
    }

    func testLoadRecords_WithDateRange_ShouldClearOtherFilters() async throws {
        viewModel.filterAssetId = testAsset1.id
        viewModel.filterProviderId = testProvider1.id

        let start = Date().addingTimeInterval(-60 * 60 * 24 * 30)
        let end = Date()

        await viewModel.loadRecords(from: start, to: end)

        XCTAssertNotNil(viewModel.startDate)
        XCTAssertNotNil(viewModel.endDate)
        XCTAssertNil(viewModel.filterAssetId)
        XCTAssertNil(viewModel.filterProviderId)
    }

    // MARK: - Recent Records Tests

    func testLoadRecentRecords_ShouldReturnMostRecent() async throws {
        let now = Date()

        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Old", performedAt: now.addingTimeInterval(-60 * 60 * 24 * 30))
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Recent", performedAt: now.addingTimeInterval(-60 * 60 * 24))
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Most Recent", performedAt: now)

        await viewModel.loadRecentRecords(limit: 2)

        XCTAssertEqual(viewModel.records.count, 2)
        XCTAssertEqual(viewModel.records.first?.maintenanceType, "Most Recent")
    }

    // MARK: - Search Tests

    func testFilteredRecords_WithSearchQuery_ShouldFilterByType() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Inspection", performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Repair", performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Service", performedAt: Date())

        await viewModel.loadRecords()
        viewModel.searchQuery = "repair"

        XCTAssertEqual(viewModel.filteredRecords.count, 1)
        XCTAssertEqual(viewModel.filteredRecords.first?.maintenanceType, "Repair")
    }

    func testFilteredRecords_WithSearchQuery_ShouldFilterByDescription() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Repair", description: "Fixed heating", performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Service", description: "Routine check", performedAt: Date())

        await viewModel.loadRecords()
        viewModel.searchQuery = "heating"

        XCTAssertEqual(viewModel.filteredRecords.count, 1)
        XCTAssertTrue(viewModel.filteredRecords.first?.description?.contains("heating") ?? false)
    }

    func testFilteredRecords_WithSearchQuery_ShouldFilterByNotes() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Repair", notes: "Replaced thermostat", performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Service", notes: "All good", performedAt: Date())

        await viewModel.loadRecords()
        viewModel.searchQuery = "thermostat"

        XCTAssertEqual(viewModel.filteredRecords.count, 1)
        XCTAssertTrue(viewModel.filteredRecords.first?.notes?.contains("thermostat") ?? false)
    }

    func testFilteredRecords_CaseInsensitive_ShouldWork() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "REPAIR", performedAt: Date())

        await viewModel.loadRecords()
        viewModel.searchQuery = "repair"

        XCTAssertEqual(viewModel.filteredRecords.count, 1)
    }

    // MARK: - Cost Calculation Tests

    func testTotalCost_ShouldSumAllRecordCosts() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type1", cost: Decimal(string: "100.00"), performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type2", cost: Decimal(string: "50.50"), performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type3", cost: Decimal(string: "25.00"), performedAt: Date())

        await viewModel.loadRecords()

        XCTAssertEqual(viewModel.totalCost, Decimal(string: "175.50"))
    }

    func testTotalCost_WithNullCosts_ShouldIgnoreNulls() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Paid", cost: Decimal(string: "100.00"), performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Free", cost: nil, performedAt: Date())

        await viewModel.loadRecords()

        XCTAssertEqual(viewModel.totalCost, Decimal(string: "100.00"))
    }

    func testAverageCost_ShouldCalculateCorrectly() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type1", cost: Decimal(string: "100.00"), performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type2", cost: Decimal(string: "200.00"), performedAt: Date())

        await viewModel.loadRecords()

        XCTAssertEqual(viewModel.averageCost, Decimal(string: "150.00"))
    }

    func testAverageCost_WhenNoRecords_ShouldReturnZero() async throws {
        await viewModel.loadRecords()

        XCTAssertEqual(viewModel.averageCost, Decimal(0))
    }

    func testGetTotalCost_ForAsset_ShouldReturnAssetTotal() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type1", cost: Decimal(string: "100.00"), performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type2", cost: Decimal(string: "50.00"), performedAt: Date())
        try recordRepo.create(assetId: testAsset2.id!, maintenanceType: "Type3", cost: Decimal(string: "200.00"), performedAt: Date())

        let total = await viewModel.getTotalCost(forAssetId: testAsset1.id!)

        XCTAssertEqual(total, Decimal(string: "150.00"))
    }

    // MARK: - Clear Filters Tests

    func testClearFilters_ShouldResetAllFilters() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type1", performedAt: Date())
        try recordRepo.create(assetId: testAsset2.id!, maintenanceType: "Type2", performedAt: Date())

        // Set all filters
        viewModel.filterAssetId = testAsset1.id
        viewModel.filterProviderId = testProvider1.id
        viewModel.startDate = Date()
        viewModel.endDate = Date()
        viewModel.searchQuery = "test"

        await viewModel.clearFilters()

        XCTAssertNil(viewModel.filterAssetId)
        XCTAssertNil(viewModel.filterProviderId)
        XCTAssertNil(viewModel.startDate)
        XCTAssertNil(viewModel.endDate)
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.records.count, 2) // All records loaded
    }

    // MARK: - Delete Tests

    func testDeleteRecord_ShouldRemoveRecord() async throws {
        let record = try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "ToDelete", performedAt: Date())

        await viewModel.loadRecords()
        XCTAssertEqual(viewModel.records.count, 1)

        await viewModel.deleteRecord(record)

        XCTAssertEqual(viewModel.records.count, 0)
    }

    // MARK: - Loading State Tests

    func testLoadRecords_ShouldSetLoadingState() async throws {
        // This is tricky to test because loading happens so fast
        // We can at least verify it's false after loading
        await viewModel.loadRecords()

        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Record Count Tests

    func testRecordCount_ShouldReturnCorrectCount() async throws {
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type1", performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type2", performedAt: Date())
        try recordRepo.create(assetId: testAsset1.id!, maintenanceType: "Type3", performedAt: Date())

        await viewModel.loadRecords()

        XCTAssertEqual(viewModel.recordCount, 3)
    }
}
