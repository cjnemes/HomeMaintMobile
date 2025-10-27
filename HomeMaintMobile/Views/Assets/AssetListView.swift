import SwiftUI

struct AssetListView: View {

    @StateObject private var viewModel = AssetListViewModel()
    @State private var showingAddAsset = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.assets.isEmpty {
                    ProgressView("Loading assets...")
                } else if viewModel.assets.isEmpty {
                    emptyStateView
                } else {
                    assetList
                }
            }
            .navigationTitle("Assets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddAsset = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Search assets")
            .onChange(of: viewModel.searchQuery) { _, newValue in
                Task {
                    await viewModel.search(newValue)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddAsset) {
                AssetFormView(mode: .create) {
                    Task {
                        await viewModel.loadAssets()
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

    private var assetList: some View {
        List {
            ForEach(viewModel.assets) { asset in
                NavigationLink(destination: AssetDetailView(asset: asset)) {
                    AssetRowView(asset: asset)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let asset = viewModel.assets[index]
                    Task {
                        await viewModel.deleteAsset(asset)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Assets Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first asset to start tracking maintenance")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingAddAsset = true
            } label: {
                Label("Add Asset", systemImage: "plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

struct AssetRowView: View {

    let asset: Asset

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(asset.name)
                .font(.headline)

            if let manufacturer = asset.manufacturer {
                Text(manufacturer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let modelNumber = asset.modelNumber {
                Text("Model: \(modelNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if asset.warrantyStatus != .unknown {
                HStack(spacing: 4) {
                    Circle()
                        .fill(warrantyColor)
                        .frame(width: 8, height: 8)

                    Text("Warranty: \(asset.warrantyStatus.displayText)")
                        .font(.caption)
                        .foregroundColor(warrantyColor)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var warrantyColor: Color {
        switch asset.warrantyStatus {
        case .active: return .green
        case .expiringSoon: return .orange
        case .expired: return .red
        case .unknown: return .gray
        }
    }
}

#Preview {
    AssetListView()
}
