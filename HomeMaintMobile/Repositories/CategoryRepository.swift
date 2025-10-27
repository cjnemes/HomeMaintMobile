import Foundation
import GRDB

class CategoryRepository: BaseRepository<Category> {

    // MARK: - Create

    func create(homeId: Int64, name: String, icon: String? = nil) throws -> Category {
        return try dbQueue.write { db in
            var category = Category(
                homeId: homeId,
                name: name,
                icon: icon
            )
            try category.insert(db)
            return category
        }
    }

    // MARK: - Update

    func update(_ id: Int64, name: String? = nil, icon: String? = nil) throws -> Category {
        return try dbQueue.write { db in
            guard var category = try Category.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            if let name = name { category.name = name }
            if let icon = icon { category.icon = icon }

            try category.update(db)
            return category
        }
    }

    // MARK: - Query Methods

    func findByHomeId(_ homeId: Int64) throws -> [Category] {
        return try dbQueue.read { db in
            try Category
                .filter(Category.Columns.homeId == homeId)
                .order(Category.Columns.name)
                .fetchAll(db)
        }
    }
}
