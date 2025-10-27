import Foundation
import GRDB

/// Base repository providing common CRUD operations
/// All repositories extend this class
class BaseRepository<Model: Codable & FetchableRecord & PersistableRecord & MutablePersistableRecord> {

    var dbQueue: DatabaseQueue {
        guard let queue = DatabaseService.shared.dbQueue else {
            fatalError("❌ DatabaseService not initialized! Call DatabaseService.shared.initialize() before creating repositories.")
        }
        return queue
    }

    required init() {
    }

    // MARK: - Common CRUD Operations

    /// Find all records
    func findAll() throws -> [Model] {
        return try dbQueue.read { db in
            try Model.fetchAll(db)
        }
    }

    /// Find record by ID
    func findById(_ id: Int64) throws -> Model? {
        return try dbQueue.read { db in
            try Model.fetchOne(db, key: id)
        }
    }

    /// Count all records
    func count() throws -> Int {
        return try dbQueue.read { db in
            try Model.fetchCount(db)
        }
    }

    /// Delete record by ID
    @discardableResult
    func delete(_ id: Int64) throws -> Bool {
        return try dbQueue.write { db in
            try Model.deleteOne(db, key: id)
        }
    }

    /// Delete all records (use with caution!)
    func deleteAll() throws {
        _ = try dbQueue.write { db in
            try Model.deleteAll(db)
        }
    }
}

// MARK: - Repository Error

enum RepositoryError: Error {
    case notFound
    case invalidInput
    case databaseError(String)

    var localizedDescription: String {
        switch self {
        case .notFound:
            return "Record not found"
        case .invalidInput:
            return "Invalid input data"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}
