import XCTest
@testable import HomeMaintMobile
import GRDB

final class CategoryRepositoryTests: XCTestCase {

    var repository: CategoryRepository!
    var homeRepo: HomeRepository!
    var testHomeId: Int64!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        repository = CategoryRepository()
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

    func testCreate_WithValidData_ShouldReturnCategoryWithId() throws {
        // Given
        let name = "HVAC"
        let icon = "air.conditioner"

        // When
        let category = try repository.create(
            homeId: testHomeId,
            name: name,
            icon: icon
        )

        // Then
        XCTAssertNotNil(category.id)
        XCTAssertEqual(category.name, name)
        XCTAssertEqual(category.icon, icon)
        XCTAssertEqual(category.homeId, testHomeId)
    }

    func testCreate_WithMinimalData_ShouldSucceed() throws {
        // Given
        let name = "Plumbing"

        // When
        let category = try repository.create(homeId: testHomeId, name: name)

        // Then
        XCTAssertNotNil(category.id)
        XCTAssertEqual(category.name, name)
        XCTAssertNil(category.icon)
        XCTAssertEqual(category.homeId, testHomeId)
    }

    func testCreate_DuplicateName_ShouldCreateSeparateCategory() throws {
        // Given
        let name = "Electrical"

        // When
        let category1 = try repository.create(homeId: testHomeId, name: name)
        let category2 = try repository.create(homeId: testHomeId, name: name)

        // Then
        XCTAssertNotEqual(category1.id, category2.id)
        XCTAssertEqual(category1.name, category2.name)
    }

    // MARK: - Read Tests

    func testFindById_WithExistingId_ShouldReturnCategory() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Test Category")
        let id = created.id!

        // When
        let found = try repository.findById(id)

        // Then
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, id)
        XCTAssertEqual(found?.name, "Test Category")
    }

    func testFindById_WithNonExistentId_ShouldReturnNil() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let found = try repository.findById(nonExistentId)

        // Then
        XCTAssertNil(found)
    }

    func testFindByHomeId_ShouldReturnAllCategoriesForHome() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "HVAC")
        try repository.create(homeId: testHomeId, name: "Plumbing")
        try repository.create(homeId: testHomeId, name: "Electrical")

        // When
        let categories = try repository.findByHomeId(testHomeId)

        // Then
        XCTAssertEqual(categories.count, 3)
        XCTAssertTrue(categories.allSatisfy { $0.homeId == testHomeId })
        // Should be ordered by name
        XCTAssertEqual(categories[0].name, "Electrical")
        XCTAssertEqual(categories[1].name, "HVAC")
        XCTAssertEqual(categories[2].name, "Plumbing")
    }

    func testFindByHomeId_WithNoCategoriesForHome_ShouldReturnEmptyArray() throws {
        // Given
        let otherHomeId: Int64 = 99999

        // When
        let categories = try repository.findByHomeId(otherHomeId)

        // Then
        XCTAssertTrue(categories.isEmpty)
    }

    func testFindAll_ShouldReturnAllCategories() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "Category 1")
        try repository.create(homeId: testHomeId, name: "Category 2")

        // When
        let categories = try repository.findAll()

        // Then
        XCTAssertEqual(categories.count, 2)
    }

    // MARK: - Update Tests

    func testUpdate_Name_ShouldUpdateCategoryName() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Old Name", icon: "old.icon")
        let id = created.id!

        // When
        let updated = try repository.update(id, name: "New Name")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "New Name")
        XCTAssertEqual(updated.icon, "old.icon") // Should remain unchanged
    }

    func testUpdate_Icon_ShouldUpdateCategoryIcon() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Test Category", icon: "old.icon")
        let id = created.id!

        // When
        let updated = try repository.update(id, icon: "new.icon")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "Test Category") // Should remain unchanged
        XCTAssertEqual(updated.icon, "new.icon")
    }

    func testUpdate_BothFields_ShouldUpdateBoth() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Old Name", icon: "old.icon")
        let id = created.id!

        // When
        let updated = try repository.update(id, name: "New Name", icon: "new.icon")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "New Name")
        XCTAssertEqual(updated.icon, "new.icon")
    }

    func testUpdate_NonExistentCategory_ShouldThrowError() {
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

    func testDelete_ExistingCategory_ShouldSucceed() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "To Delete")
        let id = created.id!

        // When
        let deleted = try repository.delete(id)

        // Then
        XCTAssertTrue(deleted)

        // Verify category is gone
        let found = try repository.findById(id)
        XCTAssertNil(found)
    }

    func testDelete_NonExistentCategory_ShouldReturnFalse() throws {
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
        try repository.create(homeId: testHomeId, name: "Category 1")
        try repository.create(homeId: testHomeId, name: "Category 2")
        try repository.create(homeId: testHomeId, name: "Category 3")

        // When
        let count = try repository.count()

        // Then
        XCTAssertEqual(count, 3)
    }

    func testCount_EmptyDatabase_ShouldReturnZero() throws {
        // Given - empty database

        // When
        let count = try repository.count()

        // Then
        XCTAssertEqual(count, 0)
    }
}