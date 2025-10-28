import XCTest
@testable import HomeMaintMobile
import GRDB

@MainActor
final class ServiceProviderListViewModelTests: XCTestCase {

    var viewModel: ServiceProviderListViewModel!
    var providerRepo: ServiceProviderRepository!
    var homeRepo: HomeRepository!
    var testHomeId: Int64!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        // Initialize repositories
        providerRepo = ServiceProviderRepository()
        homeRepo = HomeRepository()

        // Create test home
        let home = try homeRepo.create(name: "Test Home")
        testHomeId = home.id!
    }

    override func tearDownWithError() throws {
        // Clean up test data
        try? DatabaseService.shared.resetAllData()

        viewModel = nil
        providerRepo = nil
        homeRepo = nil
        testHomeId = nil

        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInit_ShouldLoadProvidersAutomatically() async throws {
        // When
        viewModel = ServiceProviderListViewModel()

        // Wait for async loading to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Load Data Tests

    func testLoadProviders_WithProviders_ShouldLoadAll() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        // Create test providers
        try providerRepo.create(homeId: testHomeId, company: "ABC Plumbing", specialty: "Plumbing")
        try providerRepo.create(homeId: testHomeId, company: "XYZ Electric", specialty: "Electrical")
        try providerRepo.create(homeId: testHomeId, company: "Cool HVAC", specialty: "HVAC")

        // When
        await viewModel.loadProviders()

        // Then
        XCTAssertEqual(viewModel.providers.count, 3)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        // Should be ordered alphabetically by company
        XCTAssertEqual(viewModel.providers[0].company, "ABC Plumbing")
        XCTAssertEqual(viewModel.providers[1].company, "Cool HVAC")
        XCTAssertEqual(viewModel.providers[2].company, "XYZ Electric")
    }

    func testLoadProviders_WithNoProviders_ShouldReturnEmptyList() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()
        // No providers created

        // When
        await viewModel.loadProviders()

        // Then
        XCTAssertTrue(viewModel.providers.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadProviders_WithSearchQuery_ShouldFilterResults() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        // Create test providers
        try providerRepo.create(homeId: testHomeId, company: "ABC Plumbing", specialty: "Plumbing")
        try providerRepo.create(homeId: testHomeId, company: "XYZ Electric", specialty: "Electrical")
        try providerRepo.create(homeId: testHomeId, company: "ABC HVAC", specialty: "HVAC")

        // When
        viewModel.searchQuery = "ABC"
        await viewModel.loadProviders()

        // Then
        XCTAssertEqual(viewModel.providers.count, 2)
        XCTAssertTrue(viewModel.providers.allSatisfy { $0.company.contains("ABC") })
    }

    func testLoadProviders_EmptySearchQuery_ShouldLoadAll() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        try providerRepo.create(homeId: testHomeId, company: "Company 1")
        try providerRepo.create(homeId: testHomeId, company: "Company 2")

        // When
        viewModel.searchQuery = ""
        await viewModel.loadProviders()

        // Then
        XCTAssertEqual(viewModel.providers.count, 2)
    }

    func testLoadProviders_SetsLoadingState() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        // When/Then
        let expectation = XCTestExpectation(description: "Loading state changes")

        Task {
            await viewModel.loadProviders()

            // After completion, loading should be false
            XCTAssertFalse(viewModel.isLoading)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Delete Tests

    func testDeleteProvider_ExistingProvider_ShouldRemoveFromList() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        let provider1 = try providerRepo.create(homeId: testHomeId, company: "To Keep")
        let provider2 = try providerRepo.create(homeId: testHomeId, company: "To Delete")

        await viewModel.loadProviders()
        XCTAssertEqual(viewModel.providers.count, 2)

        // When
        await viewModel.deleteProvider(provider2)

        // Then
        XCTAssertEqual(viewModel.providers.count, 1)
        XCTAssertEqual(viewModel.providers[0].company, "To Keep")
        XCTAssertNil(viewModel.errorMessage)

        // Verify deletion from database
        let found = try providerRepo.findById(provider2.id!)
        XCTAssertNil(found)
    }

    func testDeleteProvider_WithNilId_ShouldDoNothing() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()
        var providerWithoutId = ServiceProvider(
            homeId: testHomeId,
            company: "No ID Provider"
        )
        providerWithoutId.id = nil

        try providerRepo.create(homeId: testHomeId, company: "Existing Provider")
        await viewModel.loadProviders()
        let initialCount = viewModel.providers.count

        // When
        await viewModel.deleteProvider(providerWithoutId)

        // Then - Nothing should change
        XCTAssertEqual(viewModel.providers.count, initialCount)
    }

    func testDeleteProvider_LastProvider_ShouldResultInEmptyList() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        let provider = try providerRepo.create(homeId: testHomeId, company: "Only Provider")
        await viewModel.loadProviders()
        XCTAssertEqual(viewModel.providers.count, 1)

        // When
        await viewModel.deleteProvider(provider)

        // Then
        XCTAssertTrue(viewModel.providers.isEmpty)
    }

    // MARK: - Search Tests

    func testSearch_WithQuery_ShouldUpdateSearchQueryAndReload() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        try providerRepo.create(homeId: testHomeId, company: "ABC Company", specialty: "Plumbing")
        try providerRepo.create(homeId: testHomeId, company: "XYZ Company", specialty: "Electrical")
        try providerRepo.create(homeId: testHomeId, company: "123 Services", specialty: "HVAC")

        // When
        await viewModel.search("Company")

        // Then
        XCTAssertEqual(viewModel.searchQuery, "Company")
        XCTAssertEqual(viewModel.providers.count, 2)
        XCTAssertTrue(viewModel.providers.allSatisfy { $0.company.contains("Company") })
    }

    func testSearch_EmptyQuery_ShouldLoadAllProviders() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        try providerRepo.create(homeId: testHomeId, company: "Company 1")
        try providerRepo.create(homeId: testHomeId, company: "Company 2")

        // When
        await viewModel.search("")

        // Then
        XCTAssertEqual(viewModel.searchQuery, "")
        XCTAssertEqual(viewModel.providers.count, 2)
    }

    func testSearch_NoMatches_ShouldReturnEmptyList() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        try providerRepo.create(homeId: testHomeId, company: "ABC Company")
        try providerRepo.create(homeId: testHomeId, company: "XYZ Company")

        // When
        await viewModel.search("NonExistent")

        // Then
        XCTAssertEqual(viewModel.searchQuery, "NonExistent")
        XCTAssertTrue(viewModel.providers.isEmpty)
    }

    // MARK: - Refresh Tests

    func testRefresh_ShouldReloadProviders() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        try providerRepo.create(homeId: testHomeId, company: "Initial Provider")
        await viewModel.loadProviders()
        XCTAssertEqual(viewModel.providers.count, 1)

        // Add new provider directly to repo
        try providerRepo.create(homeId: testHomeId, company: "New Provider")

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.providers.count, 2)
    }

    // MARK: - Edge Case Tests

    func testLoadProviders_MultipleLoads_ShouldHandleCorrectly() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()
        try providerRepo.create(homeId: testHomeId, company: "Provider 1")

        // When - Load multiple times
        await viewModel.loadProviders()
        await viewModel.loadProviders()
        await viewModel.loadProviders()

        // Then - Should still work correctly
        XCTAssertEqual(viewModel.providers.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadProviders_WithSpecialCharactersInSearch_ShouldHandleCorrectly() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        try providerRepo.create(homeId: testHomeId, company: "Bob's Plumbing")
        try providerRepo.create(homeId: testHomeId, company: "A-1 Electric")
        try providerRepo.create(homeId: testHomeId, company: "24/7 Services")

        // When
        await viewModel.search("Bob's")

        // Then
        XCTAssertEqual(viewModel.providers.count, 1)
        XCTAssertEqual(viewModel.providers[0].company, "Bob's Plumbing")
    }

    func testProviders_MultipleHomes_ShouldOnlyShowCurrentHomeProviders() async throws {
        // Given
        viewModel = ServiceProviderListViewModel()

        // Create another home
        let otherHome = try homeRepo.create(name: "Other Home")
        let otherHomeId = otherHome.id!

        // Create providers for different homes
        try providerRepo.create(homeId: testHomeId, company: "Home 1 Provider")
        try providerRepo.create(homeId: otherHomeId, company: "Other Home Provider")

        // When
        await viewModel.loadProviders()

        // Then - Should only show providers for the first home
        XCTAssertEqual(viewModel.providers.count, 1)
        XCTAssertEqual(viewModel.providers[0].company, "Home 1 Provider")
    }
}