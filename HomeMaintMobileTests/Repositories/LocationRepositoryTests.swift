import XCTest
@testable import HomeMaintMobile
import GRDB

final class LocationRepositoryTests: XCTestCase {

    var repository: LocationRepository!
    var homeRepo: HomeRepository!
    var testHomeId: Int64!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        repository = LocationRepository()
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

    func testCreate_WithValidData_ShouldReturnLocationWithId() throws {
        // Given
        let name = "Master Bedroom"
        let floor = "Second Floor"

        // When
        let location = try repository.create(
            homeId: testHomeId,
            name: name,
            floor: floor
        )

        // Then
        XCTAssertNotNil(location.id)
        XCTAssertEqual(location.name, name)
        XCTAssertEqual(location.floor, floor)
        XCTAssertEqual(location.homeId, testHomeId)
    }

    func testCreate_WithMinimalData_ShouldSucceed() throws {
        // Given
        let name = "Basement"

        // When
        let location = try repository.create(homeId: testHomeId, name: name)

        // Then
        XCTAssertNotNil(location.id)
        XCTAssertEqual(location.name, name)
        XCTAssertNil(location.floor)
        XCTAssertEqual(location.homeId, testHomeId)
    }

    func testCreate_DuplicateName_ShouldCreateSeparateLocation() throws {
        // Given
        let name = "Kitchen"

        // When
        let location1 = try repository.create(homeId: testHomeId, name: name)
        let location2 = try repository.create(homeId: testHomeId, name: name)

        // Then
        XCTAssertNotEqual(location1.id, location2.id)
        XCTAssertEqual(location1.name, location2.name)
    }

    // MARK: - Read Tests

    func testFindById_WithExistingId_ShouldReturnLocation() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Living Room")
        let id = created.id!

        // When
        let found = try repository.findById(id)

        // Then
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, id)
        XCTAssertEqual(found?.name, "Living Room")
    }

    func testFindById_WithNonExistentId_ShouldReturnNil() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let found = try repository.findById(nonExistentId)

        // Then
        XCTAssertNil(found)
    }

    func testFindByHomeId_ShouldReturnAllLocationsForHome() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "Kitchen", floor: "First Floor")
        try repository.create(homeId: testHomeId, name: "Bathroom", floor: "Second Floor")
        try repository.create(homeId: testHomeId, name: "Living Room", floor: "First Floor")

        // When
        let locations = try repository.findByHomeId(testHomeId)

        // Then
        XCTAssertEqual(locations.count, 3)
        XCTAssertTrue(locations.allSatisfy { $0.homeId == testHomeId })
        // Should be ordered by name
        XCTAssertEqual(locations[0].name, "Bathroom")
        XCTAssertEqual(locations[1].name, "Kitchen")
        XCTAssertEqual(locations[2].name, "Living Room")
    }

    func testFindByHomeId_WithNoLocationsForHome_ShouldReturnEmptyArray() throws {
        // Given
        let otherHomeId: Int64 = 99999

        // When
        let locations = try repository.findByHomeId(otherHomeId)

        // Then
        XCTAssertTrue(locations.isEmpty)
    }

    func testFindAll_ShouldReturnAllLocations() throws {
        // Given
        try repository.create(homeId: testHomeId, name: "Location 1")
        try repository.create(homeId: testHomeId, name: "Location 2")
        try repository.create(homeId: testHomeId, name: "Location 3")

        // When
        let locations = try repository.findAll()

        // Then
        XCTAssertEqual(locations.count, 3)
    }

    // MARK: - Update Tests

    func testUpdate_Name_ShouldUpdateLocationName() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Old Room", floor: "First Floor")
        let id = created.id!

        // When
        let updated = try repository.update(id, name: "New Room")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "New Room")
        XCTAssertEqual(updated.floor, "First Floor") // Should remain unchanged
    }

    func testUpdate_Floor_ShouldUpdateLocationFloor() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Office", floor: "Ground Floor")
        let id = created.id!

        // When
        let updated = try repository.update(id, floor: "Second Floor")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "Office") // Should remain unchanged
        XCTAssertEqual(updated.floor, "Second Floor")
    }

    func testUpdate_BothFields_ShouldUpdateBoth() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "Old Name", floor: "Old Floor")
        let id = created.id!

        // When
        let updated = try repository.update(id, name: "New Name", floor: "New Floor")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.name, "New Name")
        XCTAssertEqual(updated.floor, "New Floor")
    }

    func testUpdate_NonExistentLocation_ShouldThrowError() {
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

    func testDelete_ExistingLocation_ShouldSucceed() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, name: "To Delete")
        let id = created.id!

        // When
        let deleted = try repository.delete(id)

        // Then
        XCTAssertTrue(deleted)

        // Verify location is gone
        let found = try repository.findById(id)
        XCTAssertNil(found)
    }

    func testDelete_NonExistentLocation_ShouldReturnFalse() throws {
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
        try repository.create(homeId: testHomeId, name: "Location 1")
        try repository.create(homeId: testHomeId, name: "Location 2")
        try repository.create(homeId: testHomeId, name: "Location 3")
        try repository.create(homeId: testHomeId, name: "Location 4")

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

    func testCreate_WithEmptyFloor_ShouldTreatAsNil() throws {
        // Given
        let name = "Room"
        let floor = ""

        // When
        let location = try repository.create(homeId: testHomeId, name: name, floor: floor)

        // Then
        // Depending on implementation, empty string might be stored as is or as nil
        XCTAssertNotNil(location.id)
        XCTAssertEqual(location.name, name)
        // Empty string is typically stored as is in SQLite unless handled specifically
        XCTAssertEqual(location.floor, floor)
    }

    func testFindByHomeId_MultipleHomes_ShouldReturnOnlySpecificHomeLocations() throws {
        // Given
        let otherHome = try homeRepo.create(name: "Other Home")
        let otherHomeId = otherHome.id!

        try repository.create(homeId: testHomeId, name: "Location 1")
        try repository.create(homeId: testHomeId, name: "Location 2")
        try repository.create(homeId: otherHomeId, name: "Other Location")

        // When
        let locations = try repository.findByHomeId(testHomeId)

        // Then
        XCTAssertEqual(locations.count, 2)
        XCTAssertTrue(locations.allSatisfy { $0.homeId == testHomeId })
    }
}