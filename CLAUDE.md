# HomeMaint Mobile - AI Development Guidelines

This document provides guidance for AI assistants working on the HomeMaint Mobile iOS project.

## Project Overview

**What:** Native iOS mobile app for home maintenance and asset tracking

**Why:** Provide homeowners with on-the-go access to their home maintenance records, enabling quick photo capture of assets, maintenance logging, and task management from iPhone/iPad

**Who:** Homeowners who want mobile-first home maintenance tracking (companion to HomeMaint web app)

**Status:** MVP - Initial Development

**Tech Stack:**
- Framework: SwiftUI (iOS 17+)
- Language: Swift 5.9+
- Database: SQLite (GRDB.swift or SQLite.swift)
- Testing: XCTest with XCUITest
- Deployment: TestFlight → App Store

---

## Architecture Decisions

### Patterns Used

**Repository Pattern** - Testable data access abstraction
- **Reason:** Same pattern as HomeMaint web app. Enables 85%+ test coverage, clean separation between UI and database, and swappable data sources (could add CloudKit/sync later)
- **Location:** `HomeMaintMobile/Repositories/`
- **Evidence:** HomeMaint web (115/115 unit tests passing, Grade A project)
- **Reference:** Dev-Vault-R/04 Resources/Knowledge-Base/Techniques-Patterns/SQLite-Repository-Pattern.md

**MVVM (Model-View-ViewModel)** - SwiftUI architectural pattern
- **Reason:** Native iOS pattern, pairs perfectly with SwiftUI + Combine, ViewModels use repositories for data access
- **Location:** `HomeMaintMobile/ViewModels/`, `HomeMaintMobile/Views/`
- **Evidence:** iOS best practice, testable business logic

### Patterns NOT Used (and Why)

**Provider Pattern** - Rejected
- **Reason:** Single data source (local SQLite only). Provider Pattern is for 4+ data sources (multiple APIs/blockchains)
- **Considered on:** 2025-10-26
- **Decision:** Rejected (over-engineering for single database)

**Three-Layer Architecture** - Rejected
- **Reason:** Not porting to other platforms. iOS-only app. Three-Layer is for cross-platform code reuse (Python → Swift)
- **Considered on:** 2025-10-26
- **Decision:** Rejected (web app is separate codebase)

**CoreData** - Rejected (for now)
- **Reason:** SQLite with Repository Pattern is simpler, matches web app schema, easier migration path. Can switch to CoreData later if needed
- **Considered on:** 2025-10-26
- **Decision:** Deferred (use SQLite + GRDB.swift)

---

## Directory Structure

```
HomeMaintMobile/
├── HomeMaintMobile/
│   ├── Models/              # Data models (Asset, MaintenanceRecord, Task, etc.)
│   ├── Repositories/        # Repository Pattern implementation
│   │   ├── BaseRepository.swift
│   │   ├── AssetRepository.swift
│   │   ├── MaintenanceRepository.swift
│   │   ├── TaskRepository.swift
│   │   ├── DocumentRepository.swift
│   │   └── ServiceProviderRepository.swift
│   ├── ViewModels/          # MVVM ViewModels (use repositories)
│   │   ├── AssetListViewModel.swift
│   │   ├── AssetDetailViewModel.swift
│   │   └── ...
│   ├── Views/               # SwiftUI Views (never access DB directly)
│   │   ├── Assets/
│   │   ├── Maintenance/
│   │   ├── Tasks/
│   │   ├── Documents/
│   │   └── Settings/
│   ├── Services/            # Utility services
│   │   ├── DatabaseService.swift    # SQLite connection + migrations
│   │   ├── FileStorageService.swift # Photo/document storage
│   │   └── CameraService.swift      # Camera integration
│   ├── Utils/               # Extensions, helpers
│   └── HomeMaintMobileApp.swift
├── HomeMaintMobileTests/    # Unit tests (mirror source structure)
│   ├── Repositories/        # Test repositories (90%+ coverage)
│   ├── ViewModels/          # Test ViewModels (85%+ coverage)
│   └── Models/              # Test model validation
├── HomeMaintMobileUITests/  # UI tests (critical user flows)
└── docs/                    # Project documentation
```

**Key Directories:**
- `Models/` - Swift structs matching web app's database schema
- `Repositories/` - All database access (CRUD operations)
- `ViewModels/` - Business logic, uses repositories, publishes to views
- `Views/` - SwiftUI UI only, observes ViewModels
- `Services/` - DatabaseService (migrations), FileStorageService (photos)

---

## Testing Strategy

### Coverage Targets

**Overall Minimum:** 85%
**By Layer:**
- Repositories: 90%+
- ViewModels: 85%+
- Models: 80%+
- Views: 70%+
- Services: 85%+

