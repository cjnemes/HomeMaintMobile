import Foundation
import GRDB

/// Attachment model for documents and photos
struct Attachment: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {

    var id: Int64?
    var assetId: Int64?
    var maintenanceRecordId: Int64?
    var type: String
    var filename: String
    var relativePath: String
    var fileSize: Int?
    var mimeType: String?
    var createdAt: Date

    // MARK: - GRDB Configuration

    static let databaseTableName = "attachments"

    enum Columns: String, ColumnExpression {
        case id
        case assetId = "asset_id"
        case maintenanceRecordId = "maintenance_record_id"
        case type, filename
        case relativePath = "relative_path"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case createdAt = "created_at"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case assetId = "asset_id"
        case maintenanceRecordId = "maintenance_record_id"
        case type, filename
        case relativePath = "relative_path"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case createdAt = "created_at"
    }

    // MARK: - Relationships

    static let asset = belongsTo(Asset.self)
    static let maintenanceRecord = belongsTo(MaintenanceRecord.self)

    // MARK: - Initialization

    init(
        id: Int64? = nil,
        assetId: Int64? = nil,
        maintenanceRecordId: Int64? = nil,
        type: String,
        filename: String,
        relativePath: String,
        fileSize: Int? = nil,
        mimeType: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.assetId = assetId
        self.maintenanceRecordId = maintenanceRecordId
        self.type = type
        self.filename = filename
        self.relativePath = relativePath
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var typeEnum: AttachmentType {
        return AttachmentType(rawValue: type) ?? .other
    }

    var formattedFileSize: String? {
        guard let size = fileSize else { return nil }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    var isImage: Bool {
        guard let mimeType = mimeType else { return false }
        return mimeType.starts(with: "image/")
    }

    var isPDF: Bool {
        return mimeType == "application/pdf"
    }

    // MARK: - Attachment Types

    enum AttachmentType: String, CaseIterable {
        case photo = "photo"
        case manual = "manual"
        case receipt = "receipt"
        case warranty = "warranty"
        case invoice = "invoice"
        case other = "other"

        var displayText: String {
            return rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .photo: return "photo"
            case .manual: return "book"
            case .receipt: return "doc.text"
            case .warranty: return "checkmark.seal"
            case .invoice: return "dollarsign.circle"
            case .other: return "doc"
            }
        }
    }

    // MARK: - GRDB Insertion

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

}
