import Foundation
import GRDB

/// MaintenanceTask model for upcoming maintenance
struct MaintenanceTask: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {

    var id: Int64?
    var assetId: Int64?
    var title: String
    var description: String?
    var dueDate: Date?
    var priority: String?
    var status: String
    var createdAt: Date
    var completedAt: Date?

    // MARK: - GRDB Configuration

    static let databaseTableName = "tasks"

    enum Columns: String, ColumnExpression {
        case id
        case assetId = "asset_id"
        case title, description
        case dueDate = "due_date"
        case priority, status
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case assetId = "asset_id"
        case title, description
        case dueDate = "due_date"
        case priority, status
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }

    // MARK: - Relationships

    static let asset = belongsTo(Asset.self)

    // MARK: - Initialization

    init(
        id: Int64? = nil,
        assetId: Int64? = nil,
        title: String,
        description: String? = nil,
        dueDate: Date? = nil,
        priority: String? = nil,
        status: String = TaskStatus.pending.rawValue,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.assetId = assetId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    // MARK: - Computed Properties

    var isOverdue: Bool {
        guard let due = dueDate, status != TaskStatus.completed.rawValue else {
            return false
        }
        return due < Date()
    }

    var isCompleted: Bool {
        return status == TaskStatus.completed.rawValue
    }

    var priorityEnum: TaskPriority? {
        guard let priority = priority else { return nil }
        return TaskPriority(rawValue: priority)
    }

    var statusEnum: TaskStatus {
        return TaskStatus(rawValue: status) ?? .pending
    }

    // MARK: - Enums

    enum TaskStatus: String, CaseIterable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"

        var displayText: String {
            switch self {
            case .pending: return "Pending"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }
    }

    enum TaskPriority: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"

        var displayText: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }

        var color: String {
            switch self {
            case .low: return "blue"
            case .medium: return "yellow"
            case .high: return "orange"
            case .urgent: return "red"
            }
        }
    }

    // MARK: - GRDB Insertion

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

}
