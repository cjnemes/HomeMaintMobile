import Foundation
import Combine

@MainActor
class AssetListViewModel: ObservableObject {

    @Published var assets: [Asset] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""

    private let assetRepo = AssetRepository()
    private let homeRepo = HomeRepository()
    private let seedService = SeedDataService.shared

    private var currentHomeId: Int64?

    // MARK: - Initialization

    init() {
        Task {
            await loadAssets()
        }
    }

    // MARK: - Load Data

    func loadAssets() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get or create home
            let home = try seedService.getOrCreateHome()
            currentHomeId = home.id

            // Load assets
            if searchQuery.isEmpty {
                assets = try assetRepo.findByHomeId(home.id!)
            } else {
                assets = try assetRepo.search(homeId: home.id!, query: searchQuery)
            }

            print("✅ Loaded \(assets.count) assets")
        } catch {
            errorMessage = "Failed to load assets: \(error.localizedDescription)"
            print("❌ Error loading assets: \(error)")
        }

        isLoading = false
    }

    // MARK: - Actions

    func deleteAsset(_ asset: Asset) async {
        guard let id = asset.id else { return }

        do {
            try assetRepo.delete(id)
            await loadAssets() // Reload list
            print("✅ Asset deleted: \(asset.name)")
        } catch {
            errorMessage = "Failed to delete asset: \(error.localizedDescription)"
            print("❌ Error deleting asset: \(error)")
        }
    }

    func search(_ query: String) async {
        searchQuery = query
        await loadAssets()
    }

    func refresh() async {
        await loadAssets()
    }
}
