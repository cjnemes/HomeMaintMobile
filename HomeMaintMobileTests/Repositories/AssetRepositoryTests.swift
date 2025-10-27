import XCTest
@testable import HomeMaintMobile
import GRDB

final class AssetRepositoryTests: XCTestCase {

    var repository: AssetRepository!
    var homeRepo: HomeRepository!
    var testHomeId: Int64!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        repository = AssetRepository()
        homeRepo = HomeRepository()

        // Create test home
        let home = try homeRepo.create(name: "Test Home")
        testHomeId = home.id!
    }

    override func tearDownWithError() throws {
        // Clean up test data
        try? DatabaseService.shared.resetAllData()

        repository = nil
        homeRepo = nil
        testHomeId = nil

        try super.tearDownWithError()
    }

    // MARK: - Create Tests

    func testCreate_WithValidData_ShouldReturnAssetWithId() throws {
        // Given
        let name = "Test Asset"
        let manufacturer = "Test Manufacturer"

        // When
        let asset = try repository.create(
            homeId: testHomeId,
            name: name,
            manufacturer: manufacturer
        )

        // Then
        XCTAssertNotNil(asset.id)
        XCTAssertEqual(asset.name, name)
        XCTAssertEqual(asset.manufacturer, manufacturer)
        XCTAssertEqual(asset.homeId, testHomeId)
    }

    func testCreate_WithMinimalData_ShouldSucceed() throws {
        // Given
        let name = "Minimal Asset"

        // When
        let asset = try repository.create(homeId: testHomeId, name: name)

        // Then
        XCTAssertNotNil(asset.id)
        XCTAssertEqual(asset.name, name)
        XCTAssertNil(asset.manufacturer)
        XCTAssertNil(asset.modelNumber)
    }

    // MARK: - Read Tests

    func testFindById_WithExistingId_ShouldReturnAsset() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Test Asset")
        let id = created.id!

        // When
        let found = try repository.findById(id)

        // Then
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, id)
        XCTAssertEqual(found?.name, "Test Asset")
    }

    func testFindById_WithNonExistentId_ShouldReturnNil() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let found = try repository.findById(nonExistentId)

        // Then
        XCTAssertNil(found)
    }

    func testFindByHomeId_ShouldReturnAllAssetsForHome() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "Asset 1")
        try repository.create(homeId: testHomeId, name: "Asset 2")
        try repository.create(homeId: testHomeId, name: "Asset 3")

        // When
        let assets = try repository.findByHomeId(testHomeId)

        // Then
        XCTAssertEqual(assets.count, 3)
        XCTAssertTrue(assets.allSatisfy { $0.homeId == testHomeId })
    }

    func testFindAll_ShouldReturnAllAssets() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "Asset 1")
        try repository.create(homeId: testHomeId, name: "Asset 2")

        // When
        let assets = try repository.findAll()

        // Then
        XCTAssertEqual(assets.count, 2)
    }

    // MARK: - Update Tests

    func testUpdate_WithValidData_ShouldUpdateAsset() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Original Name")
        let id = created.id!

        // When
        let updated = try repository.update(id, name: "Updated Name")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "Updated Name")
        XCTAssertNotEqual(updated.updatedAt, created.updatedAt)
    }

    func testUpdate_NonExistentAsset_ShouldThrowError() {
        // Given
        let nonExistentId: Int64 = 99999

        // When/Then
        XCTAssertThrowsError(try repository.update(nonExistentId, name: "New Name")) { error in
            XCTAssertTrue(error is RepositoryError)
        }
    }

    // MARK: - Delete Tests

    func testDelete_ExistingAsset_ShouldSucceed() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "To Delete")
        let id = created.id!

        // When
        let deleted = try repository.delete(id)

        // Then
        XCTAssertTrue(deleted)

        // Verify asset is gone
        let found = try repository.findById(id)
        XCTAssertNil(found)
    }

    func testDelete_NonExistentAsset_ShouldReturnFalse() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let deleted = try repository.delete(nonExistentId)

        // Then
        XCTAssertFalse(deleted)
    }

    // MARK: - Search Tests

    func testSearch_ByName_ShouldReturnMatchingAssets() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "HVAC Unit")
        try repository.create(homeId: testHomeId, name: "Water Heater")
        try repository.create(homeId: testHomeId, name: "HVAC Filter")

        // When
        let results = try repository.search(homeId: testHomeId, query: "HVAC")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.name.contains("HVAC") })
    }

    func testSearch_ByManufacturer_ShouldReturnMatchingAssets() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "Asset 1", manufacturer: "Carrier")
        try repository.create(homeId: testHomeId, name: "Asset 2", manufacturer: "Trane")
        try repository.create(homeId: testHomeId, name: "Asset 3", manufacturer: "Carrier")

        // When
        let results = try repository.search(homeId: testHomeId, query: "Carrier")

        // Then
        XCTAssertEqual(results.count, 2)
    }

    func testSearch_NoMatches_ShouldReturnEmptyArray() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "Asset 1")

        // When
        let results = try repository.search(homeId: testHomeId, query: "NonExistent")

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Warranty Tests

    func testFindExpiringWarranties_ShouldReturnAssetsWithUpcomingExpiration() throws {
        // Given
        let futureDate = Date().addingTimeInterval(15 * 24 * 60 * 60) // 15 days
        let farFutureDate = Date().addingTimeInterval(60 * 24 * 60 * 60) // 60 days

        try repository.create(
            homeId: testHomeId,
            name: "Expiring Soon",
            warrantyExpiration: futureDate
        )
        try repository.create(
            homeId: testHomeId,
            name: "Expiring Later",
            warrantyExpiration: farFutureDate
        )

        // When
        let expiring = try repository.findExpiringWarranties(homeId: testHomeId, withinDays: 30)

        // Then
        XCTAssertEqual(expiring.count, 1)
        XCTAssertEqual(expiring.first?.name, "Expiring Soon")
    }

    // MARK: - Count Tests

    func testCount_ShouldReturnCorrectNumber() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "Asset 1")
        try repository.create(homeId: testHomeId, name: "Asset 2")
        try repository.create(homeId: testHomeId, name: "Asset 3")

        // When
        let count = try repository.count()

        // Then
        XCTAssertEqual(count, 3)
    }
}
