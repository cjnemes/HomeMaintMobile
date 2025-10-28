import XCTest
@testable import HomeMaintMobile
import GRDB

final class DatabaseServiceTests: XCTestCase {

    var databaseService: DatabaseService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        databaseService = DatabaseService.shared
    }

    override func tearDownWithError() throws {
        // Clean up test data
        try? DatabaseService.shared.resetAllData()
        databaseService = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInitialize_InMemoryDatabase_ShouldSucceed() throws {
        // When
        try databaseService.initialize(inMemory: true)

        // Then
        XCTAssertNotNil(databaseService.dbQueue)
    }

    func testInitialize_ForeignKeysEnabled_ShouldBeOn() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        // When
        let foreignKeysEnabled = try databaseService.dbQueue.read { db in
            try Bool.fetchOne(db, sql: "PRAGMA foreign_keys") ?? false
        }

        // Then
        XCTAssertTrue(foreignKeysEnabled, "Foreign keys should be enabled")
    }

    // MARK: - Migration Tests

    func testMigration001_InitialSchema_CreatesAllTables() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        // When/Then - Check all tables exist
        try databaseService.dbQueue.read { db in
            // Check homes table
            let homesExists = try db.tableExists("homes")
            XCTAssertTrue(homesExists, "homes table should exist")

            // Check categories table
            let categoriesExists = try db.tableExists("categories")
            XCTAssertTrue(categoriesExists, "categories table should exist")

            // Check locations table
            let locationsExists = try db.tableExists("locations")
            XCTAssertTrue(locationsExists, "locations table should exist")

            // Check assets table
            let assetsExists = try db.tableExists("assets")
            XCTAssertTrue(assetsExists, "assets table should exist")

            // Check maintenance_records table
            let maintenanceExists = try db.tableExists("maintenance_records")
            XCTAssertTrue(maintenanceExists, "maintenance_records table should exist")

            // Check tasks table
            let tasksExists = try db.tableExists("tasks")
            XCTAssertTrue(tasksExists, "tasks table should exist")

            // Check service_providers table
            let providersExists = try db.tableExists("service_providers")
            XCTAssertTrue(providersExists, "service_providers table should exist")

            // Check attachments table
            let attachmentsExists = try db.tableExists("attachments")
            XCTAssertTrue(attachmentsExists, "attachments table should exist")
        }
    }

    func testMigration002_AddIndexes_CreatesPerformanceIndexes() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        // When/Then - Check indexes exist
        try databaseService.dbQueue.read { db in
            // Check index on assets.home_id
            let assetsHomeIdIndex = try db.indexExists("idx_assets_home_id")
            XCTAssertTrue(assetsHomeIdIndex, "Index on assets.home_id should exist")

            // Check index on assets.category_id
            let assetsCategoryIdIndex = try db.indexExists("idx_assets_category_id")
            XCTAssertTrue(assetsCategoryIdIndex, "Index on assets.category_id should exist")

            // Check index on assets.location_id
            let assetsLocationIdIndex = try db.indexExists("idx_assets_location_id")
            XCTAssertTrue(assetsLocationIdIndex, "Index on assets.location_id should exist")

            // Check index on maintenance_records.asset_id
            let maintenanceAssetIdIndex = try db.indexExists("idx_maintenance_records_asset_id")
            XCTAssertTrue(maintenanceAssetIdIndex, "Index on maintenance_records.asset_id should exist")

            // Check index on tasks.asset_id
            let tasksAssetIdIndex = try db.indexExists("idx_tasks_asset_id")
            XCTAssertTrue(tasksAssetIdIndex, "Index on tasks.asset_id should exist")

            // Check index on attachments.asset_id
            let attachmentsAssetIdIndex = try db.indexExists("idx_attachments_asset_id")
            XCTAssertTrue(attachmentsAssetIdIndex, "Index on attachments.asset_id should exist")
        }
    }

    func testMigration003_ServiceProvidersUpdate_CompanyIsMandatory() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        // When/Then - Check service_providers table structure
        try databaseService.dbQueue.read { db in
            let columns = try db.columns(in: "service_providers")

            // Find company column
            guard let companyColumn = columns.first(where: { $0.name == "company" }) else {
                XCTFail("company column should exist")
                return
            }

            // Find name column
            guard let nameColumn = columns.first(where: { $0.name == "name" }) else {
                XCTFail("name column should exist")
                return
            }

            // Check company is NOT NULL
            XCTAssertFalse(companyColumn.isNullable, "company column should be NOT NULL")

            // Check name is nullable
            XCTAssertTrue(nameColumn.isNullable, "name column should be nullable")
        }
    }

    // MARK: - Schema Validation Tests

    func testHomesTable_HasCorrectSchema() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        // When/Then
        try databaseService.dbQueue.read { db in
            let columns = try db.columns(in: "homes")
            let columnNames = columns.map { $0.name }

            XCTAssertTrue(columnNames.contains("id"))
            XCTAssertTrue(columnNames.contains("name"))
            XCTAssertTrue(columnNames.contains("address"))
            XCTAssertTrue(columnNames.contains("purchase_date"))
            XCTAssertTrue(columnNames.contains("square_footage"))
            XCTAssertTrue(columnNames.contains("created_at"))
            XCTAssertTrue(columnNames.contains("updated_at"))
        }
    }

    func testAssetsTable_HasCorrectForeignKeys() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        // When/Then
        try databaseService.dbQueue.read { db in
            let foreignKeys = try db.foreignKeys(on: "assets")

            // Should have foreign keys to homes, categories, and locations
            XCTAssertTrue(foreignKeys.contains { $0.destinationTable == "homes" })
            XCTAssertTrue(foreignKeys.contains { $0.destinationTable == "categories" })
            XCTAssertTrue(foreignKeys.contains { $0.destinationTable == "locations" })
        }
    }

    func testMaintenanceRecordsTable_HasCorrectForeignKeys() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        // When/Then
        try databaseService.dbQueue.read { db in
            let foreignKeys = try db.foreignKeys(on: "maintenance_records")

            // Should have foreign keys to assets and service_providers
            XCTAssertTrue(foreignKeys.contains { $0.destinationTable == "assets" })
            XCTAssertTrue(foreignKeys.contains { $0.destinationTable == "service_providers" })
        }
    }

    // MARK: - Data Integrity Tests

    func testForeignKeyConstraint_DeleteHome_CascadesToAssets() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        try databaseService.dbQueue.write { db in
            // Create home
            try db.execute(sql: "INSERT INTO homes (name) VALUES ('Test Home')")
            let homeId = db.lastInsertedRowID

            // Create asset for the home
            try db.execute(sql: """
                INSERT INTO assets (home_id, name)
                VALUES (?, 'Test Asset')
            """, arguments: [homeId])

            // Verify asset exists
            let assetCountBefore = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM assets") ?? 0
            XCTAssertEqual(assetCountBefore, 1)

            // When - Delete home
            try db.execute(sql: "DELETE FROM homes WHERE id = ?", arguments: [homeId])

            // Then - Asset should be deleted (CASCADE)
            let assetCountAfter = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM assets") ?? 0
            XCTAssertEqual(assetCountAfter, 0)
        }
    }

    func testForeignKeyConstraint_DeleteCategory_SetsNullInAssets() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        try databaseService.dbQueue.write { db in
            // Create home and category
            try db.execute(sql: "INSERT INTO homes (name) VALUES ('Test Home')")
            let homeId = db.lastInsertedRowID

            try db.execute(sql: """
                INSERT INTO categories (home_id, name)
                VALUES (?, 'Test Category')
            """, arguments: [homeId])
            let categoryId = db.lastInsertedRowID

            // Create asset with category
            try db.execute(sql: """
                INSERT INTO assets (home_id, category_id, name)
                VALUES (?, ?, 'Test Asset')
            """, arguments: [homeId, categoryId])

            // Verify asset has category
            let categoryBefore = try Int64?.fetchOne(db, sql: """
                SELECT category_id FROM assets WHERE name = 'Test Asset'
            """)
            XCTAssertEqual(categoryBefore, categoryId)

            // When - Delete category
            try db.execute(sql: "DELETE FROM categories WHERE id = ?", arguments: [categoryId])

            // Then - Asset should still exist but category_id should be NULL (SET NULL)
            let assetExists = try Bool.fetchOne(db, sql: """
                SELECT EXISTS(SELECT 1 FROM assets WHERE name = 'Test Asset')
            """) ?? false
            XCTAssertTrue(assetExists)

            let categoryAfter = try Int64?.fetchOne(db, sql: """
                SELECT category_id FROM assets WHERE name = 'Test Asset'
            """)
            XCTAssertNil(categoryAfter)
        }
    }

    // MARK: - Migration Idempotency Tests

    func testMigrations_RunMultipleTimes_ShouldBeIdempotent() throws {
        // Given/When - Initialize multiple times
        try databaseService.initialize(inMemory: true)
        try databaseService.initialize(inMemory: true)
        try databaseService.initialize(inMemory: true)

        // Then - Should still work correctly
        try databaseService.dbQueue.read { db in
            let homesExists = try db.tableExists("homes")
            XCTAssertTrue(homesExists)
        }
    }

    // MARK: - Reset Data Tests

    func testResetAllData_ShouldClearAllTables() throws {
        // Given
        try databaseService.initialize(inMemory: true)

        // Add some data
        try databaseService.dbQueue.write { db in
            try db.execute(sql: "INSERT INTO homes (name) VALUES ('Test Home')")
            let homeId = db.lastInsertedRowID

            try db.execute(sql: """
                INSERT INTO assets (home_id, name)
                VALUES (?, 'Test Asset')
            """, arguments: [homeId])
        }

        // Verify data exists
        let countBefore = try databaseService.dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM homes") ?? 0
        }
        XCTAssertGreaterThan(countBefore, 0)

        // When
        try databaseService.resetAllData()

        // Then - All data should be cleared
        let countAfter = try databaseService.dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM homes") ?? 0
        }
        XCTAssertEqual(countAfter, 0)

        let assetCount = try databaseService.dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM assets") ?? 0
        }
        XCTAssertEqual(assetCount, 0)
    }
}

// MARK: - Helper Extensions for Testing

extension Database {
    func tableExists(_ tableName: String) throws -> Bool {
        return try Bool.fetchOne(self, sql: """
            SELECT EXISTS(
                SELECT 1 FROM sqlite_master
                WHERE type='table' AND name=?
            )
        """, arguments: [tableName]) ?? false
    }

    func indexExists(_ indexName: String) throws -> Bool {
        return try Bool.fetchOne(self, sql: """
            SELECT EXISTS(
                SELECT 1 FROM sqlite_master
                WHERE type='index' AND name=?
            )
        """, arguments: [indexName]) ?? false
    }
}