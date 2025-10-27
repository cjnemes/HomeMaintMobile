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

    // Photo capture
    @State private var showingPhotoOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var capturedPhotos: [UIImage] = []
    @State private var existingAttachments: [Attachment] = []

    private let recordRepo = MaintenanceRecordRepository()
    private let assetRepo = AssetRepository()
    private let providerRepo = ServiceProviderRepository()
    private let attachmentRepo = AttachmentRepository()
    private let fileStorage = FileStorageService.shared
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

                Section("Photos") {
                    // Existing attachments (edit mode)
                    if !existingAttachments.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(existingAttachments) { attachment in
                                    AsyncImage(url: URL(string: attachment.relativePath)) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            ProgressView()
                                        }
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    // Newly captured photos
                    if !capturedPhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(capturedPhotos.enumerated()), id: \.offset) { index, photo in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: photo)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Button {
                                            capturedPhotos.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white))
                                        }
                                        .offset(x: 8, y: -8)
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        showingPhotoOptions = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Add Photo")
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
            .confirmationDialog("Choose Photo Source", isPresented: $showingPhotoOptions) {
                Button("Take Photo") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingPhotoLibrary = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(selectedImage: Binding(
                    get: { nil },
                    set: { if let image = $0 { capturedPhotos.append(image) } }
                ), sourceType: .camera)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePicker(selectedImage: Binding(
                    get: { nil },
                    set: { if let image = $0 { capturedPhotos.append(image) } }
                ), sourceType: .photoLibrary)
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
                maintenanceType = record.type
                description = record.description ?? ""
                notes = record.notes ?? ""
                performedAt = record.date
                selectedAsset = assets.first { $0.id == record.assetId }
                if let providerId = record.serviceProviderId {
                    selectedProvider = providers.first { $0.id == providerId }
                }
                if let cost = record.cost {
                    costString = "\(cost)"
                }

                // Load existing attachments
                existingAttachments = try await Task {
                    try attachmentRepo.findByMaintenanceRecordId(record.id!)
                }.value
                print("📷 Loaded \(existingAttachments.count) existing photos")
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
            let costValue = costString.isEmpty ? nil : costString

            let savedRecord: MaintenanceRecord
            switch mode {
            case .create:
                savedRecord = try await Task {
                    try recordRepo.create(
                        assetId: selectedAsset!.id!,
                        date: performedAt,
                        type: maintenanceType,
                        serviceProviderId: selectedProvider?.id,
                        description: description.isEmpty ? nil : description,
                        cost: costValue,
                        notes: notes.isEmpty ? nil : notes
                    )
                }.value

            case .edit(let record):
                savedRecord = try await Task {
                    try recordRepo.update(
                        record.id!,
                        date: performedAt,
                        type: maintenanceType,
                        serviceProviderId: selectedProvider?.id,
                        description: description.isEmpty ? nil : description,
                        cost: costValue,
                        notes: notes.isEmpty ? nil : notes
                    )
                }.value
            }

            // Save captured photos
            for photo in capturedPhotos {
                try await savePhoto(photo, for: savedRecord.id!)
            }

            onSave()
            dismiss()

        } catch {
            errorMessage = "Failed to save record: \(error.localizedDescription)"
        }

        isSaving = false
    }

    private func savePhoto(_ image: UIImage, for recordId: Int64) async throws {
        // Store image file
        let filename = "maintenance_\(recordId)_\(UUID().uuidString).jpg"
        let result = try await Task {
            try fileStorage.storeImage(image, filename: filename)
        }.value

        // Create attachment record
        _ = try await Task {
            try attachmentRepo.create(
                maintenanceRecordId: recordId,
                type: "photo",
                filename: filename,
                relativePath: result.relativePath,
                fileSize: result.fileSize,
                mimeType: "image/jpeg"
            )
        }.value

        print("📷 Saved photo: \(result.relativePath)")
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
