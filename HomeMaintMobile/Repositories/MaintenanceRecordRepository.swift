import Foundation
import GRDB

class MaintenanceRecordRepository: BaseRepository<MaintenanceRecord> {

    // MARK: - Create

    func create(
        assetId: Int64,
        date: Date,
        type: String,
        serviceProviderId: Int64? = nil,
        description: String? = nil,
        cost: String? = nil,
        notes: String? = nil
    ) throws -> MaintenanceRecord {
        return try dbQueue.write { db in
            var record = MaintenanceRecord(
                assetId: assetId,
                serviceProviderId: serviceProviderId,
                date: date,
                type: type,
                description: description,
                cost: cost,
                notes: notes
            )
            try record.insert(db)

            // Ensure ID is set (should be set by didInsert, but verify)
            if record.id == nil {
                // Fallback: use the last inserted row ID
                record.id = db.lastInsertedRowID
            }

            return record
        }
    }

    // MARK: - Update

    func update(
        _ id: Int64,
        date: Date? = nil,
        type: String? = nil,
        serviceProviderId: Int64? = nil,
        description: String? = nil,
        cost: String? = nil,
        notes: String? = nil
    ) throws -> MaintenanceRecord {
        return try dbQueue.write { db in
            guard var record = try MaintenanceRecord.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            if let date = date { record.date = date }
            if let type = type { record.type = type }
            if let serviceProviderId = serviceProviderId { record.serviceProviderId = serviceProviderId }
            if let description = description { record.description = description }
            if let cost = cost { record.cost = cost }
            if let notes = notes { record.notes = notes }

            try record.update(db)
            return record
        }
    }

    // MARK: - Query Methods

    func findByAssetId(_ assetId: Int64) throws -> [MaintenanceRecord] {
        return try dbQueue.read { db in
            try MaintenanceRecord
                .filter(MaintenanceRecord.Columns.assetId == assetId)
                .order(MaintenanceRecord.Columns.date.desc)
                .fetchAll(db)
        }
    }

    func findByServiceProviderId(_ providerId: Int64) throws -> [MaintenanceRecord] {
        return try dbQueue.read { db in
            try MaintenanceRecord
                .filter(MaintenanceRecord.Columns.serviceProviderId == providerId)
                .order(MaintenanceRecord.Columns.date.desc)
                .fetchAll(db)
        }
    }

    func findRecent(limit: Int = 10) throws -> [MaintenanceRecord] {
        return try dbQueue.read { db in
            try MaintenanceRecord
                .order(MaintenanceRecord.Columns.date.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func findByDateRange(from: Date, to: Date) throws -> [MaintenanceRecord] {
        return try dbQueue.read { db in
            try MaintenanceRecord
                .filter(MaintenanceRecord.Columns.date >= from)
                .filter(MaintenanceRecord.Columns.date <= to)
                .order(MaintenanceRecord.Columns.date.desc)
                .fetchAll(db)
        }
    }

    func getTotalCost(assetId: Int64? = nil) throws -> Decimal {
        let records: [MaintenanceRecord]
        if let assetId = assetId {
            records = try findByAssetId(assetId)
        } else {
            records = try findAll()
        }

        var total: Decimal = 0
        for record in records {
            if let decimal = record.costDecimal {
                total += decimal
            }
        }
        return total
    }
}
