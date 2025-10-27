import SwiftUI

struct AssetDetailView: View {

    @StateObject private var viewModel: AssetDetailViewModel
    @State private var showingEditAsset = false
    @State private var showingAddMaintenance = false
    @State private var showingAddTask = false

    init(asset: Asset) {
        _viewModel = StateObject(wrappedValue: AssetDetailViewModel(asset: asset))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Basic Info Section
                basicInfoSection

                // Stats Section
                statsSection

                // Warranty Section
                if viewModel.asset.warrantyExpiration != nil {
                    warrantySection
                }

                // Notes Section
                if let notes = viewModel.asset.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }

                // Quick Actions
                quickActionsSection

                // Recent Maintenance
                if !viewModel.maintenanceRecords.isEmpty {
                    maintenanceSection
                }

                // Pending Tasks
                if !viewModel.tasks.isEmpty {
                    tasksSection
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditAsset = true
                }
            }
        }
        .sheet(isPresented: $showingEditAsset) {
            AssetFormView(mode: .edit(viewModel.asset)) {
                Task {
                    await viewModel.loadRelatedData()
                }
            }
        }
        .sheet(isPresented: $showingAddMaintenance) {
            MaintenanceRecordFormView(
                mode: .create,
                preselectedAssetId: viewModel.asset.id
            ) {
                Task {
                    await viewModel.loadRelatedData()
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            TaskFormView(
                mode: .create,
                preselectedAssetId: viewModel.asset.id
            ) {
                Task {
                    await viewModel.loadRelatedData()
                }
            }
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let manufacturer = viewModel.asset.manufacturer {
                detailRow(label: "Manufacturer", value: manufacturer)
            }

            if let model = viewModel.asset.modelNumber {
                detailRow(label: "Model", value: model)
            }

            if let serial = viewModel.asset.serialNumber {
                detailRow(label: "Serial Number", value: serial)
            }

            if let category = viewModel.category {
                detailRow(label: "Category", value: category.name)
            }

            if let location = viewModel.location {
                detailRow(label: "Location", value: location.name)
            }

            if let purchaseDate = viewModel.asset.purchaseDate {
                detailRow(label: "Purchase Date", value: formatDate(purchaseDate))
            }

            if let installDate = viewModel.asset.installationDate {
                detailRow(label: "Installation Date", value: formatDate(installDate))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var statsSection: some View {
        HStack(spacing: 20) {
            statCard(
                title: "Maintenance",
                value: "\(viewModel.maintenanceCount)",
                icon: "wrench.and.screwdriver",
                color: .blue
            )

            statCard(
                title: "Tasks",
                value: "\(viewModel.pendingTasksCount)",
                icon: "checklist",
                color: .orange
            )

            statCard(
                title: "Photos",
                value: "\(viewModel.photoCount)",
                icon: "photo",
                color: .purple
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var warrantySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Warranty", systemImage: "checkmark.seal")
                .font(.headline)

            HStack {
                Circle()
                    .fill(warrantyColor)
                    .frame(width: 12, height: 12)

                Text(viewModel.warrantyStatusText)
                    .font(.subheadline)

                Spacer()

                if let expiration = viewModel.asset.warrantyExpiration {
                    Text(formatDate(expiration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showingAddMaintenance = true
            } label: {
                Label("Log Maintenance", systemImage: "wrench.and.screwdriver.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button {
                showingAddTask = true
            } label: {
                Label("Add Task", systemImage: "checklist")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Maintenance", systemImage: "wrench.and.screwdriver")
                .font(.headline)

            ForEach(viewModel.maintenanceRecords.prefix(3)) { record in
                maintenanceRow(record)
            }

            if viewModel.maintenanceRecords.count > 3 {
                Button("View All") {
                    // Navigate to full maintenance list
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func maintenanceRow(_ record: MaintenanceRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.type)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(formatDate(record.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let cost = record.formattedCost {
                Text(cost)
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tasks", systemImage: "checklist")
                .font(.headline)

            ForEach(viewModel.tasks.prefix(3)) { task in
                taskRow(task)
            }

            if viewModel.tasks.count > 3 {
                Button("View All") {
                    // Navigate to full task list
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func taskRow(_ task: MaintenanceTask) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let dueDate = task.dueDate {
                    Text(formatDate(dueDate))
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            if task.isOverdue {
                Text("Overdue")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private var warrantyColor: Color {
        switch viewModel.asset.warrantyStatus {
        case .active: return .green
        case .expiringSoon: return .orange
        case .expired: return .red
        case .unknown: return .gray
        }
    }
}
