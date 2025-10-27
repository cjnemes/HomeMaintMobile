import SwiftUI

struct MaintenanceRecordListView: View {

    @StateObject private var viewModel = MaintenanceRecordListViewModel()
    @State private var showingAddRecord = false
    @State private var showingFilterSheet = false

    // Optional filter parameters
    var filterAssetId: Int64? = nil
    var filterProviderId: Int64? = nil

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.records.isEmpty {
                ProgressView("Loading maintenance records...")
            } else if viewModel.filteredRecords.isEmpty {
                emptyStateView
            } else {
                recordList
            }
        }
        .navigationTitle("Maintenance History")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                filterButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddRecord = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search records")
        .refreshable {
            await loadRecords()
        }
        .sheet(isPresented: $showingAddRecord) {
            MaintenanceRecordFormView(
                mode: .create,
                preselectedAssetId: filterAssetId
            ) {
                Task {
                    await loadRecords()
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
        .task {
            await loadRecords()
        }
    }

    private var recordList: some View {
        List {
            // Statistics Section
            Section {
                statsView
            }

            // Records Section
            Section {
                ForEach(viewModel.filteredRecords) { record in
                    NavigationLink(destination: MaintenanceRecordDetailView(record: record)) {
                        MaintenanceRecordRowView(record: record)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let record = viewModel.filteredRecords[index]
                        Task {
                            await viewModel.deleteRecord(record)
                        }
                    }
                }
            } header: {
                Text(sectionHeader)
            }
        }
    }

    private var statsView: some View {
        HStack(spacing: 20) {
            StatBadge(
                label: "Records",
                count: viewModel.recordCount,
                color: .blue,
                icon: "doc.text"
            )

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle")
                        .font(.caption)
                    Text(formatCurrency(viewModel.totalCost))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(.green)

                Text("Total Cost")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                    Text(formatCurrency(viewModel.averageCost))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(.orange)

                Text("Avg Cost")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if hasActiveFilters {
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
                Section("Quick Actions") {
                    Button {
                        Task {
                            await viewModel.loadRecentRecords(limit: 10)
                            showingFilterSheet = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "clock")
                            Text("Recent Records")
                        }
                    }

                    Button {
                        Task {
                            await viewModel.clearFilters()
                            showingFilterSheet = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Clear Filters")
                        }
                    }
                }

                if viewModel.filterAssetId != nil || viewModel.filterProviderId != nil {
                    Section("Active Filters") {
                        if viewModel.filterAssetId != nil {
                            HStack {
                                Text("Filtered by Asset")
                                Spacer()
                                Button("Clear") {
                                    Task {
                                        await viewModel.clearFilters()
                                    }
                                }
                            }
                        }
                        if viewModel.filterProviderId != nil {
                            HStack {
                                Text("Filtered by Provider")
                                Spacer()
                                Button("Clear") {
                                    Task {
                                        await viewModel.clearFilters()
                                    }
                                }
                            }
                        }
                    }
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
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Maintenance Records")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Track all maintenance, repairs, and service history for your home assets")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingAddRecord = true
            } label: {
                Label("Add Record", systemImage: "plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadRecords() async {
        if let assetId = filterAssetId {
            await viewModel.loadRecords(forAssetId: assetId)
        } else if let providerId = filterProviderId {
            await viewModel.loadRecords(forProviderId: providerId)
        } else {
            await viewModel.loadRecords()
        }
    }

    private var hasActiveFilters: Bool {
        viewModel.filterAssetId != nil ||
        viewModel.filterProviderId != nil ||
        viewModel.startDate != nil ||
        viewModel.endDate != nil
    }

    private var sectionHeader: String {
        if viewModel.filterAssetId != nil {
            return "Asset Maintenance History"
        } else if viewModel.filterProviderId != nil {
            return "Provider Service History"
        } else if viewModel.startDate != nil && viewModel.endDate != nil {
            return "Date Range Results"
        } else {
            return "All Maintenance Records"
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Supporting Views

struct MaintenanceRecordRowView: View {
    let record: MaintenanceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Type and Date
            HStack {
                Text(record.type)
                    .font(.headline)

                Spacer()

                Text(formatDate(record.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Description (if available)
            if let description = record.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Footer: Cost and Provider indicator
            HStack {
                if let formattedCost = record.formattedCost {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption2)
                        Text(formattedCost)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.green)
                }

                Spacer()

                if record.serviceProviderId != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption2)
                        Text("Service Provider")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}
