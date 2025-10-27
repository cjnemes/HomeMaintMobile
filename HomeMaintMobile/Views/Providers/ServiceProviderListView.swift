import SwiftUI

struct ServiceProviderListView: View {

    @StateObject private var viewModel = ServiceProviderListViewModel()
    @State private var showingAddProvider = false
    @State private var selectedProvider: ServiceProvider?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.providers.isEmpty {
                    ProgressView("Loading providers...")
                } else if viewModel.providers.isEmpty {
                    emptyState
                } else {
                    providerList
                }
            }
            .navigationTitle("Service Providers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProvider = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Search providers")
            .onChange(of: viewModel.searchQuery) { _, newValue in
                Task {
                    await viewModel.search(newValue)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddProvider) {
                ServiceProviderFormView(mode: .create) {
                    Task {
                        await viewModel.loadProviders()
                    }
                }
            }
            .sheet(item: $selectedProvider) { provider in
                ServiceProviderFormView(mode: .edit(provider)) {
                    Task {
                        await viewModel.loadProviders()
                    }
                }
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
        }
    }

    private var providerList: some View {
        List {
            ForEach(viewModel.providers) { provider in
                NavigationLink {
                    ServiceProviderDetailView(provider: provider)
                } label: {
                    providerRow(provider)
                }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await viewModel.deleteProvider(viewModel.providers[index])
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func providerRow(_ provider: ServiceProvider) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(provider.company)
                .font(.headline)

            HStack(spacing: 8) {
                if let name = provider.name, !name.isEmpty {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let specialty = provider.specialty {
                    if let name = provider.name, !name.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                    }
                    Text(specialty)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let phone = provider.phone {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                    Text(phone)
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No Service Providers")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your trusted contractors, plumbers, electricians, and other service providers")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingAddProvider = true
            } label: {
                Label("Add Provider", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
