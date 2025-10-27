import Foundation
import Combine

@MainActor
class TaskListViewModel: ObservableObject {

    @Published var tasks: [MaintenanceTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var filterStatus: TaskFilter = .all
    @Published var filterPriority: MaintenanceTask.TaskPriority? = nil

    private let taskRepo = MaintenanceTaskRepository()

    // MARK: - Enums

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case overdue = "Overdue"
        case upcoming = "Upcoming"
        case completed = "Completed"
    }

    // MARK: - Initialization

    init() {
        Task {
            await loadTasks()
        }
    }

    // MARK: - Load Data

    func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load tasks based on current filter
            tasks = try await loadTasksForFilter()

            // Apply priority filter if set
            if let priority = filterPriority {
                tasks = tasks.filter { $0.priority == priority.rawValue }
            }

            // Apply search filter if query is not empty
            if !searchQuery.isEmpty {
                tasks = tasks.filter { task in
                    task.title.localizedCaseInsensitiveContains(searchQuery) ||
                    (task.description?.localizedCaseInsensitiveContains(searchQuery) ?? false)
                }
            }

            print("✅ Loaded \(tasks.count) tasks (filter: \(filterStatus.rawValue))")
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            print("❌ Error loading tasks: \(error)")
        }

        isLoading = false
    }

    private func loadTasksForFilter() async throws -> [MaintenanceTask] {
        switch filterStatus {
        case .all:
            return try taskRepo.findAll()
        case .pending:
            return try taskRepo.findPending()
        case .overdue:
            return try taskRepo.findOverdue()
        case .upcoming:
            return try taskRepo.findUpcoming(days: 30)
        case .completed:
            return try taskRepo.findCompleted()
        }
    }

    // MARK: - Actions

    func deleteTask(_ task: MaintenanceTask) async {
        guard let id = task.id else { return }

        do {
            try taskRepo.delete(id)
            await loadTasks() // Reload list
            print("✅ Task deleted: \(task.title)")
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
            print("❌ Error deleting task: \(error)")
        }
    }

    func toggleTaskCompletion(_ task: MaintenanceTask) async {
        guard let id = task.id else { return }

        do {
            if task.isCompleted {
                _ = try taskRepo.markAsPending(id)
                print("✅ Task marked as pending: \(task.title)")
            } else {
                _ = try taskRepo.markAsCompleted(id)
                print("✅ Task marked as completed: \(task.title)")
            }
            await loadTasks() // Reload list
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
            print("❌ Error updating task: \(error)")
        }
    }

    func search(_ query: String) async {
        searchQuery = query
        await loadTasks()
    }

    func setFilter(_ filter: TaskFilter) async {
        filterStatus = filter
        await loadTasks()
    }

    func setPriorityFilter(_ priority: MaintenanceTask.TaskPriority?) async {
        filterPriority = priority
        await loadTasks()
    }

    func refresh() async {
        await loadTasks()
    }

    // MARK: - Computed Properties

    var overdueCount: Int {
        tasks.filter { $0.isOverdue }.count
    }

    var pendingCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
}
