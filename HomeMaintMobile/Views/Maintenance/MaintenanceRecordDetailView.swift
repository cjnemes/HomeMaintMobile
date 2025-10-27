import SwiftUI

struct MaintenanceRecordDetailView: View {

    let record: MaintenanceRecord

    @State private var relatedAsset: Asset?
    @State private var relatedProvider: ServiceProvider?
    @State private var showingEditSheet = false

    @Environment(\.dismiss) private var dismiss

    private let assetRepo = AssetRepository()
    private let providerRepo = ServiceProviderRepository()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Card
                headerCard

                // Details Card
                detailsCard

                // Asset Card (if associated)
                if relatedAsset != nil {
                    assetCard
                }

                // Provider Card (if associated)
                if relatedProvider != nil {
                    providerCard
                }

                // Cost Card (if cost recorded)
                if record.cost != nil {
                    costCard
                }

                // Notes Card (if notes exist)
                if let notes = record.notes, !notes.isEmpty {
                    notesCard(notes: notes)
                }
            }
            .padding()
        }
        .navigationTitle("Maintenance Record")
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
            await loadRelatedData()
        }
        .sheet(isPresented: $showingEditSheet) {
            MaintenanceRecordFormView(mode: .edit(record)) {
                dismiss()
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(record.type)
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(formatDate(record.date))
                    .foregroundColor(.secondary)

                Spacer()

                if let formattedCost = record.formattedCost {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                        Text(formattedCost)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.green)
                }
            }
            .font(.subheadline)
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

            if let description = record.description, !description.isEmpty {
                DetailRow(
                    icon: "doc.text",
                    label: "Description",
                    value: description
                )
            }

            DetailRow(
                icon: "clock",
                label: "Performed On",
                value: formatDateLong(record.date)
            )

            DetailRow(
                icon: "calendar.badge.plus",
                label: "Recorded On",
                value: formatDateLong(record.createdAt)
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var assetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Related Asset")
                    .font(.headline)

                Spacer()

                NavigationLink(destination: Text("Asset Detail")) { // TODO: Navigate to AssetDetailView
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }

            if let asset = relatedAsset {
                VStack(alignment: .leading, spacing: 8) {
                    Text(asset.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let manufacturer = asset.manufacturer {
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundColor(.secondary)
                            Text(manufacturer)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let modelNumber = asset.modelNumber {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.secondary)
                            Text("Model: \(modelNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var providerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Service Provider")
                    .font(.headline)

                Spacer()

                NavigationLink(destination: Text("Provider Detail")) { // TODO: Navigate to ServiceProviderDetailView
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }

            if let provider = relatedProvider {
                VStack(alignment: .leading, spacing: 8) {
                    Text(provider.company)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let name = provider.name {
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.secondary)
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let phone = provider.phone {
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.secondary)
                            Link(phone, destination: URL(string: "tel:\(phone)")!)
                                .font(.caption)
                        }
                    }

                    if let email = provider.email {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                            Link(email, destination: URL(string: "mailto:\(email)")!)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var costCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Details")
                .font(.headline)

            if let formattedCost = record.formattedCost {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Service Cost")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(formattedCost)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.secondary)
                Text("Notes")
                    .font(.headline)
            }

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // MARK: - Data Loading

    private func loadRelatedData() async {
        do {
            relatedAsset = try await Task {
                try assetRepo.findById(record.assetId)
            }.value

            if let providerId = record.serviceProviderId {
                relatedProvider = try await Task {
                    try providerRepo.findById(providerId)
                }.value
            }
        } catch {
            print("Failed to load related data: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDateLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}
