import Foundation
import GRDB

class LocationRepository: BaseRepository<Location> {

    // MARK: - Create

    func create(homeId: Int64, name: String, floor: String? = nil) throws -> Location {
        return try dbQueue.write { db in
            var location = Location(
                homeId: homeId,
                name: name,
                floor: floor
            )
            try location.insert(db)
            return location
        }
    }

    // MARK: - Update

    func update(_ id: Int64, name: String? = nil, floor: String? = nil) throws -> Location {
        return try dbQueue.write { db in
            guard var location = try Location.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            if let name = name { location.name = name }
            if let floor = floor { location.floor = floor }

            try location.update(db)
            return location
        }
    }

    // MARK: - Query Methods

    func findByHomeId(_ homeId: Int64) throws -> [Location] {
        return try dbQueue.read { db in
            try Location
                .filter(Location.Columns.homeId == homeId)
                .order(Location.Columns.name)
                .fetchAll(db)
        }
    }
}
