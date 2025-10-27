import Foundation
import GRDB

/// Asset model representing home systems, appliances, and equipment
/// Matches HomeMaint web app schema for data portability
struct Asset: Codable, FetchableRecord, PersistableRecord {

    // MARK: - Properties

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

    /// Database table name
    static let databaseTableName = "assets"

    /// Column names
    enum Columns: String, ColumnExpression {
        case id, homeId = "home_id", categoryId = "category_id", locationId = "location_id"
        case name, manufacturer, modelNumber = "model_number", serialNumber = "serial_number"
        case purchaseDate = "purchase_date", installationDate = "installation_date"
        case warrantyExpiration = "warranty_expiration", notes
        case createdAt = "created_at", updatedAt = "updated_at"
    }

    /// Coding keys for database mapping
    enum CodingKeys: String, CodingKey {
        case id, homeId = "home_id", categoryId = "category_id", locationId = "location_id"
        case name, manufacturer, modelNumber = "model_number", serialNumber = "serial_number"
        case purchaseDate = "purchase_date", installationDate = "installation_date"
        case warrantyExpiration = "warranty_expiration", notes
        case createdAt = "created_at", updatedAt = "updated_at"
    }

    // MARK: - Relationships

    /// Associated category
    static let category = belongsTo(Category.self)

    /// Associated location
    static let location = belongsTo(Location.self)

    /// Associated maintenance records
    static let maintenanceRecords = hasMany(MaintenanceRecord.self)

    /// Associated tasks
    static let tasks = hasMany(Task.self)

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

    /// Display name (combines name and model if available)
    var displayName: String {
        if let model = modelNumber {
            return "\(name) (\(model))"
        }
        return name
    }

    /// Warranty status
    var warrantyStatus: WarrantyStatus {
        guard let expiration = warrantyExpiration else {
            return .unknown
        }

        let now = Date()
        if expiration < now {
            return .expired
        } else if expiration < now.addingTimeInterval(30 * 24 * 60 * 60) { // 30 days
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
    }
}

// MARK: - Identifiable (for SwiftUI)

extension Asset: Identifiable {}

// MARK: - Hashable & Equatable

extension Asset: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Asset, rhs: Asset) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Example Related Models (minimal definitions)

struct Category: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var homeId: Int64
    var name: String
    var icon: String?
    var createdAt: Date

    static let databaseTableName = "categories"
}

struct Location: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var homeId: Int64
    var name: String
    var floor: String?
    var createdAt: Date

    static let databaseTableName = "locations"
}

struct MaintenanceRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var assetId: Int64
    var serviceProviderId: Int64?
    var date: Date
    var type: String
    var description: String?
    var cost: Decimal?
    var notes: String?
    var createdAt: Date

    static let databaseTableName = "maintenance_records"
}

struct Task: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var assetId: Int64?
    var title: String
    var description: String?
    var dueDate: Date?
    var priority: String?
    var status: String
    var createdAt: Date
    var completedAt: Date?

    static let databaseTableName = "tasks"
}
