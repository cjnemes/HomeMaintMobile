import Foundation
import GRDB

class AttachmentRepository: BaseRepository<Attachment> {

    // MARK: - Create

    func create(
        assetId: Int64? = nil,
        maintenanceRecordId: Int64? = nil,
        type: String,
        filename: String,
        relativePath: String,
        fileSize: Int? = nil,
        mimeType: String? = nil
    ) throws -> Attachment {
        return try dbQueue.write { db in
            var attachment = Attachment(
                assetId: assetId,
                maintenanceRecordId: maintenanceRecordId,
                type: type,
                filename: filename,
                relativePath: relativePath,
                fileSize: fileSize,
                mimeType: mimeType
            )
            try attachment.insert(db)
            return attachment
        }
    }

    // MARK: - Update

    func update(
        _ id: Int64,
        type: String? = nil,
        filename: String? = nil
    ) throws -> Attachment {
        return try dbQueue.write { db in
            guard var attachment = try Attachment.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            if let type = type { attachment.type = type }
            if let filename = filename { attachment.filename = filename }

            try attachment.update(db)
            return attachment
        }
    }

    // MARK: - Query Methods

    func findByAssetId(_ assetId: Int64) throws -> [Attachment] {
        return try dbQueue.read { db in
            try Attachment
                .filter(Attachment.Columns.assetId == assetId)
                .order(Attachment.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    func findByMaintenanceRecordId(_ recordId: Int64) throws -> [Attachment] {
        return try dbQueue.read { db in
            try Attachment
                .filter(Attachment.Columns.maintenanceRecordId == recordId)
                .order(Attachment.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    func findByType(_ type: String) throws -> [Attachment] {
        return try dbQueue.read { db in
            try Attachment
                .filter(Attachment.Columns.type == type)
                .order(Attachment.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }
}
