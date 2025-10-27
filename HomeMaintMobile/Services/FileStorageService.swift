import Foundation
import UIKit
import CryptoKit

/// Service for file storage with hash-based deduplication
/// Stores files in app's Documents directory organized by year/month
class FileStorageService {

    static let shared = FileStorageService()

    private let fileManager = FileManager.default
    private let baseDirectory: URL

    // MARK: - Configuration

    private let maxFileSize: Int = 50 * 1024 * 1024 // 50MB
    private let jpegCompressionQuality: CGFloat = 0.8

    // MARK: - Initialization

    private init() {
        do {
            let documentsURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.baseDirectory = documentsURL.appendingPathComponent("uploads", isDirectory: true)

            // Create uploads directory if needed
            try createDirectoryIfNeeded(at: baseDirectory)

            print("✅ File storage initialized at: \(baseDirectory.path)")
        } catch {
            fatalError("Failed to initialize file storage: \(error)")
        }
    }

    // MARK: - Store File

    /// Store file with hash-based deduplication
    /// Returns relative path to stored file
    func storeFile(data: Data, mimeType: String, filename: String) throws -> StoreFileResult {
        // Validate file size
        guard data.count <= maxFileSize else {
            throw FileStorageError.fileTooLarge(data.count, maxFileSize)
        }

        // Calculate hash
        let hash = calculateHash(data: data)

        // Determine file extension
        let fileExtension = (filename as NSString).pathExtension.isEmpty
            ? extensionForMimeType(mimeType)
            : (filename as NSString).pathExtension

        // Create year/month directory structure
        let dateComponents = Calendar.current.dateComponents([.year, .month], from: Date())

        guard let yearValue = dateComponents.year, let monthValue = dateComponents.month else {
            throw FileStorageError.invalidDateComponents
        }

        let year = String(yearValue)
        let month = String(format: "%02d", monthValue)

        let directoryPath = baseDirectory
            .appendingPathComponent(year, isDirectory: true)
            .appendingPathComponent(month, isDirectory: true)

        try createDirectoryIfNeeded(at: directoryPath)

        // Create filename with hash
        let hashedFilename = "\(hash).\(fileExtension)"
        let fileURL = directoryPath.appendingPathComponent(hashedFilename)

        // Check if file already exists (deduplication)
        if fileManager.fileExists(atPath: fileURL.path) {
            print("  ♻️ File already exists (deduplicated): \(hashedFilename)")
            let relativePath = "\(year)/\(month)/\(hashedFilename)"
            return StoreFileResult(relativePath: relativePath, fileSize: data.count, wasDeduplicated: true)
        }

        // Write file
        try data.write(to: fileURL)

        let relativePath = "\(year)/\(month)/\(hashedFilename)"
        print("  ✓ File stored: \(relativePath) (\(formatBytes(data.count)))")

        return StoreFileResult(relativePath: relativePath, fileSize: data.count, wasDeduplicated: false)
    }

    /// Store image (compresses JPEG automatically)
    func storeImage(_ image: UIImage, filename: String) throws -> StoreFileResult {
        guard let data = image.jpegData(compressionQuality: jpegCompressionQuality) else {
            throw FileStorageError.imageCompressionFailed
        }

        return try storeFile(data: data, mimeType: "image/jpeg", filename: filename)
    }

    // MARK: - Retrieve File

    /// Get file data from relative path
    func getFile(relativePath: String) throws -> Data {
        let fileURL = baseDirectory.appendingPathComponent(relativePath)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileStorageError.fileNotFound(relativePath)
        }

        return try Data(contentsOf: fileURL)
    }

    /// Get image from relative path
    func getImage(relativePath: String) throws -> UIImage {
        let data = try getFile(relativePath: relativePath)

        guard let image = UIImage(data: data) else {
            throw FileStorageError.imageDecodingFailed
        }

        return image
    }

    // MARK: - Delete File

    /// Delete file by relative path
    func deleteFile(relativePath: String) throws {
        let fileURL = baseDirectory.appendingPathComponent(relativePath)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw FileStorageError.fileNotFound(relativePath)
        }

        try fileManager.removeItem(at: fileURL)
        print("  ✓ File deleted: \(relativePath)")
    }

    // MARK: - Utility Methods

    private func createDirectoryIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func calculateHash(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16).description
    }

    private func extensionForMimeType(_ mimeType: String) -> String {
        switch mimeType {
        case "image/jpeg": return "jpg"
        case "image/png": return "png"
        case "image/heic": return "heic"
        case "application/pdf": return "pdf"
        case "text/plain": return "txt"
        default: return "dat"
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    // MARK: - Storage Stats

    /// Get total storage used
    func getTotalStorageUsed() throws -> Int {
        var totalSize = 0

        let enumerator = fileManager.enumerator(at: baseDirectory, includingPropertiesForKeys: [.fileSizeKey])
        while let fileURL = enumerator?.nextObject() as? URL {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += fileSize
            }
        }

        return totalSize
    }

    /// Get count of stored files
    func getFileCount() throws -> Int {
        var count = 0

        let enumerator = fileManager.enumerator(at: baseDirectory, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.hasDirectoryPath == false {
                count += 1
            }
        }

        return count
    }
}

// MARK: - Result & Error Types

struct StoreFileResult {
    let relativePath: String
    let fileSize: Int
    let wasDeduplicated: Bool
}

enum FileStorageError: Error {
    case fileTooLarge(Int, Int)
    case fileNotFound(String)
    case imageCompressionFailed
    case imageDecodingFailed
    case invalidDateComponents

    var localizedDescription: String {
        switch self {
        case .fileTooLarge(let size, let max):
            return "File size (\(size) bytes) exceeds maximum (\(max) bytes)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .imageDecodingFailed:
            return "Failed to decode image"
        case .invalidDateComponents:
            return "Failed to get valid date components"
        }
    }
}
