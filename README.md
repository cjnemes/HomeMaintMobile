# HomeMaint Mobile

A comprehensive iOS mobile app for home maintenance and asset tracking, designed to help homeowners manage their property maintenance records, schedule tasks, and track service providers.

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

### Core Functionality
- **Asset Management** - Track all home systems, appliances, and equipment
- **Maintenance Records** - Log all service history with costs and notes
- **Task Scheduling** - Create and manage upcoming maintenance tasks
- **Service Providers** - Maintain contact information for contractors and service companies
- **Dashboard** - Quick overview of your home maintenance status

### Key Capabilities
- ✅ Full CRUD operations for all entities
- ✅ Smart filtering and search
- ✅ Category and location organization
- ✅ Priority levels for tasks
- ✅ Cost tracking with Decimal precision
- ✅ Overdue task detection
- ✅ Offline-first architecture (local SQLite database)

## Screenshots

_(Coming soon - screenshots will be added after UI polish)_

## Installation

### Requirements
- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/cjnemes/HomeMaintMobile.git
   cd HomeMaintMobile
   ```

2. **Open in Xcode**
   ```bash
   open HomeMaintMobile/HomeMaintMobile.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `⌘R` to build and run
   - Or use: Product → Run

### TestFlight Distribution

_(Instructions will be added when app is published to TestFlight)_

## Quick Start

1. **First Launch**
   - The app automatically creates a default home and seeds categories/locations
   - You'll see the Dashboard with 0 assets, 0 tasks, 0 maintenance records

2. **Add Your First Asset**
   - Tap "Assets" on the Dashboard
   - Tap the "+" button
   - Fill in asset details (name, category, location, etc.)
   - Save

3. **Log Maintenance**
   - Navigate to "Maintenance" from the Dashboard
   - Tap "+" to add a maintenance record
   - Select the asset, add details and cost
   - Save

4. **Create Tasks**
   - Navigate to "Tasks" from the Dashboard
   - Tap "+" to create a new task
   - Set priority, due date, and link to an asset
   - Save

## Technology Stack

- **Framework**: SwiftUI (iOS 17+)
- **Language**: Swift 5.9+
- **Database**: SQLite with [GRDB.swift](https://github.com/groue/GRDB.swift) v7.8.0
- **Architecture**: Repository Pattern + MVVM
- **Testing**: XCTest (85%+ coverage target)

## Project Structure

```
HomeMaintMobile/
├── HomeMaintMobile/
│   ├── Models/              # Data models
│   ├── Repositories/        # Data access layer (Repository Pattern)
│   ├── ViewModels/          # Business logic (MVVM)
│   ├── Views/               # SwiftUI views
│   │   ├── Assets/
│   │   ├── Dashboard/
│   │   ├── Maintenance/
│   │   ├── ServiceProviders/
│   │   └── Tasks/
│   ├── Services/            # Core services (Database, FileStorage)
│   └── Utils/               # Extensions and helpers
├── HomeMaintMobileTests/    # Unit tests (85%+ coverage)
├── CLAUDE.md                # AI development guidelines
├── DEVELOPMENT_ROADMAP.md   # Feature roadmap and planning
└── PRE_RELEASE_CHECKLIST.md # Release readiness checklist
```

## Architecture

HomeMaint Mobile follows best practices from enterprise iOS development:

### Repository Pattern
All database access goes through repository classes that extend `BaseRepository`. This provides:
- Clean separation of concerns
- Testable data access (90%+ repository test coverage)
- Swappable data sources (could add iCloud sync later)

### MVVM (Model-View-ViewModel)
- **Models**: Swift structs conforming to Codable/GRDB protocols
- **ViewModels**: `ObservableObject` classes using repositories
- **Views**: Pure SwiftUI views observing ViewModels

### Test-First Development
- Tests written before/during implementation
- 85%+ overall test coverage maintained
- Critical for autonomous AI development

## Database Schema

### Core Tables
- `homes` - Home/property information
- `categories` - Asset categories (HVAC, Plumbing, etc.)
- `locations` - Rooms and areas
- `assets` - Systems, appliances, equipment
- `maintenance_records` - Service history
- `tasks` - Upcoming maintenance
- `service_providers` - Contractor contacts
- `attachments` - Documents and photos _(Coming soon)_

### Migrations
The app uses a migration system to safely evolve the database schema. Currently at version 3.

## Testing

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme HomeMaintMobile \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run with coverage
xcodebuild test -scheme HomeMaintMobile \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

### Test Coverage
- **Overall Target**: 85%+
- **Repositories**: 90%+
- **ViewModels**: 85%+
- **Current Status**: ✅ Meeting targets

## Development Roadmap

See [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md) for detailed feature planning.

### Phase 1 - MVP Core ✅ Complete
- [x] Database setup with migrations
- [x] Asset management
- [x] Task management
- [x] Service providers
- [x] Maintenance records UI
- [x] Dashboard

### Phase 2 - Advanced Features (In Progress)
- [ ] Camera integration and photo capture
- [ ] Photo/document attachments
- [ ] Attachment management UI

### Phase 3 - Documentation & Release
- [x] GitHub repository setup
- [ ] Comprehensive documentation
- [ ] TestFlight beta distribution

### Phase 4 - Future Enhancements
- [ ] iCloud sync
- [ ] Data export/import
- [ ] Push notifications
- [ ] Recurring task automation
- [ ] Multi-home support

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) _(coming soon)_ for details on:
- Code style guidelines
- Pull request process
- Testing requirements
- Commit message format

## Anti-Patterns Avoided

This project follows strict guidelines to avoid common pitfalls:
- ✅ Uses Decimal for currency (not Float/Double)
- ✅ Repository Pattern for data access (not direct SQL in views)
- ✅ Proper error handling (no silent failures)
- ✅ Safe database operations (SQL operations, not file deletion)
- ✅ Keychain for sensitive data (not UserDefaults)

See [CLAUDE.md](CLAUDE.md) for full development guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [GRDB.swift](https://github.com/groue/GRDB.swift) by Gwendal Roué
- Architecture inspired by the HomeMaint web app
- Developed following AI-assisted development best practices

## Contact

**Chris Nemes**
- GitHub: [@cjnemes](https://github.com/cjnemes)
- Project Link: [https://github.com/cjnemes/HomeMaintMobile](https://github.com/cjnemes/HomeMaintMobile)

---

**Status**: Active Development | **Version**: 1.0.0-MVP | **Last Updated**: October 26, 2025
