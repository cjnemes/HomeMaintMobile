import Foundation
import GRDB

/// Service provider model for contractor contacts
struct ServiceProvider: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {

    var id: Int64?
    var homeId: Int64
    var company: String
    var name: String?
    var phone: String?
    var email: String?
    var specialty: String?
    var notes: String?
    var createdAt: Date

    // MARK: - GRDB Configuration

    static let databaseTableName = "service_providers"

    enum Columns: String, ColumnExpression {
        case id
        case homeId = "home_id"
        case company, name, phone, email, specialty, notes
        case createdAt = "created_at"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case homeId = "home_id"
        case company, name, phone, email, specialty, notes
        case createdAt = "created_at"
    }

    // MARK: - Relationships

    static let home = belongsTo(Home.self)
    static let maintenanceRecords = hasMany(MaintenanceRecord.self)

    // MARK: - Initialization

    init(
        id: Int64? = nil,
        homeId: Int64,
        company: String,
        name: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        specialty: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.homeId = homeId
        self.company = company
        self.name = name
        self.phone = phone
        self.email = email
        self.specialty = specialty
        self.notes = notes
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var displayName: String {
        if let name = name, !name.isEmpty {
            return "\(company) (\(name))"
        }
        return company
    }

    // MARK: - GRDB Insertion

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

}