**Why 85% Coverage:**
> "85%+ test coverage enabled 30+ autonomous AI PRs with zero regressions" (HomeMaint web app)

Without 85% coverage, HomeMaint Mobile loses its ability to support autonomous AI development.

### Running Tests

```bash
# Run all unit tests
xcodebuild test -scheme HomeMaintMobile -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests with coverage
xcodebuild test -scheme HomeMaintMobile -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES

# Run UI tests
xcodebuild test -scheme HomeMaintMobile -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:HomeMaintMobileUITests

# View coverage report
# Xcode → Product → Show Build Folder → Coverage Report
```

### CI/CD

- All tests must pass before merge
- Coverage cannot decrease below 85%
- UI tests run on every PR
- Build must succeed for release configuration

---

## Development Workflow

### Getting Started

```bash
# Clone repository
git clone <repo-url>
cd HomeMaintMobile

# Install dependencies (SPM auto-resolves on first build)
open HomeMaintMobile.xcodeproj

# Run project
# Xcode → Product → Run (⌘R)

# Run tests
# Xcode → Product → Test (⌘U)
```

### Common Tasks

**Adding a new feature:**
1. Write tests first in `HomeMaintMobileTests/`
2. Implement feature following Repository + MVVM pattern
3. Verify tests pass (⌘U)
4. Check coverage in Xcode (must be ≥ 85%)
5. Update this CLAUDE.md if architecture changes

**Adding a new table/model:**
1. Create migration in `DatabaseService.swift`
2. Create model in `Models/` (struct conforming to Codable)
3. Create repository in `Repositories/` (extend `BaseRepository`)
4. Create ViewModel in `ViewModels/` (uses repository)
5. Create View in `Views/` (observes ViewModel)
6. Add tests for all layers

**Capturing photos:**
1. Use `CameraService` (wraps UIImagePickerController)
2. Save via `FileStorageService` (hash-based deduplication)
3. Store file path in SQLite via `DocumentRepository`

---

## Key Files

**Critical files to understand:**
- `HomeMaintMobileApp.swift` - App entry point, dependency injection
- `Services/DatabaseService.swift` - SQLite connection, migrations, schema
- `Repositories/BaseRepository.swift` - Abstract base for all repositories
- `Models/` - Data models matching web app schema
- `ViewModels/` - Business logic layer

**Configuration:**
- `Info.plist` - App configuration, permissions (camera, photo library)
- `HomeMaintMobile.xcodeproj` - Xcode project settings
- `.gitignore` - Exclude build artifacts, user data

---

## What NOT to Do (Anti-Patterns)

### ❌ No Direct Database Access in Views/ViewModels
- **Don't:** Call SQLite directly from SwiftUI views or ViewModels
- **Do:** Always use repositories for data access
- **Why:** Testability, swappable data sources, clean architecture
- **Example (BAD):**
  ```swift
  // ❌ In ViewModel - couples to SQLite!
  let db = try Connection("path/to/db.sqlite3")
  let assets = try db.prepare(assetsTable).map { ... }
  ```
- **Example (GOOD):**
  ```swift
  // ✅ In ViewModel - uses repository
  let assets = assetRepository.findAll()
  ```

### ❌ No Float/Double for Money or Measurements
- **Don't:** Use `Float` or `Double` for currency or precise measurements
- **Do:** Use `Decimal` type for precision
- **Why:** Floating point errors accumulate (e.g., $0.10 + $0.20 ≠ $0.30)
- **Example (BAD):**
  ```swift
  // ❌ Float loses precision!
  let cost: Float = 299.99
  ```
- **Example (GOOD):**
  ```swift
  // ✅ Decimal preserves precision
  let cost: Decimal = 299.99
  ```

### ❌ No Storing Secrets in UserDefaults
- **Don't:** Store sensitive data in UserDefaults (unencrypted)
- **Do:** Use Keychain for sensitive data (API keys, tokens, etc.)
- **Why:** UserDefaults is not encrypted, accessible by other apps
- **Example (BAD):**
  ```swift
  // ❌ Exposes sensitive data!
  UserDefaults.standard.set(apiKey, forKey: "api_key")
  ```
- **Example (GOOD):**
  ```swift
  // ✅ Keychain is encrypted
  try keychain.set(apiKey, key: "api_key")
  ```

### ❌ No Massive ViewModels
- **Don't:** Put all business logic in one massive ViewModel
- **Do:** Keep ViewModels focused (one per view/feature), delegate to repositories
- **Why:** Testability, maintainability, single responsibility
- **Example:** AssetListViewModel handles list logic, AssetDetailViewModel handles detail logic

