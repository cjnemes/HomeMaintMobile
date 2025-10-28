import XCTest
@testable import HomeMaintMobile
import GRDB

final class AttachmentRepositoryTests: XCTestCase {

    var repository: AttachmentRepository!
    var assetRepo: AssetRepository!
    var homeRepo: HomeRepository!
    var maintenanceRepo: MaintenanceRecordRepository!
    var testHomeId: Int64!
    var testAssetId: Int64!
    var testRecordId: Int64!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize in-memory database for testing
        try DatabaseService.shared.initialize(inMemory: true)

        repository = AttachmentRepository()
        assetRepo = AssetRepository()
        homeRepo = HomeRepository()
        maintenanceRepo = MaintenanceRecordRepository()

        // Create test home
        let home = try homeRepo.create(name: "Test Home")
        testHomeId = home.id!

        // Create test asset
        let asset = try assetRepo.create(homeId: testHomeId, name: "Test Asset")
        testAssetId = asset.id!

        // Create test maintenance record
        let record = try maintenanceRepo.create(
            assetId: testAssetId,
            type: "Repair",
            description: "Test repair"
        )
        testRecordId = record.id!
    }

    override func tearDownWithError() throws {
        // Clean up test data
        try? DatabaseService.shared.resetAllData()

        repository = nil
        assetRepo = nil
        homeRepo = nil
        maintenanceRepo = nil
        testHomeId = nil
        testAssetId = nil
        testRecordId = nil

        try super.tearDownWithError()
    }

    // MARK: - Create Tests

    func testCreate_WithAssetId_ShouldReturnAttachmentWithId() throws {
        // Given
        let type = "photo"
        let filename = "asset_photo.jpg"
        let relativePath = "attachments/2025/01/asset_photo_hash.jpg"
        let fileSize = 1024000
        let mimeType = "image/jpeg"

        // When
        let attachment = try repository.create(
            assetId: testAssetId,
            type: type,
            filename: filename,
            relativePath: relativePath,
            fileSize: fileSize,
            mimeType: mimeType
        )

        // Then
        XCTAssertNotNil(attachment.id)
        XCTAssertEqual(attachment.assetId, testAssetId)
        XCTAssertNil(attachment.maintenanceRecordId)
        XCTAssertEqual(attachment.type, type)
        XCTAssertEqual(attachment.filename, filename)
        XCTAssertEqual(attachment.relativePath, relativePath)
        XCTAssertEqual(attachment.fileSize, fileSize)
        XCTAssertEqual(attachment.mimeType, mimeType)
    }

    func testCreate_WithMaintenanceRecordId_ShouldReturnAttachment() throws {
        // Given
        let type = "invoice"
        let filename = "invoice_12345.pdf"
        let relativePath = "attachments/2025/01/invoice_hash.pdf"

        // When
        let attachment = try repository.create(
            maintenanceRecordId: testRecordId,
            type: type,
            filename: filename,
            relativePath: relativePath
        )

        // Then
        XCTAssertNotNil(attachment.id)
        XCTAssertNil(attachment.assetId)
        XCTAssertEqual(attachment.maintenanceRecordId, testRecordId)
        XCTAssertEqual(attachment.type, type)
        XCTAssertEqual(attachment.filename, filename)
        XCTAssertEqual(attachment.relativePath, relativePath)
        XCTAssertNil(attachment.fileSize)
        XCTAssertNil(attachment.mimeType)
    }

    func testCreate_WithMinimalData_ShouldSucceed() throws {
        // Given
        let type = "document"
        let filename = "manual.pdf"
        let relativePath = "attachments/manual.pdf"

        // When
        let attachment = try repository.create(
            type: type,
            filename: filename,
            relativePath: relativePath
        )

        // Then
        XCTAssertNotNil(attachment.id)
        XCTAssertNil(attachment.assetId)
        XCTAssertNil(attachment.maintenanceRecordId)
        XCTAssertEqual(attachment.type, type)
        XCTAssertEqual(attachment.filename, filename)
        XCTAssertEqual(attachment.relativePath, relativePath)
    }

    // MARK: - Read Tests

    func testFindById_WithExistingId_ShouldReturnAttachment() throws {
        // Given
        let created = try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "test.jpg",
            relativePath: "test/path.jpg"
        )
        let id = created.id!

        // When
        let found = try repository.findById(id)

        // Then
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, id)
        XCTAssertEqual(found?.filename, "test.jpg")
    }

    func testFindById_WithNonExistentId_ShouldReturnNil() throws {
        // Given
        let nonExistentId: Int64 = 99999

        // When
        let found = try repository.findById(nonExistentId)

        // Then
        XCTAssertNil(found)
    }

    func testFindByAssetId_ShouldReturnAllAttachmentsForAsset() throws {
        // Given
        let now = Date()
        try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "photo1.jpg",
            relativePath: "path1.jpg"
        )
        Thread.sleep(forTimeInterval: 0.01) // Ensure different timestamps
        try repository.create(
            assetId: testAssetId,
            type: "document",
            filename: "manual.pdf",
            relativePath: "path2.pdf"
        )
        Thread.sleep(forTimeInterval: 0.01)
        try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "photo2.jpg",
            relativePath: "path3.jpg"
        )

        // When
        let attachments = try repository.findByAssetId(testAssetId)

        // Then
        XCTAssertEqual(attachments.count, 3)
        XCTAssertTrue(attachments.allSatisfy { $0.assetId == testAssetId })
        // Should be ordered by createdAt descending (newest first)
        XCTAssertEqual(attachments[0].filename, "photo2.jpg")
        XCTAssertEqual(attachments[1].filename, "manual.pdf")
        XCTAssertEqual(attachments[2].filename, "photo1.jpg")
    }

    func testFindByAssetId_NoAttachments_ShouldReturnEmptyArray() throws {
        // Given
        let otherAssetId: Int64 = 99999

        // When
        let attachments = try repository.findByAssetId(otherAssetId)

        // Then
        XCTAssertTrue(attachments.isEmpty)
    }

    func testFindByMaintenanceRecordId_ShouldReturnAllAttachmentsForRecord() throws {
        // Given
        try repository.create(
            maintenanceRecordId: testRecordId,
            type: "invoice",
            filename: "invoice1.pdf",
            relativePath: "path1.pdf"
        )
        Thread.sleep(forTimeInterval: 0.01)
        try repository.create(
            maintenanceRecordId: testRecordId,
            type: "photo",
            filename: "before.jpg",
            relativePath: "path2.jpg"
        )
        Thread.sleep(forTimeInterval: 0.01)
        try repository.create(
            maintenanceRecordId: testRecordId,
            type: "photo",
            filename: "after.jpg",
            relativePath: "path3.jpg"
        )

        // When
        let attachments = try repository.findByMaintenanceRecordId(testRecordId)

        // Then
        XCTAssertEqual(attachments.count, 3)
        XCTAssertTrue(attachments.allSatisfy { $0.maintenanceRecordId == testRecordId })
        // Should be ordered by createdAt descending (newest first)
        XCTAssertEqual(attachments[0].filename, "after.jpg")
        XCTAssertEqual(attachments[1].filename, "before.jpg")
        XCTAssertEqual(attachments[2].filename, "invoice1.pdf")
    }

    func testFindByType_ShouldReturnMatchingAttachments() throws {
        // Given
        try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "photo1.jpg",
            relativePath: "path1.jpg"
        )
        try repository.create(
            assetId: testAssetId,
            type: "document",
            filename: "manual.pdf",
            relativePath: "path2.pdf"
        )
        try repository.create(
            maintenanceRecordId: testRecordId,
            type: "photo",
            filename: "photo2.jpg",
            relativePath: "path3.jpg"
        )

        // When
        let photos = try repository.findByType("photo")

        // Then
        XCTAssertEqual(photos.count, 2)
        XCTAssertTrue(photos.allSatisfy { $0.type == "photo" })
    }

    func testFindByType_NoMatches_ShouldReturnEmptyArray() throws {
        // Given
        try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "test.jpg",
            relativePath: "test.jpg"
        )

        // When
        let videos = try repository.findByType("video")

        // Then
        XCTAssertTrue(videos.isEmpty)
    }

    func testFindAll_ShouldReturnAllAttachments() throws {
        // Given
        try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "photo1.jpg",
            relativePath: "path1.jpg"
        )
        try repository.create(
            maintenanceRecordId: testRecordId,
            type: "invoice",
            filename: "invoice.pdf",
            relativePath: "path2.pdf"
        )

        // When
        let attachments = try repository.findAll()

        // Then
        XCTAssertEqual(attachments.count, 2)
    }

    // MARK: - Update Tests

    func testUpdate_Type_ShouldUpdateAttachmentType() throws {
        // Given
        let created = try repository.create(
            assetId: testAssetId,
            type: "document",
            filename: "test.pdf",
            relativePath: "test.pdf"
        )
        let id = created.id!

        // When
        let updated = try repository.update(id, type: "manual")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.type, "manual")
        XCTAssertEqual(updated.filename, "test.pdf") // Should remain unchanged
    }

    func testUpdate_Filename_ShouldUpdateAttachmentFilename() throws {
        // Given
        let created = try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "old_name.jpg",
            relativePath: "path.jpg"
        )
        let id = created.id!

        // When
        let updated = try repository.update(id, filename: "new_name.jpg")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.filename, "new_name.jpg")
        XCTAssertEqual(updated.type, "photo") // Should remain unchanged
        XCTAssertEqual(updated.relativePath, "path.jpg") // Should remain unchanged
    }

    func testUpdate_BothFields_ShouldUpdateBoth() throws {
        // Given
        let created = try repository.create(
            assetId: testAssetId,
            type: "document",
            filename: "old.pdf",
            relativePath: "path.pdf"
        )
        let id = created.id!

        // When
        let updated = try repository.update(id, type: "manual", filename: "new.pdf")

        // Then
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.type, "manual")
        XCTAssertEqual(updated.filename, "new.pdf")
    }

    func testUpdate_NonExistentAttachment_ShouldThrowError() {
        // Given
        let nonExistentId: Int64 = 99999

        // When/Then
        XCTAssertThrowsError(try repository.update(nonExistentId, type: "new_type")) { error in
            XCTAssertTrue(error is RepositoryError)
            if let repoError = error as? RepositoryError {
                XCTAssertEqual(repoError, RepositoryError.notFound)
            }
        }
    }

    // MARK: - Delete Tests

    func testDelete_ExistingAttachment_ShouldSucceed() throws {
        // Given
        let created = try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "to_delete.jpg",
            relativePath: "path.jpg"
        )
        let id = created.id!

        // When
        let deleted = try repository.delete(id)

        // Then
        XCTAssertTrue(deleted)

        // Verify attachment is gone
        let found = try repository.findById(id)
        XCTAssertNil(found)
    }

    func testDelete_NonExistentAttachment_ShouldReturnFalse() throws {
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
        try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "photo1.jpg",
            relativePath: "path1.jpg"
        )
        try repository.create(
            maintenanceRecordId: testRecordId,
            type: "invoice",
            filename: "invoice.pdf",
            relativePath: "path2.pdf"
        )
        try repository.create(
            type: "document",
            filename: "manual.pdf",
            relativePath: "path3.pdf"
        )

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

    // MARK: - Edge Case Tests

    func testCreate_BothAssetAndMaintenanceIds_ShouldSucceed() throws {
        // Given - attachment can belong to both asset and maintenance record
        let type = "photo"
        let filename = "shared.jpg"
        let relativePath = "shared.jpg"

        // When
        let attachment = try repository.create(
            assetId: testAssetId,
            maintenanceRecordId: testRecordId,
            type: type,
            filename: filename,
            relativePath: relativePath
        )

        // Then
        XCTAssertNotNil(attachment.id)
        XCTAssertEqual(attachment.assetId, testAssetId)
        XCTAssertEqual(attachment.maintenanceRecordId, testRecordId)
    }

    func testFindByAssetId_MixedAttachments_ShouldOnlyReturnAssetAttachments() throws {
        // Given
        try repository.create(
            assetId: testAssetId,
            type: "photo",
            filename: "asset_photo.jpg",
            relativePath: "path1.jpg"
        )
        try repository.create(
            maintenanceRecordId: testRecordId,
            type: "photo",
            filename: "record_photo.jpg",
            relativePath: "path2.jpg"
        )

        // When
        let assetAttachments = try repository.findByAssetId(testAssetId)

        // Then
        XCTAssertEqual(assetAttachments.count, 1)
        XCTAssertEqual(assetAttachments.first?.filename, "asset_photo.jpg")
    }
}