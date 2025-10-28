import XCTest
@testable import HomeMaintMobile
import GRDB

final class ServiceProviderRepositoryTests: XCTestCase {

    var repository: ServiceProviderRepository!
    var homeRepo: HomeRepository!
    var testHomeId: Int64!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        repository = ServiceProviderRepository()
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

    func testCreate_WithAllFields_ShouldReturnCompleteServiceProvider() throws {
        // Given
        let company = "ABC Plumbing"
        let name = "John Smith"
        let phone = "(555) 123-4567"
        let email = "john@abcplumbing.com"
        let specialty = "Plumbing"
        let notes = "Reliable and affordable"

        // When
        let provider = try repository.create(
            homeId: testHomeId,
            company: company,
            name: name,
            phone: phone,
            email: email,
            specialty: specialty,
            notes: notes
        )

        // Then
        XCTAssertNotNil(provider.id)
        XCTAssertEqual(provider.company, company)
        XCTAssertEqual(provider.name, name)
        XCTAssertEqual(provider.phone, phone)
        XCTAssertEqual(provider.email, email)
        XCTAssertEqual(provider.specialty, specialty)
        XCTAssertEqual(provider.notes, notes)
        XCTAssertEqual(provider.homeId, testHomeId)
    }

    func testCreate_WithMinimalData_ShouldSucceed() throws {
        // Given
        let company = "XYZ Electric"

        // When
        let provider = try repository.create(homeId: testHomeId, company: company)

        // Then
        XCTAssertNotNil(provider.id)
        XCTAssertEqual(provider.company, company)
        XCTAssertNil(provider.name)
        XCTAssertNil(provider.phone)
        XCTAssertNil(provider.email)
        XCTAssertNil(provider.specialty)
        XCTAssertNil(provider.notes)
        XCTAssertEqual(provider.homeId, testHomeId)
    }

    func testCreate_DuplicateCompany_ShouldCreateSeparateProvider() throws {
        // Given
        let company = "Same Company"

        // When
        let provider1 = try repository.create(homeId: testHomeId, company: company)
        let provider2 = try repository.create(homeId: testHomeId, company: company)

        // Then
        XCTAssertNotEqual(provider1.id, provider2.id)
        XCTAssertEqual(provider1.company, provider2.company)
    }

    // MARK: - Read Tests

