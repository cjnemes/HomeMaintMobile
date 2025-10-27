import XCTest
@testable import HomeMaintMobile

@MainActor
final class TaskListViewModelTests: XCTestCase {

    var viewModel: TaskListViewModel!
    var taskRepo: MaintenanceTaskRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        taskRepo = MaintenanceTaskRepository()

        // Create test tasks
        try taskRepo.create(title: "Task 1", priority: MaintenanceTask.TaskPriority.high.rawValue)
        try taskRepo.create(title: "Task 2", priority: MaintenanceTask.TaskPriority.medium.rawValue)
        try taskRepo.create(title: "Task 3", priority: MaintenanceTask.TaskPriority.low.rawValue)

        viewModel = TaskListViewModel()
    }

    override func tearDownWithError() throws {
        try? DatabaseService.shared.resetAllData()

        viewModel = nil
        taskRepo = nil

        try super.tearDownWithError()
    }

    // MARK: - Load Tests

    func testLoadTasks_ShouldPopulateTasksList() async throws {
        // When
        await viewModel.loadTasks()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.tasks.count, 3)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadTasks_AfterLoad_IsLoadingShouldBeFalse() async throws {
        // When
        await viewModel.loadTasks()

        // Then
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Delete Tests

    func testDeleteTask_ShouldRemoveFromList() async throws {
        // Given
        await viewModel.loadTasks()
        let initialCount = viewModel.tasks.count
        let taskToDelete = viewModel.tasks.first!

        // When
        await viewModel.deleteTask(taskToDelete)

        // Then
        XCTAssertEqual(viewModel.tasks.count, initialCount - 1)
        XCTAssertFalse(viewModel.tasks.contains { $0.id == taskToDelete.id })
    }

    // MARK: - Toggle Completion Tests

    func testToggleTaskCompletion_WhenPending_ShouldMarkAsCompleted() async throws {
        // Given
        await viewModel.loadTasks()
        let task = viewModel.tasks.first!
        XCTAssertFalse(task.isCompleted)

        // When
        await viewModel.toggleTaskCompletion(task)

        // Then
        // Reload to get updated task
        await viewModel.loadTasks()
        let updatedTask = viewModel.tasks.first { $0.id == task.id }
        XCTAssertTrue(updatedTask?.isCompleted ?? false)
    }

    func testToggleTaskCompletion_WhenCompleted_ShouldMarkAsPending() async throws {
        // Given
        let task = try taskRepo.create(title: "Completed Task")
        _ = try taskRepo.markAsCompleted(task.id!)
        await viewModel.loadTasks()

        let completedTask = viewModel.tasks.first { $0.id == task.id }!
        XCTAssertTrue(completedTask.isCompleted)

        // When
        await viewModel.toggleTaskCompletion(completedTask)

        // Then
        await viewModel.loadTasks()
        let updatedTask = viewModel.tasks.first { $0.id == task.id }
        XCTAssertFalse(updatedTask?.isCompleted ?? true)
    }

    // MARK: - Search Tests

    func testSearch_WithQuery_ShouldFilterResults() async throws {
        // Given
        await viewModel.loadTasks()
        XCTAssertEqual(viewModel.tasks.count, 3)

        // When
        await viewModel.search("Task 1")

        // Then
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks.first?.title, "Task 1")
    }

    func testSearch_WithEmptyQuery_ShouldShowAllTasks() async throws {
        // Given
        await viewModel.search("Task 1")
        XCTAssertEqual(viewModel.tasks.count, 1)

        // When
        await viewModel.search("")

        // Then
        XCTAssertEqual(viewModel.tasks.count, 3)
    }

    func testSearch_ShouldSearchInDescription() async throws {
        // Given
        try taskRepo.create(title: "Special Task", description: "Contains unique description")
        await viewModel.loadTasks()

        // When
        await viewModel.search("unique")

        // Then
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks.first?.title, "Special Task")
    }

    // MARK: - Filter Tests

    func testSetFilter_Pending_ShouldShowOnlyPendingTasks() async throws {
        // Given
        let task = try taskRepo.create(title: "Completed Task")
        _ = try taskRepo.markAsCompleted(task.id!)
        await viewModel.loadTasks()

        // When
        await viewModel.setFilter(.pending)

        // Then
        XCTAssertTrue(viewModel.tasks.allSatisfy { !$0.isCompleted })
    }

    func testSetFilter_Completed_ShouldShowOnlyCompletedTasks() async throws {
        // Given
        let task = try taskRepo.create(title: "Completed Task")
        _ = try taskRepo.markAsCompleted(task.id!)
        await viewModel.loadTasks()

        // When
        await viewModel.setFilter(.completed)

        // Then
        XCTAssertTrue(viewModel.tasks.allSatisfy { $0.isCompleted })
    }

    func testSetFilter_Overdue_ShouldShowOnlyOverdueTasks() async throws {
        // Given
        let pastDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        try taskRepo.create(title: "Overdue Task", dueDate: pastDate)
        await viewModel.loadTasks()

        // When
        await viewModel.setFilter(.overdue)

        // Then
        XCTAssertTrue(viewModel.tasks.allSatisfy { $0.isOverdue })
    }

    func testSetFilter_Upcoming_ShouldShowTasksDueWithin30Days() async throws {
        // Given
        let in15Days = Date().addingTimeInterval(15 * 24 * 60 * 60)
        let in45Days = Date().addingTimeInterval(45 * 24 * 60 * 60)
        try taskRepo.create(title: "Due in 15 days", dueDate: in15Days)
        try taskRepo.create(title: "Due in 45 days", dueDate: in45Days)
        await viewModel.loadTasks()

        // When
        await viewModel.setFilter(.upcoming)

        // Then
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks.first?.title, "Due in 15 days")
    }

    func testSetFilter_All_ShouldShowAllTasks() async throws {
        // Given
        let task = try taskRepo.create(title: "Completed Task")
        _ = try taskRepo.markAsCompleted(task.id!)
        await viewModel.setFilter(.completed)

        // When
        await viewModel.setFilter(.all)

        // Then
        // Should show pending tasks (3) + completed task (1)
        XCTAssertEqual(viewModel.tasks.count, 4)
    }

    // MARK: - Priority Filter Tests

    func testSetPriorityFilter_ShouldShowOnlyTasksWithPriority() async throws {
        // Given
        await viewModel.loadTasks()

        // When
        await viewModel.setPriorityFilter(.high)

        // Then
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertTrue(viewModel.tasks.allSatisfy { $0.priority == MaintenanceTask.TaskPriority.high.rawValue })
    }

    func testSetPriorityFilter_Nil_ShouldShowAllTasks() async throws {
        // Given
        await viewModel.setPriorityFilter(.high)
        XCTAssertEqual(viewModel.tasks.count, 1)

        // When
        await viewModel.setPriorityFilter(nil)

        // Then
        XCTAssertEqual(viewModel.tasks.count, 3)
    }

    // MARK: - Refresh Tests

    func testRefresh_ShouldReloadData() async throws {
        // Given
        await viewModel.loadTasks()
        let initialCount = viewModel.tasks.count

        // Add new task
        try taskRepo.create(title: "New Task")

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.tasks.count, initialCount + 1)
    }

    // MARK: - Computed Properties Tests

    func testOverdueCount_ShouldReturnCorrectCount() async throws {
        // Given
        let pastDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        try taskRepo.create(title: "Overdue 1", dueDate: pastDate)
        try taskRepo.create(title: "Overdue 2", dueDate: pastDate)
        await viewModel.loadTasks()

        // Then
        XCTAssertEqual(viewModel.overdueCount, 2)
    }

    func testPendingCount_ShouldReturnCorrectCount() async throws {
        // Given
        let task = try taskRepo.create(title: "To Complete")
        _ = try taskRepo.markAsCompleted(task.id!)
        await viewModel.loadTasks()

        // Then - 3 original tasks + 1 new pending = 3 pending (1 completed excluded)
        XCTAssertEqual(viewModel.pendingCount, 3)
    }

    func testCompletedCount_ShouldReturnCorrectCount() async throws {
        // Given
        let task1 = try taskRepo.create(title: "Completed 1")
        let task2 = try taskRepo.create(title: "Completed 2")
        _ = try taskRepo.markAsCompleted(task1.id!)
        _ = try taskRepo.markAsCompleted(task2.id!)
        await viewModel.loadTasks()

        // Then
        XCTAssertEqual(viewModel.completedCount, 2)
    }

    // MARK: - Combined Filter Tests

    func testCombinedFilters_StatusAndPriority_ShouldWork() async throws {
        // Given
        try taskRepo.create(title: "High Priority Task", priority: MaintenanceTask.TaskPriority.high.rawValue)
        let completed = try taskRepo.create(title: "High Priority Completed", priority: MaintenanceTask.TaskPriority.high.rawValue)
        _ = try taskRepo.markAsCompleted(completed.id!)

        // When
        await viewModel.setFilter(.pending)
        await viewModel.setPriorityFilter(.high)

        // Then - Should only show pending high-priority tasks
        XCTAssertEqual(viewModel.tasks.count, 2) // Original high + new high (both pending)
        XCTAssertTrue(viewModel.tasks.allSatisfy { !$0.isCompleted && $0.priority == MaintenanceTask.TaskPriority.high.rawValue })
    }

    func testCombinedFilters_SearchAndFilter_ShouldWork() async throws {
        // Given
        try taskRepo.create(title: "Special Pending Task")
        let completed = try taskRepo.create(title: "Special Completed Task")
        _ = try taskRepo.markAsCompleted(completed.id!)
        await viewModel.loadTasks()

        // When
        await viewModel.setFilter(.pending)
        await viewModel.search("Special")

        // Then - Should only show pending tasks with "Special" in name
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks.first?.title, "Special Pending Task")
    }
}
