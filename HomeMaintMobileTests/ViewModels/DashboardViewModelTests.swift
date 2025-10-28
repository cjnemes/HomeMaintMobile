import XCTest
@testable import HomeMaintMobile
import GRDB

@MainActor
final class DashboardViewModelTests: XCTestCase {

    var viewModel: DashboardViewModel!
    var assetRepo: AssetRepository!
    var maintenanceRepo: MaintenanceRecordRepository!
    var taskRepo: MaintenanceTaskRepository!
    var homeRepo: HomeRepository!
    var categoryRepo: CategoryRepository!
    var testHomeId: Int64!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        // Initialize repositories
        assetRepo = AssetRepository()
        maintenanceRepo = MaintenanceRecordRepository()
        taskRepo = MaintenanceTaskRepository()
        homeRepo = HomeRepository()
        categoryRepo = CategoryRepository()

        // Create test home
        let home = try homeRepo.create(name: "Test Home")
        testHomeId = home.id!
    }

    override func tearDownWithError() throws {
        // Clean up test data
        try? DatabaseService.shared.resetAllData()

        viewModel = nil
        assetRepo = nil
        maintenanceRepo = nil
        taskRepo = nil
        homeRepo = nil
        categoryRepo = nil
        testHomeId = nil

        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInit_ShouldLoadDataAutomatically() async throws {
        // When
        viewModel = DashboardViewModel()

        // Wait for async loading to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Load Data Tests

    func testLoadDashboardData_WithAssets_ShouldLoadCorrectCount() async throws {
        // Given
        viewModel = DashboardViewModel()

        // Create test assets
        try assetRepo.create(homeId: testHomeId, name: "Asset 1")
        try assetRepo.create(homeId: testHomeId, name: "Asset 2")
        try assetRepo.create(homeId: testHomeId, name: "Asset 3")

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.totalAssets, 3)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadDashboardData_WithRecentMaintenance_ShouldLoadRecent() async throws {
        // Given
        viewModel = DashboardViewModel()
        let asset = try assetRepo.create(homeId: testHomeId, name: "Test Asset")

        // Create maintenance records with different dates
        for i in 1...7 {
            try maintenanceRepo.create(
                assetId: asset.id!,
                type: "Maintenance",
                description: "Maintenance \(i)",
                serviceDate: Date().addingTimeInterval(TimeInterval(-i * 24 * 60 * 60))
            )
        }

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.recentMaintenance.count, 5) // Should only load 5 most recent
        XCTAssertEqual(viewModel.maintenanceCount, 5)
    }

    func testLoadDashboardData_WithUpcomingTasks_ShouldLoadNext30Days() async throws {
        // Given
        viewModel = DashboardViewModel()
        let asset = try assetRepo.create(homeId: testHomeId, name: "Test Asset")

        // Create tasks with different due dates
        try taskRepo.create(
            assetId: asset.id!,
            title: "Task in 10 days",
            dueDate: Date().addingTimeInterval(10 * 24 * 60 * 60)
        )
        try taskRepo.create(
            assetId: asset.id!,
            title: "Task in 25 days",
            dueDate: Date().addingTimeInterval(25 * 24 * 60 * 60)
        )
        try taskRepo.create(
            assetId: asset.id!,
            title: "Task in 45 days",
            dueDate: Date().addingTimeInterval(45 * 24 * 60 * 60)
        )

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.upcomingTasks.count, 2) // Only tasks within 30 days
    }

    func testLoadDashboardData_WithOverdueTasks_ShouldLoadOverdue() async throws {
        // Given
        viewModel = DashboardViewModel()
        let asset = try assetRepo.create(homeId: testHomeId, name: "Test Asset")

        // Create overdue tasks
        try taskRepo.create(
            assetId: asset.id!,
            title: "Overdue 1",
            dueDate: Date().addingTimeInterval(-5 * 24 * 60 * 60) // 5 days ago
        )
        try taskRepo.create(
            assetId: asset.id!,
            title: "Overdue 2",
            dueDate: Date().addingTimeInterval(-10 * 24 * 60 * 60) // 10 days ago
        )
        try taskRepo.create(
            assetId: asset.id!,
            title: "Not overdue",
            dueDate: Date().addingTimeInterval(5 * 24 * 60 * 60) // 5 days from now
        )

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.overdueTasks.count, 2)
    }

    func testLoadDashboardData_WithExpiringWarranties_ShouldLoadNext30Days() async throws {
        // Given
        viewModel = DashboardViewModel()

        // Create assets with different warranty expiration dates
        try assetRepo.create(
            homeId: testHomeId,
            name: "Asset expiring in 15 days",
            warrantyExpiration: Date().addingTimeInterval(15 * 24 * 60 * 60)
        )
        try assetRepo.create(
            homeId: testHomeId,
            name: "Asset expiring in 25 days",
            warrantyExpiration: Date().addingTimeInterval(25 * 24 * 60 * 60)
        )
        try assetRepo.create(
            homeId: testHomeId,
            name: "Asset expiring in 45 days",
            warrantyExpiration: Date().addingTimeInterval(45 * 24 * 60 * 60)
        )

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.expiringWarranties.count, 2) // Only warranties expiring within 30 days
    }

    func testLoadDashboardData_WithNoData_ShouldHandleGracefully() async throws {
        // Given
        viewModel = DashboardViewModel()
        // No data created

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.totalAssets, 0)
        XCTAssertTrue(viewModel.recentMaintenance.isEmpty)
        XCTAssertTrue(viewModel.upcomingTasks.isEmpty)
        XCTAssertTrue(viewModel.overdueTasks.isEmpty)
        XCTAssertTrue(viewModel.expiringWarranties.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadDashboardData_SetsLoadingState() async throws {
        // Given
        viewModel = DashboardViewModel()

        // When/Then
        let expectation = XCTestExpectation(description: "Loading state changes")

        Task {
            await viewModel.loadDashboardData()

            // After completion, loading should be false
            XCTAssertFalse(viewModel.isLoading)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Computed Properties Tests

    func testPendingTasksCount_WithMixedTasks_ShouldSumCorrectly() async throws {
        // Given
        viewModel = DashboardViewModel()
        let asset = try assetRepo.create(homeId: testHomeId, name: "Test Asset")

        // Create upcoming and overdue tasks
        try taskRepo.create(
            assetId: asset.id!,
            title: "Upcoming 1",
            dueDate: Date().addingTimeInterval(5 * 24 * 60 * 60)
        )
        try taskRepo.create(
            assetId: asset.id!,
            title: "Upcoming 2",
            dueDate: Date().addingTimeInterval(10 * 24 * 60 * 60)
        )
        try taskRepo.create(
            assetId: asset.id!,
            title: "Overdue 1",
            dueDate: Date().addingTimeInterval(-5 * 24 * 60 * 60)
        )

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.pendingTasksCount, 3) // 2 upcoming + 1 overdue
    }

    func testAlertsCount_WithOverdueAndExpiringWarranties_ShouldSumCorrectly() async throws {
        // Given
        viewModel = DashboardViewModel()
        let asset = try assetRepo.create(homeId: testHomeId, name: "Test Asset")

        // Create overdue tasks
        try taskRepo.create(
            assetId: asset.id!,
            title: "Overdue 1",
            dueDate: Date().addingTimeInterval(-5 * 24 * 60 * 60)
        )
        try taskRepo.create(
            assetId: asset.id!,
            title: "Overdue 2",
            dueDate: Date().addingTimeInterval(-10 * 24 * 60 * 60)
        )

        // Create expiring warranties
        try assetRepo.create(
            homeId: testHomeId,
            name: "Asset with expiring warranty",
            warrantyExpiration: Date().addingTimeInterval(15 * 24 * 60 * 60)
        )

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.alertsCount, 3) // 2 overdue tasks + 1 expiring warranty
    }

    func testAlertsCount_NoAlerts_ShouldReturnZero() async throws {
        // Given
        viewModel = DashboardViewModel()
        // No overdue tasks or expiring warranties

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.alertsCount, 0)
    }

    // MARK: - Edge Case Tests

    func testLoadDashboardData_MultipleLoads_ShouldHandleCorrectly() async throws {
        // Given
        viewModel = DashboardViewModel()
        try assetRepo.create(homeId: testHomeId, name: "Asset 1")

        // When - Load multiple times
        await viewModel.loadDashboardData()
        await viewModel.loadDashboardData()
        await viewModel.loadDashboardData()

        // Then - Should still work correctly
        XCTAssertEqual(viewModel.totalAssets, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadDashboardData_WithCompletedTasks_ShouldNotIncludeInUpcoming() async throws {
        // Given
        viewModel = DashboardViewModel()
        let asset = try assetRepo.create(homeId: testHomeId, name: "Test Asset")

        // Create a completed task with future due date
        let task = try taskRepo.create(
            assetId: asset.id!,
            title: "Completed task",
            dueDate: Date().addingTimeInterval(5 * 24 * 60 * 60)
        )
        _ = try taskRepo.update(
            task.id!,
            status: MaintenanceTask.TaskStatus.completed.rawValue
        )

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.upcomingTasks.count, 0) // Should not include completed tasks
    }

    func testLoadDashboardData_ExpiredWarranties_ShouldNotInclude() async throws {
        // Given
        viewModel = DashboardViewModel()

        // Create asset with expired warranty
        try assetRepo.create(
            homeId: testHomeId,
            name: "Asset with expired warranty",
            warrantyExpiration: Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        )

        // When
        await viewModel.loadDashboardData()

        // Then
        XCTAssertEqual(viewModel.expiringWarranties.count, 0) // Should not include expired warranties
    }
}