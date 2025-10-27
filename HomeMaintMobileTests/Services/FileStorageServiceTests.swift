import XCTest
import UIKit
@testable import HomeMaintMobile

/// Tests for FileStorageService
/// Covers file storage, retrieval, deduplication, and error handling
final class FileStorageServiceTests: XCTestCase {

    var fileStorage: FileStorageService!

    override func setUp() async throws {
        try await super.setUp()
        fileStorage = FileStorageService.shared
    }

    override func tearDown() async throws {
        // Clean up any test files would go here if needed
        try await super.tearDown()
    }

    // MARK: - Image Storage Tests

    func testStoreImage_ShouldSucceed() throws {
        // Create a test image
        let image = createTestImage(color: .blue, size: CGSize(width: 100, height: 100))

        // Store the image
        let result = try fileStorage.storeImage(image, filename: "test-image.jpg")

        // Verify result
        XCTAssertFalse(result.relativePath.isEmpty)
        XCTAssertGreaterThan(result.fileSize, 0)
        XCTAssertFalse(result.wasDeduplicated)

        // Verify file can be retrieved
        let retrievedImage = try fileStorage.getImage(relativePath: result.relativePath)
        XCTAssertNotNil(retrievedImage)
    }

    func testStoreImage_Twice_ShouldDeduplicate() throws {
        // Create identical test image
        let image = createTestImage(color: .red, size: CGSize(width: 50, height: 50))

        // Store first time
        let result1 = try fileStorage.storeImage(image, filename: "test1.jpg")
        XCTAssertFalse(result1.wasDeduplicated)

        // Store same image again
        let result2 = try fileStorage.storeImage(image, filename: "test2.jpg")

        // Should be deduplicated
        XCTAssertTrue(result2.wasDeduplicated)
        XCTAssertEqual(result1.relativePath, result2.relativePath)
    }

    func testGetImage_WhenExists_ShouldReturnImage() throws {
        // Store a test image
        let originalImage = createTestImage(color: .green, size: CGSize(width: 75, height: 75))
        let result = try fileStorage.storeImage(originalImage, filename: "test.jpg")

        // Retrieve the image
        let retrievedImage = try fileStorage.getImage(relativePath: result.relativePath)

        // Verify it's not nil
        XCTAssertNotNil(retrievedImage)
        XCTAssertEqual(retrievedImage.size.width, originalImage.size.width, accuracy: 1.0)
        XCTAssertEqual(retrievedImage.size.height, originalImage.size.height, accuracy: 1.0)
    }

    func testGetImage_WhenNotExists_ShouldThrowError() {
        XCTAssertThrowsError(try fileStorage.getImage(relativePath: "2025/01/nonexistent.jpg")) { error in
            guard let storageError = error as? FileStorageError,
                  case .fileNotFound = storageError else {
                XCTFail("Expected fileNotFound error")
                return
            }
        }
    }

    // MARK: - Data Storage Tests

    func testStoreFile_WithValidData_ShouldSucceed() throws {
        let testData = "Hello, World!".data(using: .utf8)!

        let result = try fileStorage.storeFile(
            data: testData,
            mimeType: "text/plain",
            filename: "test.txt"
        )

        XCTAssertFalse(result.relativePath.isEmpty)
        XCTAssertEqual(result.fileSize, testData.count)

        // Verify retrieval
        let retrievedData = try fileStorage.getFile(relativePath: result.relativePath)
        XCTAssertEqual(retrievedData, testData)
    }

    func testStoreFile_WithTooLargeFile_ShouldThrowError() {
        // Create data larger than 50MB limit
        let largeData = Data(repeating: 0, count: 51 * 1024 * 1024)

        XCTAssertThrowsError(try fileStorage.storeFile(
            data: largeData,
            mimeType: "application/octet-stream",
            filename: "large.dat"
        )) { error in
            guard let storageError = error as? FileStorageError,
                  case .fileTooLarge = storageError else {
                XCTFail("Expected fileTooLarge error")
                return
            }
        }
    }

    func testStoreFile_WithPDF_ShouldSucceed() throws {
        // Create fake PDF data
        let pdfData = "%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF".data(using: .utf8)!

        let result = try fileStorage.storeFile(
            data: pdfData,
            mimeType: "application/pdf",
            filename: "document.pdf"
        )

        XCTAssertTrue(result.relativePath.hasSuffix(".pdf"))

        let retrievedData = try fileStorage.getFile(relativePath: result.relativePath)
        XCTAssertEqual(retrievedData, pdfData)
    }

    // MARK: - Deletion Tests

