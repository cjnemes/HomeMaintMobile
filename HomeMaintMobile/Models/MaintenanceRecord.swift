import Foundation
import GRDB

/// Maintenance record model for tracking service history
struct MaintenanceRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {

    var id: Int64?
    var assetId: Int64
    var serviceProviderId: Int64?
    var date: Date
    var type: String
    var description: String?
    var cost: String? // Stored as String to use Decimal (no float!)
    var notes: String?
    var createdAt: Date

    // MARK: - GRDB Configuration

    static let databaseTableName = "maintenance_records"

    enum Columns: String, ColumnExpression {
        case id
        case assetId = "asset_id"
        case serviceProviderId = "service_provider_id"
        case date, type, description, cost, notes
        case createdAt = "created_at"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case assetId = "asset_id"
        case serviceProviderId = "service_provider_id"
        case date, type, description, cost, notes
        case createdAt = "created_at"
    }

    // MARK: - Relationships

    static let asset = belongsTo(Asset.self)
    static let serviceProvider = belongsTo(ServiceProvider.self)
    static let attachments = hasMany(Attachment.self)

    // MARK: - Initialization

    init(
        id: Int64? = nil,
        assetId: Int64,
        serviceProviderId: Int64? = nil,
        date: Date,
        type: String,
        description: String? = nil,
        cost: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.assetId = assetId
        self.serviceProviderId = serviceProviderId
        self.date = date
        self.type = type
        self.description = description
        self.cost = cost
        self.notes = notes
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var costDecimal: Decimal? {
        guard let cost = cost else { return nil }
        return Decimal(string: cost)
    }

    var formattedCost: String? {
        guard let decimal = costDecimal else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: decimal as NSNumber)
    }

    // MARK: - Maintenance Types

    enum MaintenanceType: String, CaseIterable {
        case repair = "Repair"
        case inspection = "Inspection"
        case cleaning = "Cleaning"
        case replacement = "Replacement"
        case upgrade = "Upgrade"
        case preventive = "Preventive"
        case emergency = "Emergency"
        case other = "Other"
    }

    // MARK: - GRDB Insertion

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

}
