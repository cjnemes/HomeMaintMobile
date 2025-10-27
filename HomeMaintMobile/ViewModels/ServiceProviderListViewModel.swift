import Foundation
import Combine

@MainActor
class ServiceProviderListViewModel: ObservableObject {

    @Published var providers: [ServiceProvider] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""

    private let providerRepo = ServiceProviderRepository()
    private let homeRepo = HomeRepository()
    private let seedService = SeedDataService.shared

    private var currentHomeId: Int64?

    // MARK: - Initialization

    init() {
        Task {
            await loadProviders()
        }
    }

    // MARK: - Load Data

    func loadProviders() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get or create home
            let home = try seedService.getOrCreateHome()
            currentHomeId = home.id

            // Load providers
            if searchQuery.isEmpty {
                providers = try providerRepo.findByHomeId(home.id!)
            } else {
                providers = try providerRepo.search(homeId: home.id!, query: searchQuery)
            }

            print("✅ Loaded \(providers.count) providers")
        } catch {
            errorMessage = "Failed to load providers: \(error.localizedDescription)"
            print("❌ Error loading providers: \(error)")
        }

        isLoading = false
    }

    // MARK: - Actions

    func deleteProvider(_ provider: ServiceProvider) async {
        guard let id = provider.id else { return }

        do {
            try providerRepo.delete(id)
            await loadProviders() // Reload list
            print("✅ Provider deleted: \(provider.company)")
        } catch {
            errorMessage = "Failed to delete provider: \(error.localizedDescription)"
            print("❌ Error deleting provider: \(error)")
        }
    }

    func search(_ query: String) async {
        searchQuery = query
        await loadProviders()
    }

    func refresh() async {
        await loadProviders()
    }
}
