import Foundation
import GRDB

/// Database service managing SQLite connection and migrations
/// Singleton pattern ensures single database connection
class DatabaseService {

    static let shared = DatabaseService()

    private(set) var dbQueue: DatabaseQueue!

    private init() {}

    // MARK: - Initialization

    /// Initialize database connection
    /// Call this once during app launch (in App.init or SceneDelegate)
    func initialize() throws {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let dbURL = documentsURL.appendingPathComponent("homemaint.db")

        // Create database queue
        dbQueue = try DatabaseQueue(path: dbURL.path)

        // Enable foreign keys (CRITICAL for data integrity)
        try dbQueue.write { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        // Run migrations
        try runMigrations()

        print("✅ Database initialized at: \(dbURL.path)")
    }

    // MARK: - Migrations

    /// Run database migrations
    /// Migrations are idempotent (check before applying)
    private func runMigrations() throws {
        var migrator = DatabaseMigrator()

        // Migration 001: Initial Schema
        migrator.registerMigration("001_initial_schema") { db in
            try createHomesTable(db)
            try createCategoriesTable(db)
            try createLocationsTable(db)
            try createAssetsTable(db)
            try createMaintenanceRecordsTable(db)
            try createTasksTable(db)
            try createServiceProvidersTable(db)
            try createAttachmentsTable(db)
        }

        // Migration 002: Add indexes for performance
        migrator.registerMigration("002_add_indexes") { db in
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_assets_home_id ON assets(home_id);
                CREATE INDEX IF NOT EXISTS idx_assets_category_id ON assets(category_id);
                CREATE INDEX IF NOT EXISTS idx_assets_location_id ON assets(location_id);
                CREATE INDEX IF NOT EXISTS idx_maintenance_records_asset_id ON maintenance_records(asset_id);
                CREATE INDEX IF NOT EXISTS idx_tasks_asset_id ON tasks(asset_id);
                CREATE INDEX IF NOT EXISTS idx_attachments_asset_id ON attachments(asset_id);
            """)
        }

        // Run migrations
        try migrator.migrate(dbQueue)
    }

    // MARK: - Schema Creation

    private func createHomesTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS homes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                address TEXT,
                purchase_date TEXT,
                square_footage INTEGER,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
    }

    private func createCategoriesTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                home_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                icon TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (home_id) REFERENCES homes(id) ON DELETE CASCADE
            )
        """)
    }

    private func createLocationsTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS locations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                home_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                floor TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (home_id) REFERENCES homes(id) ON DELETE CASCADE
            )
        """)
    }

    private func createAssetsTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS assets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                home_id INTEGER NOT NULL,
                category_id INTEGER,
                location_id INTEGER,
                name TEXT NOT NULL,
                manufacturer TEXT,
                model_number TEXT,
                serial_number TEXT,
                purchase_date TEXT,
                installation_date TEXT,
                warranty_expiration TEXT,
                notes TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (home_id) REFERENCES homes(id) ON DELETE CASCADE,
                FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
                FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL
            )
        """)
    }

    private func createMaintenanceRecordsTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS maintenance_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                asset_id INTEGER NOT NULL,
                service_provider_id INTEGER,
                date TEXT NOT NULL,
                type TEXT NOT NULL,
                description TEXT,
                cost TEXT,
                notes TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
                FOREIGN KEY (service_provider_id) REFERENCES service_providers(id) ON DELETE SET NULL
            )
        """)
    }

    private func createTasksTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                asset_id INTEGER,
                title TEXT NOT NULL,
                description TEXT,
                due_date TEXT,
                priority TEXT,
                status TEXT NOT NULL DEFAULT 'pending',
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                completed_at TEXT,
                FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
            )
        """)
    }

    private func createServiceProvidersTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS service_providers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                home_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                company TEXT,
                phone TEXT,
                email TEXT,
                specialty TEXT,
                notes TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (home_id) REFERENCES homes(id) ON DELETE CASCADE
            )
        """)
    }

    private func createAttachmentsTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS attachments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                asset_id INTEGER,
                maintenance_record_id INTEGER,
                type TEXT NOT NULL,
                filename TEXT NOT NULL,
                relative_path TEXT NOT NULL,
                file_size INTEGER,
                mime_type TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
                FOREIGN KEY (maintenance_record_id) REFERENCES maintenance_records(id) ON DELETE CASCADE
            )
        """)
    }

    // MARK: - Database Maintenance

    /// Optimize database (ANALYZE + VACUUM)
    func optimize() throws {
        try dbQueue.write { db in
            try db.execute(sql: "ANALYZE")
            try db.execute(sql: "VACUUM")
        }
        print("✅ Database optimized")
    }

    /// Check database integrity
    func checkIntegrity() throws -> Bool {
        return try dbQueue.read { db in
            let result = try String.fetchOne(db, sql: "PRAGMA integrity_check")
            return result == "ok"
        }
    }

    /// Reset all data (for testing or "Reset All Data" feature)
    /// SAFE: Uses SQL operations, not file deletion
    func resetAllData() throws {
        try dbQueue.write { db in
            // Delete in reverse order of dependencies
            try db.execute(sql: "DELETE FROM attachments")
            try db.execute(sql: "DELETE FROM tasks")
            try db.execute(sql: "DELETE FROM maintenance_records")
            try db.execute(sql: "DELETE FROM service_providers")
            try db.execute(sql: "DELETE FROM assets")
            try db.execute(sql: "DELETE FROM locations")
            try db.execute(sql: "DELETE FROM categories")
            try db.execute(sql: "DELETE FROM homes")

            // Reset auto-increment counters
            try db.execute(sql: "DELETE FROM sqlite_sequence")

            // Reclaim space
            try db.execute(sql: "VACUUM")
        }
        print("✅ All data reset")
    }
}

// MARK: - Database Errors

enum DatabaseError: Error {
    case notInitialized
    case migrationFailed(String)
    case integrityCheckFailed
}
