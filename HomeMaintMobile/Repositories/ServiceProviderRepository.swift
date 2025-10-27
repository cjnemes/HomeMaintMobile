import Foundation
import GRDB

class ServiceProviderRepository: BaseRepository<ServiceProvider> {

    // MARK: - Create

    func create(
        homeId: Int64,
        company: String,
        name: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        specialty: String? = nil,
        notes: String? = nil
    ) throws -> ServiceProvider {
        return try dbQueue.write { db in
            var provider = ServiceProvider(
                homeId: homeId,
                company: company,
                name: name,
                phone: phone,
                email: email,
                specialty: specialty,
                notes: notes
            )
            try provider.insert(db)
            return provider
        }
    }

    // MARK: - Update

    func update(
        _ id: Int64,
        company: String? = nil,
        name: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        specialty: String? = nil,
        notes: String? = nil
    ) throws -> ServiceProvider {
        return try dbQueue.write { db in
            guard var provider = try ServiceProvider.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            if let company = company { provider.company = company }
            if let name = name { provider.name = name }
            if let phone = phone { provider.phone = phone }
            if let email = email { provider.email = email }
            if let specialty = specialty { provider.specialty = specialty }
            if let notes = notes { provider.notes = notes }

            try provider.update(db)
            return provider
        }
    }

    // MARK: - Query Methods

    func findByHomeId(_ homeId: Int64) throws -> [ServiceProvider] {
        return try dbQueue.read { db in
            try ServiceProvider
                .filter(ServiceProvider.Columns.homeId == homeId)
                .order(ServiceProvider.Columns.company)
                .fetchAll(db)
        }
    }

    func findBySpecialty(_ specialty: String) throws -> [ServiceProvider] {
        return try dbQueue.read { db in
            try ServiceProvider
                .filter(ServiceProvider.Columns.specialty == specialty)
                .order(ServiceProvider.Columns.company)
                .fetchAll(db)
        }
    }

    func search(homeId: Int64, query: String) throws -> [ServiceProvider] {
        return try dbQueue.read { db in
            let pattern = "%\(query)%"
            return try ServiceProvider
                .filter(ServiceProvider.Columns.homeId == homeId)
                .filter(
                    ServiceProvider.Columns.company.like(pattern) ||
                    ServiceProvider.Columns.name.like(pattern) ||
                    ServiceProvider.Columns.specialty.like(pattern)
                )
                .order(ServiceProvider.Columns.company)
                .fetchAll(db)
        }
    }
}
