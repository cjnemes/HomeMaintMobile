import Foundation
import GRDB

/// Home model representing a property
struct Home: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {

    var id: Int64?
    var name: String
    var address: String?
    var purchaseDate: Date?
    var squareFootage: Int?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - GRDB Configuration

    static let databaseTableName = "homes"

    enum Columns: String, ColumnExpression {
        case id, name, address
        case purchaseDate = "purchase_date"
        case squareFootage = "square_footage"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum CodingKeys: String, CodingKey {
        case id, name, address
        case purchaseDate = "purchase_date"
        case squareFootage = "square_footage"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Relationships

    static let categories = hasMany(Category.self)
    static let locations = hasMany(Location.self)
    static let assets = hasMany(Asset.self)
    static let serviceProviders = hasMany(ServiceProvider.self)

    // MARK: - Initialization

    init(
        id: Int64? = nil,
        name: String,
        address: String? = nil,
        purchaseDate: Date? = nil,
        squareFootage: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.purchaseDate = purchaseDate
        self.squareFootage = squareFootage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - GRDB Insertion

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