    func testDeleteFile_WhenExists_ShouldSucceed() throws {
        // Store a file
        let testData = "Delete me".data(using: .utf8)!
        let result = try fileStorage.storeFile(
            data: testData,
            mimeType: "text/plain",
            filename: "to-delete.txt"
        )

        // Delete the file
        XCTAssertNoThrow(try fileStorage.deleteFile(relativePath: result.relativePath))

        // Verify it's gone
        XCTAssertThrowsError(try fileStorage.getFile(relativePath: result.relativePath))
    }

    func testDeleteFile_WhenNotExists_ShouldThrowError() {
        XCTAssertThrowsError(try fileStorage.deleteFile(relativePath: "2025/01/nonexistent.txt")) { error in
            guard let storageError = error as? FileStorageError,
                  case .fileNotFound = storageError else {
                XCTFail("Expected fileNotFound error")
                return
            }
        }
    }

    // MARK: - Path Structure Tests

    func testStoreFile_ShouldUseYearMonthStructure() throws {
        let testData = "Test".data(using: .utf8)!

        let result = try fileStorage.storeFile(
            data: testData,
            mimeType: "text/plain",
            filename: "test.txt"
        )

        // Path should be in format: YYYY/MM/hash.ext
        let pathComponents = result.relativePath.components(separatedBy: "/")
        XCTAssertEqual(pathComponents.count, 3)

        // Year should be 4 digits
        XCTAssertEqual(pathComponents[0].count, 4)

        // Month should be 2 digits
        XCTAssertEqual(pathComponents[1].count, 2)

        // Filename should have hash and extension
        XCTAssertTrue(pathComponents[2].hasSuffix(".txt"))
    }

    // MARK: - Storage Stats Tests

    func testGetTotalStorageUsed_ShouldReturnSize() throws {
        // Store a known-size file
        let testData = Data(repeating: 0, count: 1024) // 1KB

        _ = try fileStorage.storeFile(
            data: testData,
            mimeType: "application/octet-stream",
            filename: "stats-test.dat"
        )

        let totalUsed = try fileStorage.getTotalStorageUsed()

        // Should be at least our 1KB file
        XCTAssertGreaterThanOrEqual(totalUsed, 1024)
    }

    func testGetFileCount_ShouldReturnCount() throws {
        // Get initial count
        let initialCount = try fileStorage.getFileCount()

        // Store a couple files
        let data = "Count me".data(using: .utf8)!
        _ = try fileStorage.storeFile(data: data, mimeType: "text/plain", filename: "count1.txt")
        _ = try fileStorage.storeFile(data: data, mimeType: "text/plain", filename: "count2.txt")

        let newCount = try fileStorage.getFileCount()

        // Count should increase (may not be exactly +2 due to deduplication)
        XCTAssertGreaterThanOrEqual(newCount, initialCount)
    }

    // MARK: - Hash-Based Deduplication Tests

    func testHashBasedDeduplication_SameContent_DifferentFilename() throws {
        let content = "Duplicate content".data(using: .utf8)!

        let result1 = try fileStorage.storeFile(data: content, mimeType: "text/plain", filename: "file1.txt")
        let result2 = try fileStorage.storeFile(data: content, mimeType: "text/plain", filename: "file2.txt")

        // Same content should produce same hash and path
        XCTAssertEqual(result1.relativePath, result2.relativePath)
        XCTAssertTrue(result2.wasDeduplicated)
    }

    func testHashBasedDeduplication_DifferentContent_ShouldCreateSeparateFiles() throws {
        let content1 = "Content A".data(using: .utf8)!
        let content2 = "Content B".data(using: .utf8)!

        let result1 = try fileStorage.storeFile(data: content1, mimeType: "text/plain", filename: "a.txt")
        let result2 = try fileStorage.storeFile(data: content2, mimeType: "text/plain", filename: "b.txt")

        // Different content should produce different paths
        XCTAssertNotEqual(result1.relativePath, result2.relativePath)
        XCTAssertFalse(result2.wasDeduplicated)
    }

    // MARK: - Image Compression Tests

    func testStoreImage_ShouldCompressJPEG() throws {
        // Create a large test image
        let largeImage = createTestImage(color: .orange, size: CGSize(width: 1000, height: 1000))

        // Get uncompressed data size
        guard let uncompressedData = largeImage.pngData() else {
            XCTFail("Failed to get PNG data")
            return
        }

        // Store with compression
        let result = try fileStorage.storeImage(largeImage, filename: "compressed.jpg")

        // JPEG compressed size should be less than PNG
        XCTAssertLessThan(result.fileSize, uncompressedData.count)
    }

    // MARK: - Helper Methods

    private func createTestImage(color: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
