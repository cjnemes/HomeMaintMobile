import SwiftUI

struct MaintenanceRecordFormView: View {

    enum Mode {
        case create
        case edit(MaintenanceRecord)
    }

    let mode: Mode
    let preselectedAssetId: Int64?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var maintenanceType = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var costString = ""
    @State private var performedAt = Date()
    @State private var selectedAsset: Asset?
    @State private var selectedProvider: ServiceProvider?

    @State private var assets: [Asset] = []
    @State private var providers: [ServiceProvider] = []

    @State private var errorMessage: String?
    @State private var isSaving = false

    private let recordRepo = MaintenanceRecordRepository()
    private let assetRepo = AssetRepository()
    private let providerRepo = ServiceProviderRepository()
    private let seedService = SeedDataService.shared

    init(mode: Mode, preselectedAssetId: Int64? = nil, onSave: @escaping () -> Void) {
        self.mode = mode
        self.preselectedAssetId = preselectedAssetId
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Maintenance Information") {
                    TextField("Maintenance Type", text: $maintenanceType)
                        .autocapitalization(.words)

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

                Section("Asset & Provider") {
                    Picker("Asset", selection: $selectedAsset) {
                        Text("Select Asset").tag(nil as Asset?)
                        ForEach(assets) { asset in
                            Text(asset.name).tag(asset as Asset?)
                        }
                    }

                    Picker("Service Provider", selection: $selectedProvider) {
                        Text("None").tag(nil as ServiceProvider?)
                        ForEach(providers) { provider in
                            Text(provider.company).tag(provider as ServiceProvider?)
                        }
                    }
                }

                Section("Cost & Date") {
                    HStack {
                        Text("$")
                        TextField("Cost (optional)", text: $costString)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker(
                        "Performed On",
                        selection: $performedAt,
                        displayedComponents: .date
                    )
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Additional notes (optional)")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .allowsHitTesting(false)
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
                            await saveRecord()
                        }
                    }
                    .disabled(!isValid || isSaving)
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

    // MARK: - Validation

    private var isValid: Bool {
        !maintenanceType.isEmpty && selectedAsset != nil
    }

    // MARK: - Data Loading

    private func loadData() async {
        do {
            let home = try await Task {
                try seedService.getOrCreateHome()
            }.value

            assets = try await Task {
                try assetRepo.findByHomeId(home.id!)
            }.value

            providers = try await Task {
                try providerRepo.findByHomeId(home.id!)
            }.value

            // Preselect asset if provided
            if let preselectedId = preselectedAssetId {
                selectedAsset = assets.first { $0.id == preselectedId }
            }

            // Load existing record data if editing
            if case .edit(let record) = mode {
                maintenanceType = record.maintenanceType
                description = record.description ?? ""
                notes = record.notes ?? ""
                performedAt = record.performedAt
                selectedAsset = assets.first { $0.id == record.assetId }
                if let providerId = record.serviceProviderId {
                    selectedProvider = providers.first { $0.id == providerId }
                }
                if let cost = record.cost {
                    costString = "\(cost)"
                }
            }

        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
    }

    // MARK: - Save Logic

    private func saveRecord() async {
        guard isValid else { return }

        isSaving = true
        errorMessage = nil

        do {
            let cost = parseCost(from: costString)

            switch mode {
            case .create:
                _ = try await Task {
                    try recordRepo.create(
                        assetId: selectedAsset!.id!,
                        serviceProviderId: selectedProvider?.id,
                        maintenanceType: maintenanceType,
                        description: description.isEmpty ? nil : description,
                        cost: cost,
                        performedAt: performedAt,
                        notes: notes.isEmpty ? nil : notes
                    )
                }.value

            case .edit(var record):
                record.maintenanceType = maintenanceType
                record.description = description.isEmpty ? nil : description
                record.notes = notes.isEmpty ? nil : notes
                record.cost = cost
                record.performedAt = performedAt
                record.assetId = selectedAsset!.id!
                record.serviceProviderId = selectedProvider?.id

                _ = try await Task {
                    try recordRepo.update(record)
                }.value
            }

            onSave()
            dismiss()

        } catch {
            errorMessage = "Failed to save record: \(error.localizedDescription)"
        }

        isSaving = false
    }

    // MARK: - Helper Methods

    private func parseCost(from string: String) -> Decimal? {
        guard !string.isEmpty else { return nil }
        return Decimal(string: string)
    }
}

// MARK: - Mode Extension

extension MaintenanceRecordFormView.Mode {
    var title: String {
        switch self {
        case .create:
            return "New Maintenance Record"
        case .edit:
            return "Edit Record"
        }
    }
}