### ❌ No Deleting Active Database Files
- **Don't:** Delete SQLite files while app is running
- **Do:** Use SQL operations to clear data (DELETE + VACUUM)
- **Why:** Crashes app, corrupts database connection
- **Evidence:** HomeMaint web discovered this (Oct 26, 2025)
- **Example (BAD):**
  ```swift
  // ❌ Crashes app!
  try FileManager.default.removeItem(at: dbURL)
  ```
- **Example (GOOD):**
  ```swift
  // ✅ Safe SQL operations
  try db.run("DELETE FROM assets")
  try db.run("DELETE FROM sqlite_sequence")
  try db.run("VACUUM")
  ```

### ❌ No Missing Error Handling
- **Don't:** Silent failures, empty catch blocks
- **Do:** Log errors with context, show user-friendly messages
- **Why:** Debugging impossible without logs, poor UX
- **Example (BAD):**
  ```swift
  // ❌ Silent failure!
  do {
    try saveAsset(asset)
  } catch {}
  ```
- **Example (GOOD):**
  ```swift
  // ✅ Logs context, informs user
  do {
    try saveAsset(asset)
  } catch {
    print("Failed to save asset \(asset.id): \(error)")
    showError("Could not save asset. Please try again.")
  }
  ```

---

## Domain-Specific Guidance

### Mobile Apps: Security & Performance

**Sensitive Data:**
- Camera permissions: Request only when needed (NSCameraUsageDescription in Info.plist)
- Photo library: Request read/write access (NSPhotoLibraryUsageDescription)
- Database encryption: Consider SQLCipher for sensitive data
- Keychain: Use for any secrets (future API keys, sync tokens)

**Photo Storage:**
- Hash-based deduplication (SHA-256, matches web app)
- Store in app's Documents directory (backed up to iCloud)
- Max file size: 50MB per photo (configurable)
- Compression: JPEG 0.8 quality for reasonable size

**Performance:**
- Lazy loading: Load data as needed (not all at once)
- Image caching: Cache thumbnails in memory
- Background tasks: Use DispatchQueue for database operations
- SwiftUI: Use @State, @StateObject, @ObservedObject appropriately

**Offline-First:**
- All features work without network (local SQLite)
- Future: Sync when network available (deferred)

---

## Database Schema

### Migrations

**Location:** `Services/DatabaseService.swift` (migrations array)

**Adding New Migration:**

```swift
// In DatabaseService.swift
func runMigrations() throws {
    let migrations: [(version: Int, name: String, execute: (Connection) throws -> Void)] = [
        (1, "initial_schema", migration_001_initial_schema),
        (2, "add_feature", migration_002_add_feature), // New migration
    ]

    // Migration execution logic...
}

private func migration_002_add_feature(_ db: Connection) throws {
    // Check if table/column exists first (idempotent)
    try db.run("""
        CREATE TABLE IF NOT EXISTS new_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """)
}
```

### Schema Compatibility with Web App

**Critical:** HomeMaint Mobile must use the **same schema** as HomeMaint web for future data portability (import/export).

**Core Tables (match web app):**
- `homes` - Home/property information
- `categories` - Asset categories (HVAC, Plumbing, etc.)
- `locations` - Rooms/areas
- `assets` - Systems, appliances, equipment
- `maintenance_records` - Service history
- `tasks` - Upcoming maintenance
- `service_providers` - Contractor contacts
- `attachments` - Documents, photos, manuals

**Simplified for MVP:**
- Single home only (web app supports multiple)
- Removed: Multi-home features, advanced analytics

**Data Types:**
- Dates: TEXT in ISO-8601 format (`YYYY-MM-DD` or `YYYY-MM-DD HH:MM:SS`)
- Booleans: INTEGER (0 = false, 1 = true)
- Currency: TEXT (store as Decimal string: "299.99")

---

## iOS-Specific Features

### Camera Integration

```swift
// Use CameraService
@Published var selectedImage: UIImage?

func capturePhoto() {
    cameraService.presentCamera { image in
        self.selectedImage = image
        self.savePhoto(image)
    }
}
```

### File Storage

```swift
// Use FileStorageService
func savePhoto(_ image: UIImage) async throws {
    guard let data = image.jpegData(compressionQuality: 0.8) else { return }

    let relativePath = try await fileStorageService.storeFile(
        data: data,
        mimeType: "image/jpeg",
        originalFilename: "asset_photo.jpg"
    )

    // Save path to database via DocumentRepository
    let document = Document(
        assetId: assetId,
        type: .photo,
        relativePath: relativePath,
        filename: "asset_photo.jpg"
    )
    try documentRepository.create(document)
}
```

### Universal App (iPhone + iPad)

