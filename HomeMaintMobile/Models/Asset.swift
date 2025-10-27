import Foundation
import GRDB

/// Asset model representing home systems, appliances, and equipment
struct Asset: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {

    var id: Int64?
    var homeId: Int64
    var categoryId: Int64?
    var locationId: Int64?
    var name: String
    var manufacturer: String?
    var modelNumber: String?
    var serialNumber: String?
    var purchaseDate: Date?
    var installationDate: Date?
    var warrantyExpiration: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - GRDB Configuration

    static let databaseTableName = "assets"

    enum Columns: String, ColumnExpression {
        case id
        case homeId = "home_id"
        case categoryId = "category_id"
        case locationId = "location_id"
        case name, manufacturer
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case purchaseDate = "purchase_date"
        case installationDate = "installation_date"
        case warrantyExpiration = "warranty_expiration"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case homeId = "home_id"
        case categoryId = "category_id"
        case locationId = "location_id"
        case name, manufacturer
        case modelNumber = "model_number"
        case serialNumber = "serial_number"
        case purchaseDate = "purchase_date"
        case installationDate = "installation_date"
        case warrantyExpiration = "warranty_expiration"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Relationships

    static let home = belongsTo(Home.self)
    static let category = belongsTo(Category.self)
    static let location = belongsTo(Location.self)
    static let maintenanceRecords = hasMany(MaintenanceRecord.self)
    static let tasks = hasMany(MaintenanceTask.self)
    static let attachments = hasMany(Attachment.self)

    // MARK: - Initialization

    init(
        id: Int64? = nil,
        homeId: Int64,
        categoryId: Int64? = nil,
        locationId: Int64? = nil,
        name: String,
        manufacturer: String? = nil,
        modelNumber: String? = nil,
        serialNumber: String? = nil,
        purchaseDate: Date? = nil,
        installationDate: Date? = nil,
        warrantyExpiration: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.homeId = homeId
        self.categoryId = categoryId
        self.locationId = locationId
        self.name = name
        self.manufacturer = manufacturer
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.purchaseDate = purchaseDate
        self.installationDate = installationDate
        self.warrantyExpiration = warrantyExpiration
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    var displayName: String {
        if let model = modelNumber {
            return "\(name) (\(model))"
        }
        return name
    }

    var warrantyStatus: WarrantyStatus {
        guard let expiration = warrantyExpiration else {
            return .unknown
        }

        let now = Date()
        if expiration < now {
            return .expired
        } else if expiration < now.addingTimeInterval(30 * 24 * 60 * 60) {
            return .expiringSoon
        } else {
            return .active
        }
    }

    enum WarrantyStatus {
        case active
        case expiringSoon
        case expired
        case unknown

        var displayText: String {
            switch self {
            case .active: return "Active"
            case .expiringSoon: return "Expiring Soon"
            case .expired: return "Expired"
            case .unknown: return "Unknown"
            }
        }

        var color: String {
            switch self {
            case .active: return "green"
            case .expiringSoon: return "orange"
            case .expired: return "red"
            case .unknown: return "gray"
            }
        }
    }

    // MARK: - GRDB Insertion

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

}
