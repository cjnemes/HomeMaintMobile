import Foundation
import GRDB

class AssetRepository: BaseRepository<Asset> {

    // MARK: - Create

    func create(
        homeId: Int64,
        name: String,
        categoryId: Int64? = nil,
        locationId: Int64? = nil,
        manufacturer: String? = nil,
        modelNumber: String? = nil,
        serialNumber: String? = nil,
        purchaseDate: Date? = nil,
        installationDate: Date? = nil,
        warrantyExpiration: Date? = nil,
        notes: String? = nil
    ) throws -> Asset {
        return try dbQueue.write { db in
            var asset = Asset(
                homeId: homeId,
                categoryId: categoryId,
                locationId: locationId,
                name: name,
                manufacturer: manufacturer,
                modelNumber: modelNumber,
                serialNumber: serialNumber,
                purchaseDate: purchaseDate,
                installationDate: installationDate,
                warrantyExpiration: warrantyExpiration,
                notes: notes
            )
            try asset.insert(db)

            // Ensure ID is set (should be set by didInsert, but verify)
            if asset.id == nil {
                // Fallback: use the last inserted row ID
                asset.id = db.lastInsertedRowID
            }

            return asset
        }
    }

    // MARK: - Update

    func update(
        _ id: Int64,
        name: String? = nil,
        categoryId: Int64? = nil,
        locationId: Int64? = nil,
        manufacturer: String? = nil,
        modelNumber: String? = nil,
        serialNumber: String? = nil,
        purchaseDate: Date? = nil,
        installationDate: Date? = nil,
        warrantyExpiration: Date? = nil,
        notes: String? = nil
    ) throws -> Asset {
        return try dbQueue.write { db in
            guard var asset = try Asset.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            if let name = name { asset.name = name }
            if let categoryId = categoryId { asset.categoryId = categoryId }
            if let locationId = locationId { asset.locationId = locationId }
            if let manufacturer = manufacturer { asset.manufacturer = manufacturer }
            if let modelNumber = modelNumber { asset.modelNumber = modelNumber }
            if let serialNumber = serialNumber { asset.serialNumber = serialNumber }
            if let purchaseDate = purchaseDate { asset.purchaseDate = purchaseDate }
            if let installationDate = installationDate { asset.installationDate = installationDate }
            if let warrantyExpiration = warrantyExpiration { asset.warrantyExpiration = warrantyExpiration }
            if let notes = notes { asset.notes = notes }

            asset.updatedAt = Date()

            try asset.update(db)
            return asset
        }
    }

    // MARK: - Query Methods

    func findByHomeId(_ homeId: Int64) throws -> [Asset] {
        return try dbQueue.read { db in
            try Asset
                .filter(Asset.Columns.homeId == homeId)
                .order(Asset.Columns.name)
                .fetchAll(db)
        }
    }

    func findByCategoryId(_ categoryId: Int64) throws -> [Asset] {
        return try dbQueue.read { db in
            try Asset
                .filter(Asset.Columns.categoryId == categoryId)
                .order(Asset.Columns.name)
                .fetchAll(db)
        }
    }

    func findByLocationId(_ locationId: Int64) throws -> [Asset] {
        return try dbQueue.read { db in
            try Asset
                .filter(Asset.Columns.locationId == locationId)
                .order(Asset.Columns.name)
                .fetchAll(db)
        }
    }

    func search(homeId: Int64, query: String) throws -> [Asset] {
        return try dbQueue.read { db in
            let pattern = "%\(query)%"
            return try Asset
                .filter(Asset.Columns.homeId == homeId)
                .filter(
                    Asset.Columns.name.like(pattern) ||
                    Asset.Columns.manufacturer.like(pattern) ||
                    Asset.Columns.modelNumber.like(pattern)
                )
                .order(Asset.Columns.name)
                .fetchAll(db)
        }
    }

    func findExpiringWarranties(homeId: Int64, withinDays days: Int = 30) throws -> [Asset] {
        return try dbQueue.read { db in
            let futureDate = Date().addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
            return try Asset
                .filter(Asset.Columns.homeId == homeId)
                .filter(Asset.Columns.warrantyExpiration != nil)
                .filter(Asset.Columns.warrantyExpiration <= futureDate)
                .order(Asset.Columns.warrantyExpiration)
                .fetchAll(db)
        }
    }
}
