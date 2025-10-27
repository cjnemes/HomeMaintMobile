import Foundation
import GRDB

/// Category model for organizing assets (HVAC, Plumbing, etc.)
struct Category: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {

    var id: Int64?
    var homeId: Int64
    var name: String
    var icon: String?
    var createdAt: Date

    // MARK: - GRDB Configuration

    static let databaseTableName = "categories"

    enum Columns: String, ColumnExpression {
        case id
        case homeId = "home_id"
        case name, icon
        case createdAt = "created_at"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case homeId = "home_id"
        case name, icon
        case createdAt = "created_at"
    }

    // MARK: - Relationships

    static let home = belongsTo(Home.self)
    static let assets = hasMany(Asset.self)

    // MARK: - Initialization

    init(
        id: Int64? = nil,
        homeId: Int64,
        name: String,
        icon: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.homeId = homeId
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
    }

    // MARK: - GRDB Insertion

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

}
