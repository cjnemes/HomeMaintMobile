import SwiftUI

struct TaskFormView: View {

    enum Mode {
        case create
        case edit(MaintenanceTask)
    }

    let mode: Mode
    let preselectedAssetId: Int64?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(mode: Mode, preselectedAssetId: Int64? = nil, onSave: @escaping () -> Void) {
        self.mode = mode
        self.preselectedAssetId = preselectedAssetId
        self.onSave = onSave
    }

    @State private var title = ""
    @State private var description = ""
    @State private var selectedAsset: Asset?
    @State private var dueDate: Date?
    @State private var selectedPriority: MaintenanceTask.TaskPriority?
    @State private var selectedStatus: MaintenanceTask.TaskStatus = .pending

    @State private var assets: [Asset] = []

    @State private var showDueDatePicker = false

    @State private var errorMessage: String?
    @State private var isSaving = false

    private let taskRepo = MaintenanceTaskRepository()
    private let assetRepo = AssetRepository()
    private let seedService = SeedDataService.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Title", text: $title)

                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Description (optional)")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Asset Association") {
                    Picker("Related Asset", selection: $selectedAsset) {
                        Text("None").tag(nil as Asset?)
                        ForEach(assets) { asset in
                            Text(asset.name).tag(asset as Asset?)
                        }
                    }
                }

                Section("Due Date") {
                    dueDateRow
                }

                Section("Priority") {
                    Picker("Priority", selection: $selectedPriority) {
                        Text("None").tag(nil as MaintenanceTask.TaskPriority?)
                        ForEach(MaintenanceTask.TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayText).tag(priority as MaintenanceTask.TaskPriority?)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if case .edit = mode {
                    Section("Status") {
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(MaintenanceTask.TaskStatus.allCases, id: \.self) { status in
                                Text(status.displayText).tag(status)
                            }
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveTask()
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .task {
                await loadData()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private var dueDateRow: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Due Date")

                Spacer()

                if let date = dueDate {
                    Text(formatDate(date))
                        .foregroundColor(.secondary)

                    Button {
                        dueDate = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                } else {
                    Button("Set") {
                        showDueDatePicker = true
                    }
                }
            }

            if showDueDatePicker {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }
        }
    }

    private func loadData() async {
        do {
            let home = try seedService.getOrCreateHome()

            guard let homeId = home.id else {
                errorMessage = "Home does not have a valid ID"
                print("❌ Error: Home missing ID")
                return
            }

            assets = try assetRepo.findByHomeId(homeId)
            print("📍 Loaded \(assets.count) assets for task form")

            // Preselect asset if provided
            if let preselectedId = preselectedAssetId {
                selectedAsset = assets.first { $0.id == preselectedId }
            }

            // Load existing task data for edit mode
            if case .edit(let task) = mode {
                title = task.title
                description = task.description ?? ""
                selectedAsset = assets.first { $0.id == task.assetId }
                dueDate = task.dueDate
                selectedPriority = task.priorityEnum
                selectedStatus = task.statusEnum
            }
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("❌ Error loading data: \(error)")
        }
    }

    private func saveTask() async {
        isSaving = true

        do {
            switch mode {
            case .create:
                _ = try taskRepo.create(
                    title: title,
                    assetId: selectedAsset?.id,
                    description: description.isEmpty ? nil : description,
                    dueDate: dueDate,
                    priority: selectedPriority?.rawValue,
                    status: selectedStatus.rawValue
                )

            case .edit(let task):
                guard let taskId = task.id else {
                    errorMessage = "Task does not have a valid ID"
                    isSaving = false
                    return
                }

                _ = try taskRepo.update(
                    taskId,
                    title: title,
                    assetId: selectedAsset?.id,
                    description: description.isEmpty ? nil : description,
                    dueDate: dueDate,
                    priority: selectedPriority?.rawValue,
                    status: selectedStatus.rawValue
                )
            }

            onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save task: \(error.localizedDescription)"
            isSaving = false
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

extension TaskFormView.Mode {
    var title: String {
        switch self {
        case .create: return "New Task"
        case .edit: return "Edit Task"
        }
    }
}
