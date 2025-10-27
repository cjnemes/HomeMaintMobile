import Foundation
import GRDB

class HomeRepository: BaseRepository<Home> {

    // MARK: - Create

    func create(name: String, address: String? = nil, purchaseDate: Date? = nil, squareFootage: Int? = nil) throws -> Home {
        return try dbQueue.write { db in
            var home = Home(
                name: name,
                address: address,
                purchaseDate: purchaseDate,
                squareFootage: squareFootage
            )
            try home.insert(db)
            return home
        }
    }

    // MARK: - Update

    func update(_ id: Int64, name: String? = nil, address: String? = nil, purchaseDate: Date? = nil, squareFootage: Int? = nil) throws -> Home {
        return try dbQueue.write { db in
            guard var home = try Home.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            if let name = name { home.name = name }
            if let address = address { home.address = address }
            if let purchaseDate = purchaseDate { home.purchaseDate = purchaseDate }
            if let squareFootage = squareFootage { home.squareFootage = squareFootage }

            home.updatedAt = Date()

            try home.update(db)
            return home
        }
    }

    // MARK: - Query Methods

    /// Get first home (for single-home MVP)
    func getFirst() throws -> Home? {
        return try dbQueue.read { db in
            try Home.fetchOne(db)
        }
    }
}
