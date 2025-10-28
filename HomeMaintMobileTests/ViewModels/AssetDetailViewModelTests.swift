import XCTest
@testable import HomeMaintMobile
import GRDB

@MainActor
final class AssetDetailViewModelTests: XCTestCase {

    var viewModel: AssetDetailViewModel!
    var assetRepo: AssetRepository!
    var categoryRepo: CategoryRepository!
    var locationRepo: LocationRepository!
    var maintenanceRepo: MaintenanceRecordRepository!
    var taskRepo: MaintenanceTaskRepository!
    var attachmentRepo: AttachmentRepository!
    var homeRepo: HomeRepository!
    var testHomeId: Int64!
    var testAsset: Asset!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        // Initialize repositories
        assetRepo = AssetRepository()
        categoryRepo = CategoryRepository()
        locationRepo = LocationRepository()
        maintenanceRepo = MaintenanceRecordRepository()
        taskRepo = MaintenanceTaskRepository()
        attachmentRepo = AttachmentRepository()
        homeRepo = HomeRepository()

        // Create test home
        let home = try homeRepo.create(name: "Test Home")
        testHomeId = home.id!

        // Create test category and location
        let category = try categoryRepo.create(homeId: testHomeId, name: "HVAC", icon: "air.conditioner")
        let location = try locationRepo.create(homeId: testHomeId, name: "Basement", floor: "Ground Floor")

