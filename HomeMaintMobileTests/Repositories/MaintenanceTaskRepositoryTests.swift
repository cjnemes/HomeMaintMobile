import XCTest
@testable import HomeMaintMobile
import GRDB

final class MaintenanceTaskRepositoryTests: XCTestCase {

    var repository: MaintenanceTaskRepository!
    var assetRepo: AssetRepository!
    var homeRepo: HomeRepository!
    var testHomeId: Int64!
    var testAssetId: Int64!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        repository = MaintenanceTaskRepository()
        homeRepo = HomeRepository()
        assetRepo = AssetRepository()

        // Create test home and asset
        let home = try homeRepo.create(name: "Test Home")
        testHomeId = home.id!

        let asset = try assetRepo.create(homeId: testHomeId, name: "Test Asset")
        testAssetId = asset.id!
    }

    override func tearDownWithError() throws {
        // Clean up test data
        try? DatabaseService.shared.resetAllData()

        repository = nil
        assetRepo = nil
        homeRepo = nil
        testHomeId = nil
        testAssetId = nil

        try super.tearDownWithError()
    }

    // MARK: - Create Tests

    func testCreate_WithValidData_ShouldReturnTaskWithId() throws {
        // Given
        let title = "Change HVAC Filter"
        let description = "Replace air filter"
        let dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now

        // When
        let task = try repository.create(
            title: title,
            assetId: testAssetId,
            description: description,
            dueDate: dueDate,
            priority: MaintenanceTask.TaskPriority.medium.rawValue
        )

        // Then
        XCTAssertNotNil(task.id)
        XCTAssertEqual(task.title, title)
        XCTAssertEqual(task.description, description)
        XCTAssertEqual(task.assetId, testAssetId)
        XCTAssertEqual(task.priority, MaintenanceTask.TaskPriority.medium.rawValue)
        XCTAssertEqual(task.status, MaintenanceTask.TaskStatus.pending.rawValue)
    }

    func testCreate_WithMinimalData_ShouldSucceed() throws {
        // Given
        let title = "Minimal Task"

        // When
        let task = try repository.create(title: title)

        // Then
        XCTAssertNotNil(task.id)
        XCTAssertEqual(task.title, title)
        XCTAssertNil(task.assetId)
        XCTAssertNil(task.description)
        XCTAssertNil(task.dueDate)
        XCTAssertEqual(task.status, MaintenanceTask.TaskStatus.pending.rawValue)
    }

    func testCreate_DefaultStatus_ShouldBePending() throws {
        // When
        let task = try repository.create(title: "Test Task")

        // Then
        XCTAssertEqual(task.status, MaintenanceTask.TaskStatus.pending.rawValue)
        XCTAssertFalse(task.isCompleted)
    }

    // MARK: - Read Tests

    func testFindById_WithExistingId_ShouldReturnTask() throws {
        // Given
        let created = try repository.create(title: "Test Task")
        let id = created.id!

        // When
        let found = try repository.findById(id)

        // Then
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, id)
        XCTAssertEqual(found?.title, "Test Task")
    }

    func testFindById_WithNonExistentId_ShouldReturnNil() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let found = try repository.findById(nonExistentId)

        // Then
        XCTAssertNil(found)
    }

    func testFindAll_ShouldReturnAllTasks() throws {
        // Given
        try repository.create(title: "Task 1")
        try repository.create(title: "Task 2")
        try repository.create(title: "Task 3")

        // When
        let tasks = try repository.findAll()

        // Then
        XCTAssertEqual(tasks.count, 3)
    }

    // MARK: - Update Tests

    func testUpdate_WithValidData_ShouldUpdateTask() throws {
        // Given
        let created = try repository.create(title: "Original Title")
        let id = created.id!

        // When
        let updated = try repository.update(
            id,
            title: "Updated Title",
            priority: MaintenanceTask.TaskPriority.high.rawValue
        )

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.title, "Updated Title")
        XCTAssertEqual(updated.priority, MaintenanceTask.TaskPriority.high.rawValue)
    }

    func testUpdate_NonExistentTask_ShouldThrowError() {
        // Given
        let nonExistentId: Int64 = 99999

        // When/Then
        XCTAssertThrowsError(try repository.update(nonExistentId, title: "New Title")) { error in
            XCTAssertTrue(error is RepositoryError)
        }
    }

    // MARK: - Delete Tests

    func testDelete_ExistingTask_ShouldSucceed() throws {
        // Given
        let created = try repository.create(title: "To Delete")
        let id = created.id!

        // When
        let deleted = try repository.delete(id)

        // Then
        XCTAssertTrue(deleted)

        // Verify task is gone
        let found = try repository.findById(id)
        XCTAssertNil(found)
    }

    func testDelete_NonExistentTask_ShouldReturnFalse() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let deleted = try repository.delete(nonExistentId)

        // Then
        XCTAssertFalse(deleted)
    }

    // MARK: - Status Operation Tests

    func testMarkAsCompleted_ShouldUpdateStatusAndCompletedAt() throws {
        // Given
        let task = try repository.create(title: "Task to Complete")
        let id = task.id!
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)

        // When
        let completed = try repository.markAsCompleted(id)

        // Then
        XCTAssertTrue(completed.isCompleted)
        XCTAssertEqual(completed.status, MaintenanceTask.TaskStatus.completed.rawValue)
        XCTAssertNotNil(completed.completedAt)
    }

    func testMarkAsPending_ShouldUpdateStatusAndClearCompletedAt() throws {
        // Given
        let task = try repository.create(title: "Task")
        let id = task.id!
        _ = try repository.markAsCompleted(id)

        // When
        let pending = try repository.markAsPending(id)

        // Then
        XCTAssertFalse(pending.isCompleted)
        XCTAssertEqual(pending.status, MaintenanceTask.TaskStatus.pending.rawValue)
        XCTAssertNil(pending.completedAt)
    }

    // MARK: - Query Method Tests

    func testFindByAssetId_ShouldReturnOnlyTasksForAsset() throws {
        // Given
        let asset2 = try assetRepo.create(homeId: testHomeId, name: "Asset 2")
        let asset2Id = asset2.id!

        try repository.create(title: "Task 1", assetId: testAssetId)
        try repository.create(title: "Task 2", assetId: testAssetId)
        try repository.create(title: "Task 3", assetId: asset2Id)

        // When
        let tasks = try repository.findByAssetId(testAssetId)

        // Then
        XCTAssertEqual(tasks.count, 2)
        XCTAssertTrue(tasks.allSatisfy { $0.assetId == testAssetId })
    }

    func testFindByStatus_ShouldReturnOnlyTasksWithStatus() throws {
        // Given
        let task1 = try repository.create(title: "Pending Task 1")
        let task2 = try repository.create(title: "Pending Task 2")
        let task3 = try repository.create(title: "Completed Task")
        try repository.markAsCompleted(task3.id!)

        // When
        let pendingTasks = try repository.findByStatus(MaintenanceTask.TaskStatus.pending.rawValue)

        // Then
        XCTAssertEqual(pendingTasks.count, 2)
        XCTAssertTrue(pendingTasks.allSatisfy { $0.status == MaintenanceTask.TaskStatus.pending.rawValue })
    }

    func testFindPending_ShouldReturnPendingTasks() throws {
        // Given
        try repository.create(title: "Pending 1")
        try repository.create(title: "Pending 2")
        let completed = try repository.create(title: "Completed")
        try repository.markAsCompleted(completed.id!)

        // When
        let pending = try repository.findPending()

        // Then
        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.allSatisfy { $0.status == MaintenanceTask.TaskStatus.pending.rawValue })
    }

    func testFindCompleted_ShouldReturnCompletedTasks() throws {
        // Given
        try repository.create(title: "Pending")
        let task2 = try repository.create(title: "Completed 1")
        let task3 = try repository.create(title: "Completed 2")
        try repository.markAsCompleted(task2.id!)
        try repository.markAsCompleted(task3.id!)

        // When
        let completed = try repository.findCompleted()

        // Then
        XCTAssertEqual(completed.count, 2)
        XCTAssertTrue(completed.allSatisfy { $0.isCompleted })
    }

    func testFindOverdue_ShouldReturnOverdueTasks() throws {
        // Given
        let pastDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        let futureDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now

        try repository.create(title: "Overdue Task", dueDate: pastDate)
        try repository.create(title: "Future Task", dueDate: futureDate)
        try repository.create(title: "No Due Date")

        // When
        let overdue = try repository.findOverdue()

        // Then
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue.first?.title, "Overdue Task")
        XCTAssertTrue(overdue.first?.isOverdue ?? false)
    }

    func testFindOverdue_ShouldExcludeCompletedTasks() throws {
        // Given
        let pastDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let overdueTask = try repository.create(title: "Overdue but Completed", dueDate: pastDate)
        try repository.markAsCompleted(overdueTask.id!)

        // When
        let overdue = try repository.findOverdue()

        // Then
        XCTAssertEqual(overdue.count, 0)
    }

    func testFindUpcoming_ShouldReturnTasksDueWithinDays() throws {
        // Given
        let in5Days = Date().addingTimeInterval(5 * 24 * 60 * 60)
        let in15Days = Date().addingTimeInterval(15 * 24 * 60 * 60)
        let in45Days = Date().addingTimeInterval(45 * 24 * 60 * 60)

        try repository.create(title: "Due in 5 days", dueDate: in5Days)
        try repository.create(title: "Due in 15 days", dueDate: in15Days)
        try repository.create(title: "Due in 45 days", dueDate: in45Days)

        // When
        let upcoming = try repository.findUpcoming(days: 30)

        // Then
        XCTAssertEqual(upcoming.count, 2) // Only tasks within 30 days
    }

    func testFindByPriority_ShouldReturnTasksWithPriority() throws {
        // Given
        try repository.create(
            title: "High Priority 1",
            priority: MaintenanceTask.TaskPriority.high.rawValue
        )
        try repository.create(
            title: "High Priority 2",
            priority: MaintenanceTask.TaskPriority.high.rawValue
        )
        try repository.create(
            title: "Low Priority",
            priority: MaintenanceTask.TaskPriority.low.rawValue
        )

        // When
        let highPriority = try repository.findByPriority(MaintenanceTask.TaskPriority.high.rawValue)

        // Then
        XCTAssertEqual(highPriority.count, 2)
        XCTAssertTrue(highPriority.allSatisfy { $0.priority == MaintenanceTask.TaskPriority.high.rawValue })
    }

    func testFindByPriority_ShouldExcludeCompleted() throws {
        // Given
        let task = try repository.create(
            title: "High Priority Completed",
            priority: MaintenanceTask.TaskPriority.high.rawValue
        )
        try repository.markAsCompleted(task.id!)

        // When
        let highPriority = try repository.findByPriority(MaintenanceTask.TaskPriority.high.rawValue)

        // Then
        XCTAssertEqual(highPriority.count, 0)
    }

    // MARK: - Count Tests

    func testCount_ShouldReturnCorrectNumber() throws {
        // Given
        try repository.create(title: "Task 1")
        try repository.create(title: "Task 2")
        try repository.create(title: "Task 3")

        // When
        let count = try repository.count()

        // Then
        XCTAssertEqual(count, 3)
    }

    // MARK: - Model Property Tests

    func testIsOverdue_WithPastDueDate_ShouldReturnTrue() throws {
        // Given
        let pastDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let task = try repository.create(title: "Overdue", dueDate: pastDate)

        // Then
        XCTAssertTrue(task.isOverdue)
    }

    func testIsOverdue_WithFutureDueDate_ShouldReturnFalse() throws {
        // Given
        let futureDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let task = try repository.create(title: "Not Overdue", dueDate: futureDate)

        // Then
        XCTAssertFalse(task.isOverdue)
    }

    func testIsOverdue_WhenCompleted_ShouldReturnFalse() throws {
        // Given
        let pastDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let task = try repository.create(title: "Completed Overdue", dueDate: pastDate)
        let completed = try repository.markAsCompleted(task.id!)

        // Then
        XCTAssertFalse(completed.isOverdue)
    }
}
