import XCTest
@testable import HomeMaintMobile

@MainActor
final class AssetListViewModelTests: XCTestCase {

    var viewModel: AssetListViewModel!
    var assetRepo: AssetRepository!
    var homeRepo: HomeRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        // Create test home
        homeRepo = HomeRepository()
        let home = try homeRepo.create(name: "Test Home")

        assetRepo = AssetRepository()

        // Create test assets
        try assetRepo.create(homeId: home.id!, name: "Asset 1")
        try assetRepo.create(homeId: home.id!, name: "Asset 2")
        try assetRepo.create(homeId: home.id!, name: "Asset 3")

        viewModel = AssetListViewModel()
    }

    override func tearDownWithError() throws {
        try? DatabaseService.shared.resetAllData()

        viewModel = nil
        assetRepo = nil
        homeRepo = nil

        try super.tearDownWithError()
    }

    // MARK: - Load Tests

    func testLoadAssets_ShouldPopulateAssetsList() async throws {
        // When
        await viewModel.loadAssets()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.assets.count, 3)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadAssets_AfterLoad_IsLoadingShouldBeFalse() async throws {
        // When
        await viewModel.loadAssets()

        // Then
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Delete Tests

    func testDeleteAsset_ShouldRemoveFromList() async throws {
        // Given
        await viewModel.loadAssets()
        let initialCount = viewModel.assets.count
        let assetToDelete = viewModel.assets.first!

        // When
        await viewModel.deleteAsset(assetToDelete)

        // Then
        XCTAssertEqual(viewModel.assets.count, initialCount - 1)
        XCTAssertFalse(viewModel.assets.contains { $0.id == assetToDelete.id })
    }

    // MARK: - Search Tests

    func testSearch_WithQuery_ShouldFilterResults() async throws {
        // Given
        await viewModel.loadAssets()
        XCTAssertEqual(viewModel.assets.count, 3)

        // When
        await viewModel.search("Asset 1")

        // Then
        XCTAssertEqual(viewModel.assets.count, 1)
        XCTAssertEqual(viewModel.assets.first?.name, "Asset 1")
    }

    func testSearch_WithEmptyQuery_ShouldShowAllAssets() async throws {
        // Given
        await viewModel.search("Asset 1")
        XCTAssertEqual(viewModel.assets.count, 1)

        // When
        await viewModel.search("")

        // Then
        XCTAssertEqual(viewModel.assets.count, 3)
    }

    // MARK: - Refresh Tests

    func testRefresh_ShouldReloadData() async throws {
        // Given
        await viewModel.loadAssets()
        let initialCount = viewModel.assets.count

        // Add new asset
        let home = try homeRepo.getFirst()!
        try assetRepo.create(homeId: home.id!, name: "New Asset")

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.assets.count, initialCount + 1)
    }
}
