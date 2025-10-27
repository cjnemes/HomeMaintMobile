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

    private let assetRepo = AssetRepository()
    private let categoryRepo = CategoryRepository()
    private let locationRepo = LocationRepository()
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

            switch mode {
            case .create:
                _ = try assetRepo.create(
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
                _ = try assetRepo.update(
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

            onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save asset: \(error.localizedDescription)"
            isSaving = false
        }
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
