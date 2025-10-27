import SwiftUI

struct TaskListView: View {

    @StateObject private var viewModel = TaskListViewModel()
    @State private var showingAddTask = false
    @State private var showingFilterSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView("Loading tasks...")
                } else if viewModel.tasks.isEmpty {
                    emptyStateView
                } else {
                    taskList
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Search tasks")
            .onChange(of: viewModel.searchQuery) { _, newValue in
                Task {
                    await viewModel.search(newValue)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddTask) {
                TaskFormView(mode: .create) {
                    Task {
                        await viewModel.loadTasks()
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                filterView
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    private var taskList: some View {
        List {
            // Statistics Section
            Section {
                statsView
            }

            // Tasks Section
            Section {
                ForEach(viewModel.tasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        TaskRowView(task: task) {
                            Task {
                                await viewModel.toggleTaskCompletion(task)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let task = viewModel.tasks[index]
                        Task {
                            await viewModel.deleteTask(task)
                        }
                    }
                }
            } header: {
                Text(viewModel.filterStatus.rawValue)
            }
        }
    }

    private var statsView: some View {
        HStack(spacing: 20) {
            StatBadge(
                label: "Overdue",
                count: viewModel.overdueCount,
                color: .red,
                icon: "exclamationmark.triangle"
            )

            StatBadge(
                label: "Pending",
                count: viewModel.pendingCount,
                color: .orange,
                icon: "clock"
            )

            StatBadge(
                label: "Completed",
                count: viewModel.completedCount,
                color: .green,
                icon: "checkmark.circle"
            )
        }
        .padding(.vertical, 8)
    }

    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if viewModel.filterStatus != .all || viewModel.filterPriority != nil {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private var filterView: some View {
        NavigationStack {
            Form {
                Section("Status Filter") {
                    Picker("Status", selection: Binding(
                        get: { viewModel.filterStatus },
                        set: { newValue in
                            Task {
                                await viewModel.setFilter(newValue)
                            }
                        }
                    )) {
                        ForEach(TaskListViewModel.TaskFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Priority Filter") {
                    Picker("Priority", selection: Binding(
                        get: { viewModel.filterPriority },
                        set: { newValue in
                            Task {
                                await viewModel.setPriorityFilter(newValue)
                            }
                        }
                    )) {
                        Text("All Priorities").tag(nil as MaintenanceTask.TaskPriority?)
                        ForEach(MaintenanceTask.TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayText).tag(priority as MaintenanceTask.TaskPriority?)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Tasks Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first maintenance task to stay on top of home care")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingAddTask = true
            } label: {
                Label("Add Task", systemImage: "plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - Supporting Views

struct TaskRowView: View {
    let task: MaintenanceTask
    let onToggleCompletion: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button(action: onToggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted, color: .gray)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    // Priority badge
                    if let priority = task.priorityEnum {
                        PriorityBadge(priority: priority)
                    }

                    // Due date
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: task.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                                .font(.caption2)
                            Text(formatDate(dueDate))
                                .font(.caption)
                        }
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                    }
                }
            }

            Spacer()

            if task.isOverdue && !task.isCompleted {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct PriorityBadge: View {
    let priority: MaintenanceTask.TaskPriority

    var body: some View {
        Text(priority.displayText)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }

    private var backgroundColor: Color {
        switch priority {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct StatBadge: View {
    let label: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
