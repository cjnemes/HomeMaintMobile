import XCTest
@testable import HomeMaintMobile
import GRDB

final class HomeRepositoryTests: XCTestCase {

    var repository: HomeRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        repository = HomeRepository()
    }

    override func tearDownWithError() throws {
        // Clean up test data
        try? DatabaseService.shared.resetAllData()

        repository = nil

        try super.tearDownWithError()
    }

    // MARK: - Create Tests

    func testCreate_WithAllFields_ShouldReturnCompleteHome() throws {
        // Given
        let name = "Main House"
        let address = "123 Main St, Springfield, IL 62701"
        let purchaseDate = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021
        let squareFootage = 2500

        // When
        let home = try repository.create(
            name: name,
            address: address,
            purchaseDate: purchaseDate,
            squareFootage: squareFootage
        )

        // Then
        XCTAssertNotNil(home.id)
        XCTAssertEqual(home.name, name)
        XCTAssertEqual(home.address, address)
        XCTAssertEqual(home.purchaseDate, purchaseDate)
        XCTAssertEqual(home.squareFootage, squareFootage)
        XCTAssertNotNil(home.createdAt)
        XCTAssertNotNil(home.updatedAt)
    }

    func testCreate_WithMinimalData_ShouldSucceed() throws {
        // Given
        let name = "Vacation Home"

        // When
        let home = try repository.create(name: name)

        // Then
        XCTAssertNotNil(home.id)
        XCTAssertEqual(home.name, name)
        XCTAssertNil(home.address)
        XCTAssertNil(home.purchaseDate)
        XCTAssertNil(home.squareFootage)
    }

    func testCreate_MultipleHomes_ShouldHaveDifferentIds() throws {
        // Given
        let name1 = "Home 1"
        let name2 = "Home 2"

        // When
        let home1 = try repository.create(name: name1)
        let home2 = try repository.create(name: name2)

        // Then
        XCTAssertNotEqual(home1.id, home2.id)
        XCTAssertEqual(home1.name, name1)
        XCTAssertEqual(home2.name, name2)
    }

    // MARK: - Read Tests

    func testFindById_WithExistingId_ShouldReturnHome() throws {
        // Given
        let created = try repository.create(name: "Test Home", address: "123 Test St")
        let id = created.id!

        // When
        let found = try repository.findById(id)

        // Then
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, id)
        XCTAssertEqual(found?.name, "Test Home")
        XCTAssertEqual(found?.address, "123 Test St")
    }

    func testFindById_WithNonExistentId_ShouldReturnNil() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let found = try repository.findById(nonExistentId)

        // Then
        XCTAssertNil(found)
    }

    func testGetFirst_WithHomes_ShouldReturnFirstHome() throws {
        // Given
        try repository.create(name: "First Home")
        try repository.create(name: "Second Home")
        try repository.create(name: "Third Home")

        // When
        let first = try repository.getFirst()

        // Then
        XCTAssertNotNil(first)
        XCTAssertEqual(first?.name, "First Home")
    }

    func testGetFirst_WithNoHomes_ShouldReturnNil() throws {
        // Given - empty database

        // When
        let first = try repository.getFirst()

        // Then
        XCTAssertNil(first)
    }

    func testFindAll_ShouldReturnAllHomes() throws {
        // Given
        try repository.create(name: "Home 1")
        try repository.create(name: "Home 2")
        try repository.create(name: "Home 3")

        // When
        let homes = try repository.findAll()

        // Then
        XCTAssertEqual(homes.count, 3)
    }

    // MARK: - Update Tests

    func testUpdate_Name_ShouldUpdateHomeName() throws {
        // Given
        let created = try repository.create(
            name: "Original Name",
            address: "123 Main St",
            squareFootage: 2000
        )
        let id = created.id!
        let originalUpdatedAt = created.updatedAt

        // Sleep briefly to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.01)

        // When
        let updated = try repository.update(id, name: "New Name")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "New Name")
        XCTAssertEqual(updated.address, "123 Main St") // Should remain unchanged
        XCTAssertEqual(updated.squareFootage, 2000) // Should remain unchanged
        XCTAssertGreaterThan(updated.updatedAt, originalUpdatedAt)
    }

    func testUpdate_Address_ShouldUpdateHomeAddress() throws {
        // Given
        let created = try repository.create(name: "Test Home", address: "Old Address")
        let id = created.id!

        // When
        let updated = try repository.update(id, address: "New Address")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "Test Home") // Should remain unchanged
        XCTAssertEqual(updated.address, "New Address")
    }

    func testUpdate_PurchaseDate_ShouldUpdatePurchaseDate() throws {
        // Given
        let oldDate = Date(timeIntervalSince1970: 1577836800) // Jan 1, 2020
        let newDate = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021
        let created = try repository.create(name: "Test Home", purchaseDate: oldDate)
        let id = created.id!

        // When
        let updated = try repository.update(id, purchaseDate: newDate)

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.purchaseDate, newDate)
    }

    func testUpdate_SquareFootage_ShouldUpdateSquareFootage() throws {
        // Given
        let created = try repository.create(name: "Test Home", squareFootage: 1500)
        let id = created.id!

        // When
        let updated = try repository.update(id, squareFootage: 2500)

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.squareFootage, 2500)
    }

    func testUpdate_MultipleFields_ShouldUpdateAll() throws {
        // Given
        let created = try repository.create(
            name: "Old Name",
            address: "Old Address",
            squareFootage: 1000
        )
        let id = created.id!
        let newDate = Date()

        // When
        let updated = try repository.update(
            id,
            name: "New Name",
            address: "New Address",
            purchaseDate: newDate,
            squareFootage: 3000
        )

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "New Name")
        XCTAssertEqual(updated.address, "New Address")
        XCTAssertEqual(updated.purchaseDate, newDate)
        XCTAssertEqual(updated.squareFootage, 3000)
    }

    func testUpdate_NonExistentHome_ShouldThrowError() {
        // Given
        let nonExistentId: Int64 = 99999

        // When/Then
        XCTAssertThrowsError(try repository.update(nonExistentId, name: "New Name")) { error in
            XCTAssertTrue(error is RepositoryError)
            if let repoError = error as? RepositoryError {
                XCTAssertEqual(repoError, RepositoryError.notFound)
            }
        }
    }

    // MARK: - Delete Tests

    func testDelete_ExistingHome_ShouldSucceed() throws {
        // Given
        let created = try repository.create(name: "To Delete")
        let id = created.id!

        // When
        let deleted = try repository.delete(id)

        // Then
        XCTAssertTrue(deleted)

        // Verify home is gone
        let found = try repository.findById(id)
        XCTAssertNil(found)
    }

    func testDelete_NonExistentHome_ShouldReturnFalse() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let deleted = try repository.delete(nonExistentId)

        // Then
        XCTAssertFalse(deleted)
    }

    // MARK: - Count Tests

    func testCount_ShouldReturnCorrectNumber() throws {
        // Given
        try repository.create(name: "Home 1")
        try repository.create(name: "Home 2")
        try repository.create(name: "Home 3")
        try repository.create(name: "Home 4")

        // When
        let count = try repository.count()

        // Then
        XCTAssertEqual(count, 4)
    }

    func testCount_EmptyDatabase_ShouldReturnZero() throws {
        // Given - empty database

        // When
        let count = try repository.count()

        // Then
        XCTAssertEqual(count, 0)
    }

    // MARK: - Edge Case Tests

    func testCreate_WithEmptyStringAddress_ShouldTreatAsValue() throws {
        // Given
        let name = "Home"
        let address = ""

        // When
        let home = try repository.create(name: name, address: address)

        // Then
        XCTAssertEqual(home.address, "")
    }

    func testUpdate_UpdatedAtField_ShouldAlwaysUpdate() throws {
        // Given
        let created = try repository.create(name: "Test Home")
        let id = created.id!
        let originalUpdatedAt = created.updatedAt

        // Sleep to ensure different timestamp
        Thread.sleep(forTimeInterval: 0.1)

        // When - Update even without changing fields
        let updated = try repository.update(id)

        // Then
        XCTAssertGreaterThan(updated.updatedAt, originalUpdatedAt)
    }

    func testGetFirst_AfterDeletion_ShouldReturnNextHome() throws {
        // Given
        let home1 = try repository.create(name: "First Home")
        let home2 = try repository.create(name: "Second Home")

        // When
        _ = try repository.delete(home1.id!)
        let first = try repository.getFirst()

        // Then
        XCTAssertNotNil(first)
        XCTAssertEqual(first?.id, home2.id)
        XCTAssertEqual(first?.name, "Second Home")
    }

    func testCreate_LargeSqareFootage_ShouldHandleCorrectly() throws {
        // Given
        let name = "Mansion"
        let squareFootage = 50000

        // When
        let home = try repository.create(name: name, squareFootage: squareFootage)

        // Then
        XCTAssertEqual(home.squareFootage, 50000)
    }
}