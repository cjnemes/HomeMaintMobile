import SwiftUI

struct AssetFormView: View {

    enum Mode {
        case create
        case edit(Asset)
    }

    let mode: Mode
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var manufacturer = ""
    @State private var modelNumber = ""
    @State private var serialNumber = ""
    @State private var selectedCategory: Category?
    @State private var selectedLocation: Location?
    @State private var purchaseDate: Date?
    @State private var installationDate: Date?
    @State private var warrantyExpiration: Date?
    @State private var notes = ""

    @State private var categories: [Category] = []
    @State private var locations: [Location] = []

    @State private var showPurchaseDatePicker = false
    @State private var showInstallDatePicker = false
    @State private var showWarrantyDatePicker = false

    @State private var errorMessage: String?
    @State private var isSaving = false

    // Photo capture
    @State private var showingPhotoOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var capturedPhotos: [UIImage] = []
    @State private var existingAttachments: [Attachment] = []

    private let assetRepo = AssetRepository()
    private let categoryRepo = CategoryRepository()
    private let locationRepo = LocationRepository()
    private let attachmentRepo = AttachmentRepository()
    private let fileStorage = FileStorageService.shared
    private let seedService = SeedDataService.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Model Number", text: $modelNumber)
                    TextField("Serial Number", text: $serialNumber)
                }

                Section("Classification") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }

                    Picker("Location", selection: $selectedLocation) {
                        Text("None").tag(nil as Location?)
                        ForEach(locations) { location in
                            Text(location.name).tag(location as Location?)
                        }
                    }
                }

                Section("Dates") {
                    datePickerRow(
                        label: "Purchase Date",
                        date: $purchaseDate,
                        showPicker: $showPurchaseDatePicker
                    )

                    datePickerRow(
                        label: "Installation Date",
                        date: $installationDate,
                        showPicker: $showInstallDatePicker
                    )

                    datePickerRow(
                        label: "Warranty Expiration",
                        date: $warrantyExpiration,
                        showPicker: $showWarrantyDatePicker
                    )
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
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
                            await saveAsset()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
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

    private func datePickerRow(label: String, date: Binding<Date?>, showPicker: Binding<Bool>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)

                Spacer()

                if let dateValue = date.wrappedValue {
                    Text(formatDate(dateValue))
                        .foregroundColor(.secondary)

                    Button {
                        date.wrappedValue = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                } else {
                    Button("Set") {
                        showPicker.wrappedValue = true
                    }
                }
            }

            if showPicker.wrappedValue {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { date.wrappedValue ?? Date() },
                        set: { date.wrappedValue = $0 }
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
            print("📍 Home ID: \(home.id ?? -1)")

            categories = try categoryRepo.findByHomeId(home.id!)
            print("📍 Loaded \(categories.count) categories")

            locations = try locationRepo.findByHomeId(home.id!)
            print("📍 Loaded \(locations.count) locations")

            // Load existing asset data for edit mode
            if case .edit(let asset) = mode {
                name = asset.name
                manufacturer = asset.manufacturer ?? ""
                modelNumber = asset.modelNumber ?? ""
                serialNumber = asset.serialNumber ?? ""
                selectedCategory = categories.first { $0.id == asset.categoryId }
                selectedLocation = locations.first { $0.id == asset.locationId }
                purchaseDate = asset.purchaseDate
                installationDate = asset.installationDate
                warrantyExpiration = asset.warrantyExpiration
                notes = asset.notes ?? ""

                // Load existing attachments
                existingAttachments = try await Task {
                    try attachmentRepo.findByAssetId(asset.id!)
                }.value
                print("📷 Loaded \(existingAttachments.count) existing photos")
            }
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("❌ Error loading data: \(error)")
        }
    }

    private func saveAsset() async {
        isSaving = true

        do {
            let home = try seedService.getOrCreateHome()

            let savedAsset: Asset
            switch mode {
            case .create:
                savedAsset = try assetRepo.create(
                    homeId: home.id!,
                    name: name,
                    categoryId: selectedCategory?.id,
                    locationId: selectedLocation?.id,
                    manufacturer: manufacturer.isEmpty ? nil : manufacturer,
                    modelNumber: modelNumber.isEmpty ? nil : modelNumber,
                    serialNumber: serialNumber.isEmpty ? nil : serialNumber,
                    purchaseDate: purchaseDate,
                    installationDate: installationDate,
                    warrantyExpiration: warrantyExpiration,
                    notes: notes.isEmpty ? nil : notes
                )

            case .edit(let asset):
                savedAsset = try assetRepo.update(
                    asset.id!,
                    name: name,
                    categoryId: selectedCategory?.id,
                    locationId: selectedLocation?.id,
                    manufacturer: manufacturer.isEmpty ? nil : manufacturer,
                    modelNumber: modelNumber.isEmpty ? nil : modelNumber,
                    serialNumber: serialNumber.isEmpty ? nil : serialNumber,
                    purchaseDate: purchaseDate,
                    installationDate: installationDate,
                    warrantyExpiration: warrantyExpiration,
                    notes: notes.isEmpty ? nil : notes
                )
            }

            // Save captured photos
            for photo in capturedPhotos {
                try await savePhoto(photo, for: savedAsset.id!)
            }

            onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save asset: \(error.localizedDescription)"
            isSaving = false
        }
    }

    private func savePhoto(_ image: UIImage, for assetId: Int64) async throws {
        // Store image file
        let filename = "asset_\(assetId)_\(UUID().uuidString).jpg"
        let result = try await Task {
            try fileStorage.storeImage(image, filename: filename)
        }.value

        // Create attachment record
        _ = try await Task {
            try attachmentRepo.create(
                assetId: assetId,
                type: "photo",
                filename: filename,
                relativePath: result.relativePath,
                fileSize: result.fileSize,
                mimeType: "image/jpeg"
            )
        }.value

        print("📷 Saved photo: \(result.relativePath)")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

extension AssetFormView.Mode {
    var title: String {
        switch self {
        case .create: return "New Asset"
        case .edit: return "Edit Asset"
        }
    }
}