        // Create test asset
        testAsset = try assetRepo.create(
            homeId: testHomeId,
            name: "Test Asset",
            manufacturer: "Test Manufacturer",
            modelNumber: "TEST-123",
            serialNumber: "SN12345",
            purchaseDate: Date(),
            purchaseCost: Decimal(1500.00),
            warrantyExpiration: Date().addingTimeInterval(365 * 24 * 60 * 60), // 1 year from now
            categoryId: category.id,
            locationId: location.id
        )
    }

    override func tearDownWithError() throws {
        // Clean up test data
        try? DatabaseService.shared.resetAllData()

        viewModel = nil
        assetRepo = nil
        categoryRepo = nil
        locationRepo = nil
        maintenanceRepo = nil
        taskRepo = nil
        attachmentRepo = nil
        homeRepo = nil
        testHomeId = nil
        testAsset = nil

        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInit_WithAsset_ShouldSetAssetProperty() async throws {
        // When
        viewModel = AssetDetailViewModel(asset: testAsset)

        // Then
        XCTAssertEqual(viewModel.asset.id, testAsset.id)
        XCTAssertEqual(viewModel.asset.name, testAsset.name)

        // Wait for async loading to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }

    // MARK: - Load Data Tests

    func testLoadRelatedData_WithCompleteAsset_ShouldLoadAllRelatedData() async throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // Create related data
        let record = try maintenanceRepo.create(
            assetId: testAsset.id!,
            type: "Repair",
            description: "Test repair"
        )
        let task = try taskRepo.create(
            assetId: testAsset.id!,
            title: "Test task"
        )
        let attachment = try attachmentRepo.create(
            assetId: testAsset.id!,
            type: "photo",
            filename: "test.jpg",
            relativePath: "test.jpg"
        )

        // When
        await viewModel.loadRelatedData()

        // Then
        XCTAssertNotNil(viewModel.category)
        XCTAssertEqual(viewModel.category?.name, "HVAC")
        XCTAssertNotNil(viewModel.location)
        XCTAssertEqual(viewModel.location?.name, "Basement")
        XCTAssertEqual(viewModel.maintenanceRecords.count, 1)
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.attachments.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadRelatedData_WithNoCategoryOrLocation_ShouldHandleGracefully() async throws {
        // Given
        let assetWithoutRelations = try assetRepo.create(
            homeId: testHomeId,
            name: "Asset Without Relations"
        )
        viewModel = AssetDetailViewModel(asset: assetWithoutRelations)

        // When
        await viewModel.loadRelatedData()

        // Then
        XCTAssertNil(viewModel.category)
        XCTAssertNil(viewModel.location)
        XCTAssertTrue(viewModel.maintenanceRecords.isEmpty)
        XCTAssertTrue(viewModel.tasks.isEmpty)
        XCTAssertTrue(viewModel.attachments.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadRelatedData_SetsLoadingState() async throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // When/Then
        let expectation = XCTestExpectation(description: "Loading state changes")

        Task {
            // Check loading becomes true
            await viewModel.loadRelatedData()

            // After completion, loading should be false
            XCTAssertFalse(viewModel.isLoading)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Computed Properties Tests

    func testWarrantyStatusText_ShouldReturnCorrectText() throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // When
        let statusText = viewModel.warrantyStatusText

        // Then
        XCTAssertEqual(statusText, testAsset.warrantyStatus.displayText)
    }

    func testWarrantyStatusColor_ShouldReturnCorrectColor() throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // When
        let statusColor = viewModel.warrantyStatusColor

        // Then
        XCTAssertEqual(statusColor, testAsset.warrantyStatus.color)
    }

    func testMaintenanceCount_WithRecords_ShouldReturnCorrectCount() async throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // Create maintenance records
        try maintenanceRepo.create(assetId: testAsset.id!, type: "Repair", description: "Repair 1")
        try maintenanceRepo.create(assetId: testAsset.id!, type: "Maintenance", description: "Maintenance 1")
        try maintenanceRepo.create(assetId: testAsset.id!, type: "Inspection", description: "Inspection 1")

        // When
        await viewModel.loadRelatedData()

        // Then
        XCTAssertEqual(viewModel.maintenanceCount, 3)
    }

    func testMaintenanceCount_WithNoRecords_ShouldReturnZero() async throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // When
        await viewModel.loadRelatedData()

        // Then
        XCTAssertEqual(viewModel.maintenanceCount, 0)
    }

    func testPendingTasksCount_WithMixedStatuses_ShouldCountOnlyPending() async throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // Create tasks with different statuses
        var task1 = try taskRepo.create(assetId: testAsset.id!, title: "Pending Task 1")
        var task2 = try taskRepo.create(assetId: testAsset.id!, title: "Pending Task 2")
        var task3 = try taskRepo.create(assetId: testAsset.id!, title: "Completed Task")

        // Mark one as completed
        task3.status = MaintenanceTask.TaskStatus.completed.rawValue
        _ = try taskRepo.update(
            task3.id!,
            status: MaintenanceTask.TaskStatus.completed.rawValue
        )

        // When
        await viewModel.loadRelatedData()

        // Then
        XCTAssertEqual(viewModel.pendingTasksCount, 2)
    }

    func testPendingTasksCount_AllCompleted_ShouldReturnZero() async throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // Create completed tasks
        var task = try taskRepo.create(assetId: testAsset.id!, title: "Completed Task")
        _ = try taskRepo.update(
            task.id!,
            status: MaintenanceTask.TaskStatus.completed.rawValue
        )

        // When
        await viewModel.loadRelatedData()

        // Then
        XCTAssertEqual(viewModel.pendingTasksCount, 0)
    }

    func testPhotoCount_WithMixedAttachments_ShouldCountOnlyPhotos() async throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // Create mixed attachments
        try attachmentRepo.create(
            assetId: testAsset.id!,
            type: "photo",
            filename: "photo1.jpg",
            relativePath: "photo1.jpg",
            mimeType: "image/jpeg"
        )
        try attachmentRepo.create(
            assetId: testAsset.id!,
            type: "photo",
            filename: "photo2.png",
            relativePath: "photo2.png",
            mimeType: "image/png"
        )
        try attachmentRepo.create(
            assetId: testAsset.id!,
            type: "document",
            filename: "manual.pdf",
            relativePath: "manual.pdf",
            mimeType: "application/pdf"
        )

        // When
        await viewModel.loadRelatedData()

        // Then
        XCTAssertEqual(viewModel.photoCount, 2)
    }

    func testPhotoCount_NoPhotos_ShouldReturnZero() async throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // Create non-photo attachment
        try attachmentRepo.create(
            assetId: testAsset.id!,
            type: "document",
            filename: "document.pdf",
            relativePath: "document.pdf"
        )

        // When
        await viewModel.loadRelatedData()

        // Then
        XCTAssertEqual(viewModel.photoCount, 0)
    }

    // MARK: - Edge Case Tests

    func testLoadRelatedData_MultipleLoads_ShouldHandleCorrectly() async throws {
        // Given
        viewModel = AssetDetailViewModel(asset: testAsset)

        // When - Load multiple times
        await viewModel.loadRelatedData()
        await viewModel.loadRelatedData()
        await viewModel.loadRelatedData()

        // Then - Should still work correctly
        XCTAssertNotNil(viewModel.category)
        XCTAssertNotNil(viewModel.location)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testAssetWithExpiredWarranty_ShouldShowCorrectStatus() throws {
        // Given
        var expiredAsset = testAsset!
        expiredAsset.warrantyExpiration = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        viewModel = AssetDetailViewModel(asset: expiredAsset)

        // When
        let status = viewModel.warrantyStatusText

        // Then
        XCTAssertEqual(status, expiredAsset.warrantyStatus.displayText)
        XCTAssertTrue(status.contains("Expired") || status.contains("No warranty"))
    }
}