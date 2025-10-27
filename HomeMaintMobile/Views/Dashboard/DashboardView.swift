import SwiftUI

struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    statsSection

                    // Alerts Section
                    if viewModel.alertsCount > 0 {
                        alertsSection
                    }

                    // Recent Maintenance
                    if !viewModel.recentMaintenance.isEmpty {
                        recentMaintenanceSection
                    }

                    // Upcoming Tasks
                    if !viewModel.upcomingTasks.isEmpty {
                        upcomingTasksSection
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboardData()
            }
        }
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(
                    title: "Assets",
                    value: "\(viewModel.totalAssets)",
                    icon: "house.fill",
                    color: .blue
                )

                statCard(
                    title: "Tasks",
                    value: "\(viewModel.pendingTasksCount)",
                    icon: "checklist",
                    color: .orange
                )
            }

            HStack(spacing: 12) {
                statCard(
                    title: "Maintenance",
                    value: "\(viewModel.maintenanceCount)",
                    icon: "wrench.and.screwdriver.fill",
                    color: .purple
                )

                statCard(
                    title: "Alerts",
                    value: "\(viewModel.alertsCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        NavigationLink {
            destinationView(for: title)
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 36, weight: .bold))

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func destinationView(for title: String) -> some View {
        switch title {
        case "Assets":
            AssetListView()
        case "Tasks", "Alerts":
            TaskListView()
        case "Maintenance":
            MaintenanceRecordListView()
        default:
            Text(title)
        }
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Alerts", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.red)

            if !viewModel.overdueTasks.isEmpty {
                ForEach(viewModel.overdueTasks.prefix(3)) { task in
                    alertCard(
                        title: task.title,
                        subtitle: "Task overdue",
                        icon: "clock.fill",
                        color: .red
                    )
                }
            }

            if !viewModel.expiringWarranties.isEmpty {
                ForEach(viewModel.expiringWarranties.prefix(3)) { asset in
                    alertCard(
                        title: asset.name,
                        subtitle: "Warranty expiring soon",
                        icon: "checkmark.seal.fill",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func alertCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private var recentMaintenanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Maintenance", systemImage: "wrench.and.screwdriver.fill")
                .font(.headline)

            ForEach(viewModel.recentMaintenance) { record in
                maintenanceCard(record)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func maintenanceCard(_ record: MaintenanceRecord) -> some View {
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

    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Upcoming Tasks", systemImage: "checklist")
                .font(.headline)

            ForEach(viewModel.upcomingTasks.prefix(5)) { task in
                taskCard(task)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func taskCard(_ task: MaintenanceTask) -> some View{
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let dueDate = task.dueDate {
                    Text(formatDate(dueDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let priority = task.priorityEnum {
                Text(priority.displayText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor(priority).opacity(0.2))
                    .foregroundColor(priorityColor(priority))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private func priorityColor(_ priority: MaintenanceTask.TaskPriority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
}