    func testFindById_WithExistingId_ShouldReturnProvider() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, company: "Test Company")
        let id = created.id!

        // When
        let found = try repository.findById(id)

        // Then
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, id)
        XCTAssertEqual(found?.company, "Test Company")
    }

    func testFindById_WithNonExistentId_ShouldReturnNil() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let found = try repository.findById(nonExistentId)

        // Then
        XCTAssertNil(found)
    }

    func testFindByHomeId_ShouldReturnAllProvidersForHome() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "Alpha Services")
        try repository.create(homeId: testHomeId, company: "Beta Contractors")
        try repository.create(homeId: testHomeId, company: "Charlie's Repairs")

        // When
        let providers = try repository.findByHomeId(testHomeId)

        // Then
        XCTAssertEqual(providers.count, 3)
        XCTAssertTrue(providers.allSatisfy { $0.homeId == testHomeId })
        // Should be ordered by company name
        XCTAssertEqual(providers[0].company, "Alpha Services")
        XCTAssertEqual(providers[1].company, "Beta Contractors")
        XCTAssertEqual(providers[2].company, "Charlie's Repairs")
    }

    func testFindByHomeId_WithNoProvidersForHome_ShouldReturnEmptyArray() throws {
        // Given
        let otherHomeId: Int64 = 99999

        // When
        let providers = try repository.findByHomeId(otherHomeId)

        // Then
        XCTAssertTrue(providers.isEmpty)
    }

    func testFindBySpecialty_ShouldReturnMatchingProviders() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "Plumber 1", specialty: "Plumbing")
        try repository.create(homeId: testHomeId, company: "Electrician 1", specialty: "Electrical")
        try repository.create(homeId: testHomeId, company: "Plumber 2", specialty: "Plumbing")

        // When
        let plumbers = try repository.findBySpecialty("Plumbing")

        // Then
        XCTAssertEqual(plumbers.count, 2)
        XCTAssertTrue(plumbers.allSatisfy { $0.specialty == "Plumbing" })
        // Should be ordered by company
        XCTAssertEqual(plumbers[0].company, "Plumber 1")
        XCTAssertEqual(plumbers[1].company, "Plumber 2")
    }

    func testFindBySpecialty_NoMatches_ShouldReturnEmptyArray() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "HVAC Pro", specialty: "HVAC")

        // When
        let providers = try repository.findBySpecialty("Roofing")

        // Then
        XCTAssertTrue(providers.isEmpty)
    }

    func testFindAll_ShouldReturnAllProviders() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "Provider 1")
        try repository.create(homeId: testHomeId, company: "Provider 2")
        try repository.create(homeId: testHomeId, company: "Provider 3")

        // When
        let providers = try repository.findAll()

        // Then
        XCTAssertEqual(providers.count, 3)
    }

    // MARK: - Update Tests

    func testUpdate_Company_ShouldUpdateCompanyName() throws {
        // Given
        let created = try repository.create(
            homeId: testHomeId,
            company: "Old Company",
            name: "John",
            phone: "555-1234"
        )
        let id = created.id!

        // When
        let updated = try repository.update(id, company: "New Company")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.company, "New Company")
        XCTAssertEqual(updated.name, "John") // Should remain unchanged
        XCTAssertEqual(updated.phone, "555-1234") // Should remain unchanged
    }

    func testUpdate_MultipleFields_ShouldUpdateAllProvided() throws {
        // Given
        let created = try repository.create(
            homeId: testHomeId,
            company: "Original",
            name: "Old Name",
            phone: "Old Phone"
        )
        let id = created.id!

        // When
        let updated = try repository.update(
            id,
            company: "Updated Company",
            name: "New Name",
            phone: "New Phone",
            email: "new@email.com"
        )

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.company, "Updated Company")
        XCTAssertEqual(updated.name, "New Name")
        XCTAssertEqual(updated.phone, "New Phone")
        XCTAssertEqual(updated.email, "new@email.com")
    }

    func testUpdate_NonExistentProvider_ShouldThrowError() {
        // Given
        let nonExistentId: Int64 = 99999

        // When/Then
        XCTAssertThrowsError(try repository.update(nonExistentId, company: "New Company")) { error in
            XCTAssertTrue(error is RepositoryError)
            if let repoError = error as? RepositoryError {
                XCTAssertEqual(repoError, RepositoryError.notFound)
            }
        }
    }

    // MARK: - Delete Tests

    func testDelete_ExistingProvider_ShouldSucceed() throws {
        // Given
        let created = try repository.create(homeId: testHomeId, company: "To Delete")
        let id = created.id!

        // When
        let deleted = try repository.delete(id)

        // Then
        XCTAssertTrue(deleted)

        // Verify provider is gone
        let found = try repository.findById(id)
        XCTAssertNil(found)
    }

    func testDelete_NonExistentProvider_ShouldReturnFalse() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let deleted = try repository.delete(nonExistentId)

        // Then
        XCTAssertFalse(deleted)
    }

    // MARK: - Search Tests

    func testSearch_ByCompanyName_ShouldReturnMatches() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "ABC Plumbing")
        try repository.create(homeId: testHomeId, company: "XYZ Electric")
        try repository.create(homeId: testHomeId, company: "ABC HVAC")

        // When
        let results = try repository.search(homeId: testHomeId, query: "ABC")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.company.contains("ABC") })
    }

    func testSearch_ByContactName_ShouldReturnMatches() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "Company 1", name: "John Smith")
        try repository.create(homeId: testHomeId, company: "Company 2", name: "Jane Doe")
        try repository.create(homeId: testHomeId, company: "Company 3", name: "John Doe")

        // When
        let results = try repository.search(homeId: testHomeId, query: "John")

        // Then
        XCTAssertEqual(results.count, 2)
    }

    func testSearch_BySpecialty_ShouldReturnMatches() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "Company 1", specialty: "Plumbing")
        try repository.create(homeId: testHomeId, company: "Company 2", specialty: "Electrical")
        try repository.create(homeId: testHomeId, company: "Company 3", specialty: "Plumbing & HVAC")

        // When
        let results = try repository.search(homeId: testHomeId, query: "Plumb")

        // Then
        XCTAssertEqual(results.count, 2)
    }

    func testSearch_CaseInsensitive_ShouldFindMatches() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "ABC Company")

        // When
        let results1 = try repository.search(homeId: testHomeId, query: "abc")
        let results2 = try repository.search(homeId: testHomeId, query: "ABC")

        // Then
        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results2.count, 1)
    }

    func testSearch_NoMatches_ShouldReturnEmptyArray() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "Test Company")

        // When
        let results = try repository.search(homeId: testHomeId, query: "NonExistent")

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    func testSearch_MultipleHomes_ShouldOnlyReturnForSpecifiedHome() throws {
        // Given
        let otherHome = try homeRepo.create(name: "Other Home")
        let otherHomeId = otherHome.id!

        try repository.create(homeId: testHomeId, company: "ABC Company")
        try repository.create(homeId: otherHomeId, company: "ABC Company")

        // When
        let results = try repository.search(homeId: testHomeId, query: "ABC")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.homeId, testHomeId)
    }

    // MARK: - Count Tests

    func testCount_ShouldReturnCorrectNumber() throws {
        // Given
        try repository.create(homeId: testHomeId, company: "Provider 1")
        try repository.create(homeId: testHomeId, company: "Provider 2")
        try repository.create(homeId: testHomeId, company: "Provider 3")

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