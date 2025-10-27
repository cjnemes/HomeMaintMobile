import Foundation
import GRDB

/// Base protocol for all repositories
/// Provides common CRUD operations
protocol RepositoryProtocol {
    associatedtype Model: Codable & FetchableRecord & PersistableRecord
    associatedtype CreateDTO
    associatedtype UpdateDTO

    func findAll() throws -> [Model]
    func findById(_ id: Int64) throws -> Model?
    func create(_ data: CreateDTO) throws -> Model
    func update(_ id: Int64, with data: UpdateDTO) throws -> Model?
    func delete(_ id: Int64) throws -> Bool
}

/// Abstract base class for repositories using GRDB
/// Subclass this for each model (Asset, MaintenanceRecord, etc.)
class BaseRepository<Model: Codable & FetchableRecord & PersistableRecord> {

    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
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
    func delete(_ id: Int64) throws -> Bool {
        return try dbQueue.write { db in
            try Model.deleteOne(db, key: id)
        }
    }

    // MARK: - Subclass Override Points

    /// Subclasses must implement custom create logic
    func create(_ data: Any) throws -> Model {
        fatalError("Subclasses must override create(_:)")
    }

    /// Subclasses must implement custom update logic
    func update(_ id: Int64, with data: Any) throws -> Model? {
        fatalError("Subclasses must override update(_:with:)")
    }
}

// MARK: - Example Usage

/// Example: Asset Repository
/// Demonstrates how to extend BaseRepository
///
/// ```swift
/// class AssetRepository: BaseRepository<Asset> {
///
///     struct CreateAssetDTO {
///         let homeId: Int64
///         let name: String
///         let categoryId: Int64?
///         let locationId: Int64?
///     }
///
///     struct UpdateAssetDTO {
///         let name: String?
///         let categoryId: Int64?
///         let locationId: Int64?
///     }
///
///     override func create(_ data: Any) throws -> Asset {
///         guard let dto = data as? CreateAssetDTO else {
///             throw RepositoryError.invalidInput
///         }
///
///         return try dbQueue.write { db in
///             var asset = Asset(
///                 id: nil,
///                 homeId: dto.homeId,
///                 name: dto.name,
///                 categoryId: dto.categoryId,
///                 locationId: dto.locationId,
///                 createdAt: Date()
///             )
///             try asset.insert(db)
///             return asset
///         }
///     }
///
///     override func update(_ id: Int64, with data: Any) throws -> Asset? {
///         guard let dto = data as? UpdateAssetDTO else {
///             throw RepositoryError.invalidInput
///         }
///
///         return try dbQueue.write { db in
///             guard var asset = try Asset.fetchOne(db, key: id) else {
///                 return nil
///             }
///
///             if let name = dto.name { asset.name = name }
///             if let categoryId = dto.categoryId { asset.categoryId = categoryId }
///             if let locationId = dto.locationId { asset.locationId = locationId }
///
///             try asset.update(db)
///             return asset
///         }
///     }
///
///     func findByHomeId(_ homeId: Int64) throws -> [Asset] {
///         return try dbQueue.read { db in
///             try Asset
///                 .filter(Column("home_id") == homeId)
///                 .fetchAll(db)
///         }
///     }
/// }
/// ```

enum RepositoryError: Error {
    case invalidInput
    case notFound
    case databaseError(String)
}
