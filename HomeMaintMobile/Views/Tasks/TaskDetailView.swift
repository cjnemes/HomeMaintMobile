import SwiftUI

struct TaskDetailView: View {

    let task: MaintenanceTask

    @State private var relatedAsset: Asset?
    @State private var showingEditSheet = false
    @State private var isCompleted: Bool

    @Environment(\.dismiss) private var dismiss

    private let assetRepo = AssetRepository()
    private let taskRepo = MaintenanceTaskRepository()

    init(task: MaintenanceTask) {
        self.task = task
        _isCompleted = State(initialValue: task.isCompleted)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Section
                statusCard

                // Details Section
                detailsCard

                // Asset Section (if associated)
                if relatedAsset != nil {
                    assetCard
                }

                // Actions Section
                if !isCompleted {
                    actionsCard
                }
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .task {
            await loadRelatedAsset()
        }
        .sheet(isPresented: $showingEditSheet) {
            TaskFormView(mode: .edit(task)) {
                // Refresh is handled by parent view
                dismiss()
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
            }

            if let priority = task.priorityEnum {
                PriorityBadge(priority: priority)
            }

            HStack(spacing: 12) {
                StatusBadge(status: task.statusEnum)

                if task.isOverdue && !isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Overdue")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)

            if let dueDate = task.dueDate {
                DetailRow(
                    icon: "calendar",
                    label: "Due Date",
                    value: formatDate(dueDate),
                    valueColor: task.isOverdue && !isCompleted ? .red : .primary
                )
            }

            if let description = task.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        Text("Description")
                            .foregroundColor(.secondary)
                    }
                    Text(description)
                        .padding(.leading, 32)
                }
            }

            DetailRow(
                icon: "clock",
                label: "Created",
                value: formatDate(task.createdAt)
            )

            if let completedAt = task.completedAt {
                DetailRow(
                    icon: "checkmark.circle",
                    label: "Completed",
                    value: formatDate(completedAt)
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var assetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Asset")
                .font(.headline)

            if let asset = relatedAsset {
                NavigationLink(destination: AssetDetailView(asset: asset)) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.name)
                                .font(.body)
                                .foregroundColor(.primary)

                            if let manufacturer = asset.manufacturer {
                                Text(manufacturer)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await markAsCompleted()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Mark as Completed")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func loadRelatedAsset() async {
        guard let assetId = task.assetId else { return }

        do {
            relatedAsset = try assetRepo.findById(assetId)
        } catch {
            print("❌ Error loading related asset: \(error)")
        }
    }

    private func markAsCompleted() async {
        guard let id = task.id else { return }

        do {
            _ = try taskRepo.markAsCompleted(id)
            isCompleted = true
            print("✅ Task marked as completed")

            // Delay dismiss to show completion state
            try? await Task.sleep(for: .milliseconds(500))
            dismiss()
        } catch {
            print("❌ Error marking task as completed: \(error)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
