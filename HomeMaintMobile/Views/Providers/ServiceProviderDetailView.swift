import SwiftUI

struct ServiceProviderDetailView: View {

    let provider: ServiceProvider

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    private let providerRepo = ServiceProviderRepository()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(provider.company)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        if let name = provider.name, !name.isEmpty {
                            Text(name)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        if let specialty = provider.specialty {
                            if let name = provider.name, !name.isEmpty {
                                Text("•")
                                    .foregroundColor(.secondary)
                            }
                            Text(specialty)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Contact Information
                if hasContactInfo {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Contact Information", systemImage: "info.circle.fill")
                            .font(.headline)

                        if let phone = provider.phone {
                            contactRow(icon: "phone.fill", label: "Phone", value: phone, link: "tel:\(phone)")
                        }

                        if let email = provider.email {
                            contactRow(icon: "envelope.fill", label: "Email", value: email, link: "mailto:\(email)")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Notes
                if let notes = provider.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Notes", systemImage: "note.text")
                            .font(.headline)

                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Delete Button
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Provider", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle("Provider Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ServiceProviderFormView(mode: .edit(provider)) {
                // Refresh handled by parent
            }
        }
        .alert("Delete Provider", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteProvider()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(provider.company)? This action cannot be undone.")
        }
    }

    private var hasContactInfo: Bool {
        provider.phone != nil || provider.email != nil
    }

    @ViewBuilder
    private func contactRow(icon: String, label: String, value: String, link: String) -> some View {
        if let url = URL(string: link) {
            Link(destination: url) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(value)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        } else {
            // Fallback if URL is invalid - show as plain text
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private func deleteProvider() async {
        guard let id = provider.id else { return }

        do {
            try providerRepo.delete(id)
            dismiss()
        } catch {
            print("❌ Error deleting provider: \(error)")
        }
    }
}