- Use adaptive layouts (`.navigationViewStyle(.stack)` for iPhone, `.columns` for iPad)
- Support all orientations (portrait, landscape)
- Optimize for large screens (iPad split view, multitasking)
- Test on multiple devices (iPhone 15, iPad Pro)

---

## Architecture Evolution

### Version 1.0 (MVP - Current)

**Built:** 2025-10-26
**Focus:** Core features for single home
**Key Decisions:**
- Repository Pattern (matches web app)
- SwiftUI + MVVM (native iOS)
- Local SQLite only (no sync)
- Single home support (simplified scope)
- Camera integration for asset photos

**Scope:**
- ✅ Asset tracking (view, add, edit, delete)
- ✅ Maintenance records (log service history)
- ✅ Tasks (upcoming maintenance)
- ✅ Documents/photos (attach to assets)
- ✅ Service providers (contractor contacts)
- ✅ Dashboard (quick overview)

**Deferred:**
- Multi-home support
- Data sync with web app
- Recurring task automation
- Warranty expiration alerts
- Advanced analytics

### Future (Planned)

**Version 1.1 - Data Sync:**
- iCloud sync (or custom API)
- Import/export from web app
- Conflict resolution

**Version 2.0 - Advanced Features:**
- Multi-home support
- Recurring tasks with reminders
- Push notifications (warranty expirations)
- Siri shortcuts ("Show me recent maintenance")
- Widgets (upcoming tasks)

**Timeline:** TBD based on MVP feedback

---

## Success Metrics

**Technical Metrics:**
- Test coverage: > 85%
- Build time: < 2 minutes
- App size: < 50MB
- Crash-free rate: > 99%

**Product Metrics:**
- Feature completion (MVP scope)
- Bug count (< 5 critical bugs at launch)
- Performance (60 FPS UI, < 1s database queries)
- App Store rating: > 4.5 stars (target)

---

## AI Development Notes

### What AI Can Do Autonomously

- Implement new repositories (following BaseRepository pattern)
- Create ViewModels (using repositories)
- Build SwiftUI views (observing ViewModels)
- Write unit tests (matching existing test patterns)
- Add database migrations (idempotent, following schema)
- Implement camera/photo features (using existing services)

### What Requires Human Review

- Architecture changes (new patterns)
- Security decisions (Keychain usage, encryption)
- UX decisions (navigation flow, interaction design)
- App Store submission (screenshots, description, pricing)
- Privacy policy (data collection, usage)
- Third-party SDK integration (analytics, crash reporting)

### AI Workflow

1. Read this CLAUDE.md before starting
2. Follow Repository + MVVM pattern
3. Test-first development (write XCTest, then code)
4. Check coverage after each feature (must be ≥ 85%)
5. Run full test suite before committing
6. Update CLAUDE.md if architecture changes

---

## Questions & Troubleshooting

### Common Issues

**Issue:** "No such table" error
**Solution:** Check DatabaseService migrations ran successfully. Delete app and reinstall to force fresh migration.

**Issue:** "Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value"
**Solution:** Check repository method returns optional. Use `if let` or `guard let` to safely unwrap.

**Issue:** "Cannot find 'assetRepository' in scope"
**Solution:** Ensure repository is injected via dependency injection in App initialization or ViewModel init.

**Issue:** Tests fail on CI but pass locally
**Solution:** Ensure simulator matches (same iOS version, device type). Check test database is created fresh for each test.

### Getting Help

- Documentation: `docs/`
- Web App Reference: HomeMaint web app CLAUDE.md (same patterns)
- Examples: `HomeMaintMobileTests/` (test fixtures show usage)
- Patterns: Dev-Vault-R/04 Resources/Knowledge-Base/Techniques-Patterns/

---

## References

**Web App (HomeMaint):**
- Repository: https://github.com/cjnemes/HomeMaint
- CLAUDE.md: Follow same patterns, anti-patterns, testing strategy
- Schema: Match database schema for data portability

**External Resources:**
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [GRDB.swift](https://github.com/groue/GRDB.swift) (SQLite toolkit)
- [Swift Testing](https://developer.apple.com/documentation/xctest)

**Dev-Vault References:**
- Repository Pattern: Dev-Vault-R/04 Resources/Knowledge-Base/Techniques-Patterns/SQLite-Repository-Pattern.md
- Anti-Patterns: Dev-Vault-R/QUICK-START-GUIDE.md
- HomeMaint Case Study: Dev-Vault-R/02 Projects/Completed-Projects/HomeMaint-Case-Study.md

---

## Tags

`#ios` `#swift` `#swiftui` `#sqlite` `#repository-pattern` `#mvvm` `#mobile` `#home-maintenance`

---

**Last Updated:** 2025-10-26
**Version:** 1.0.0-MVP
**Created By:** AI-assisted development following Dev-Vault standards
