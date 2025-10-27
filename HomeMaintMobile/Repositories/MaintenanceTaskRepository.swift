import Foundation
import GRDB

class MaintenanceTaskRepository: BaseRepository<MaintenanceTask> {

    // MARK: - Create

    func create(
        title: String,
        assetId: Int64? = nil,
        description: String? = nil,
        dueDate: Date? = nil,
        priority: String? = nil,
        status: String = MaintenanceTask.TaskStatus.pending.rawValue
    ) throws -> MaintenanceTask {
        return try dbQueue.write { db in
            var task = MaintenanceTask(
                assetId: assetId,
                title: title,
                description: description,
                dueDate: dueDate,
                priority: priority,
                status: status
            )
            try task.insert(db)

            // Ensure ID is set (should be set by didInsert, but verify)
            if task.id == nil {
                // Fallback: use the last inserted row ID
                task.id = db.lastInsertedRowID
            }

            return task
        }
    }

    // MARK: - Update

    func update(
        _ id: Int64,
        title: String? = nil,
        assetId: Int64? = nil,
        description: String? = nil,
        dueDate: Date? = nil,
        priority: String? = nil,
        status: String? = nil
    ) throws -> MaintenanceTask {
        return try dbQueue.write { db in
            guard var task = try MaintenanceTask.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            if let title = title { task.title = title }
            if let assetId = assetId { task.assetId = assetId }
            if let description = description { task.description = description }
            if let dueDate = dueDate { task.dueDate = dueDate }
            if let priority = priority { task.priority = priority }
            if let status = status { task.status = status }

            try task.update(db)
            return task
        }
    }

    // MARK: - Status Operations

    func markAsCompleted(_ id: Int64) throws -> MaintenanceTask {
        return try dbQueue.write { db in
            guard var task = try MaintenanceTask.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            task.status = MaintenanceTask.TaskStatus.completed.rawValue
            task.completedAt = Date()

            try task.update(db)
            return task
        }
    }

    func markAsPending(_ id: Int64) throws -> MaintenanceTask {
        return try dbQueue.write { db in
            guard var task = try MaintenanceTask.fetchOne(db, key: id) else {
                throw RepositoryError.notFound
            }

            task.status = MaintenanceTask.TaskStatus.pending.rawValue
            task.completedAt = nil

            try task.update(db)
            return task
        }
    }

    // MARK: - Query Methods

    func findByAssetId(_ assetId: Int64) throws -> [MaintenanceTask] {
        return try dbQueue.read { db in
            try MaintenanceTask
                .filter(MaintenanceTask.Columns.assetId == assetId)
                .order(MaintenanceTask.Columns.dueDate)
                .fetchAll(db)
        }
    }

    func findByStatus(_ status: String) throws -> [MaintenanceTask] {
        return try dbQueue.read { db in
            try MaintenanceTask
                .filter(MaintenanceTask.Columns.status == status)
                .order(MaintenanceTask.Columns.dueDate)
                .fetchAll(db)
        }
    }

    func findPending() throws -> [MaintenanceTask] {
        return try findByStatus(MaintenanceTask.TaskStatus.pending.rawValue)
    }

    func findCompleted() throws -> [MaintenanceTask] {
        return try findByStatus(MaintenanceTask.TaskStatus.completed.rawValue)
    }

    func findOverdue() throws -> [MaintenanceTask] {
        return try dbQueue.read { db in
            let now = Date()
            return try MaintenanceTask
                .filter(MaintenanceTask.Columns.status != MaintenanceTask.TaskStatus.completed.rawValue)
                .filter(MaintenanceTask.Columns.dueDate != nil)
                .filter(MaintenanceTask.Columns.dueDate < now)
                .order(MaintenanceTask.Columns.dueDate)
                .fetchAll(db)
        }
    }

    func findUpcoming(days: Int = 30) throws -> [MaintenanceTask] {
        return try dbQueue.read { db in
            let now = Date()
            let futureDate = now.addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
            return try MaintenanceTask
                .filter(MaintenanceTask.Columns.status != MaintenanceTask.TaskStatus.completed.rawValue)
                .filter(MaintenanceTask.Columns.dueDate != nil)
                .filter(MaintenanceTask.Columns.dueDate >= now)
                .filter(MaintenanceTask.Columns.dueDate <= futureDate)
                .order(MaintenanceTask.Columns.dueDate)
                .fetchAll(db)
        }
    }

    func findByPriority(_ priority: String) throws -> [MaintenanceTask] {
        return try dbQueue.read { db in
            try MaintenanceTask
                .filter(MaintenanceTask.Columns.priority == priority)
                .filter(MaintenanceTask.Columns.status != MaintenanceTask.TaskStatus.completed.rawValue)
                .order(MaintenanceTask.Columns.dueDate)
                .fetchAll(db)
        }
    }
}
