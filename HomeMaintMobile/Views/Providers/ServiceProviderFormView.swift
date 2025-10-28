import SwiftUI

struct ServiceProviderFormView: View {

    enum Mode {
        case create
        case edit(ServiceProvider)
    }

    let mode: Mode
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var company = ""
    @State private var name = ""
    @State private var specialty = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""

    @State private var errorMessage: String?
    @State private var isSaving = false

    private let providerRepo = ServiceProviderRepository()
    private let seedService = SeedDataService.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Company Name", text: $company)
                    TextField("Contact Person (optional)", text: $name)
                    TextField("Specialty (e.g., Plumber, Electrician)", text: $specialty)
                }

                Section("Contact Information") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
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
                            await saveProvider()
                        }
                    }
                    .disabled(company.isEmpty || isSaving)
                }
            }
            .task {
                loadData()
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

    private func loadData() {
        // Load existing provider data for edit mode
        if case .edit(let provider) = mode {
            company = provider.company
            name = provider.name ?? ""
            specialty = provider.specialty ?? ""
            phone = provider.phone ?? ""
            email = provider.email ?? ""
            notes = provider.notes ?? ""
        }
    }

    private func saveProvider() async {
        isSaving = true

        do {
            let home = try seedService.getOrCreateHome()

            guard let homeId = home.id else {
                errorMessage = "Home does not have a valid ID"
                isSaving = false
                return
            }

            switch mode {
            case .create:
                _ = try providerRepo.create(
                    homeId: homeId,
                    company: company,
                    name: name.isEmpty ? nil : name,
                    phone: phone.isEmpty ? nil : phone,
                    email: email.isEmpty ? nil : email,
                    specialty: specialty.isEmpty ? nil : specialty,
                    notes: notes.isEmpty ? nil : notes
                )

            case .edit(let provider):
                guard let providerId = provider.id else {
                    errorMessage = "Provider does not have a valid ID"
                    isSaving = false
                    return
                }

                _ = try providerRepo.update(
                    providerId,
                    company: company,
                    name: name.isEmpty ? nil : name,
                    phone: phone.isEmpty ? nil : phone,
                    email: email.isEmpty ? nil : email,
                    specialty: specialty.isEmpty ? nil : specialty,
                    notes: notes.isEmpty ? nil : notes
                )
            }

            onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save provider: \(error.localizedDescription)"
            isSaving = false
        }
    }
}

extension ServiceProviderFormView.Mode {
    var title: String {
        switch self {
        case .create: return "New Provider"
        case .edit: return "Edit Provider"
        }
    }
}
