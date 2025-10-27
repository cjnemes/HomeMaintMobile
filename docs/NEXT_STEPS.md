# Next Steps - HomeMaint Mobile Development

After completing the Xcode project setup, follow these steps to build your iOS app.

## Phase 1: Foundation (Week 1)

### Day 1-2: Database & Repositories

**Goal:** Complete database layer with full test coverage

1. **Verify Database Setup**
   ```bash
   # Run app in simulator
   # Check console for: "✅ Database initialized at: [path]"
   # Verify homemaint.db file created in Documents directory
   ```

2. **Create AssetRepository**
   - File: `Repositories/AssetRepository.swift`
   - Extend `BaseRepository<Asset>`
   - Implement CRUD operations
   - Add custom queries: `findByHomeId`, `findByCategoryId`, etc.

3. **Write Tests (CRITICAL - 90%+ coverage)**
   - File: `HomeMaintMobileTests/Repositories/AssetRepositoryTests.swift`
   - Test all CRUD operations
   - Test edge cases (empty DB, invalid IDs, etc.)
   - Test custom queries

4. **Create Additional Repositories**
   - `MaintenanceRecordRepository`
   - `TaskRepository`
   - `ServiceProviderRepository`
   - `CategoryRepository`
   - `LocationRepository`
   - Each with 90%+ test coverage

**Completion Criteria:**
- ✅ All repositories implemented
- ✅ All repository tests passing
- ✅ 90%+ coverage on repositories
- ✅ Database migrations working
- ✅ CRUD operations validated

### Day 3-4: Seed Data & Services

**Goal:** Populate initial data and support services

1. **Create Seed Data Function**
   - File: `Services/SeedDataService.swift`
   - Create default home
   - Create default categories (HVAC, Plumbing, Electrical, etc.)
   - Create default locations (Kitchen, Bathroom, etc.)
   - Make idempotent (check before creating)

2. **File Storage Service**
   - File: `Services/FileStorageService.swift`
   - Hash-based file storage (SHA-256)
   - Photo compression (JPEG 0.8 quality)
   - Max file size validation (50MB)
   - Deduplication

3. **Camera Service**
   - File: `Services/CameraService.swift`
   - Wrap UIImagePickerController for SwiftUI
   - Handle permissions (camera, photo library)
   - Return UIImage for processing

**Completion Criteria:**
- ✅ Seed data populates on first launch
- ✅ File storage works with hash deduplication
- ✅ Camera integration functional
- ✅ Services tested (80%+ coverage)

### Day 5-7: First ViewModel & View

**Goal:** Build Asset List feature (end-to-end)

1. **AssetListViewModel**
   - File: `ViewModels/AssetListViewModel.swift`
   - `@Published var assets: [Asset]`
   - Load assets from repository
   - Delete asset
   - Search/filter assets
   - Error handling

2. **AssetListView**
   - File: `Views/Assets/AssetListView.swift`
   - SwiftUI List displaying assets
   - Pull to refresh
   - Swipe to delete
   - Search bar
   - Navigate to detail view

3. **Tests**
   - `AssetListViewModelTests.swift` (85%+ coverage)
   - UI Tests: `AssetListUITests.swift`

4. **Update ContentView**
   - Replace placeholder with `AssetListView`

**Completion Criteria:**
- ✅ Asset list displays
- ✅ Can delete assets
- ✅ Search works
- ✅ Pull to refresh works
- ✅ ViewModel tested (85%+ coverage)
- ✅ UI tests pass

---

## Phase 2: Core Features (Week 2-3)

### Asset Management

1. **AssetDetailView**
   - Display asset details
   - Show associated maintenance records
   - Show associated tasks
   - Photos carousel

2. **AssetFormView**
   - Create new asset
   - Edit existing asset
   - Form validation
   - Photo picker integration

### Maintenance Records

1. **MaintenanceListView**
   - Display maintenance history
   - Filter by asset, date, type
   - Summary statistics

2. **MaintenanceFormView**
   - Log new maintenance
   - Attach photos
   - Link to service provider
   - Cost tracking (use Decimal!)

### Tasks

1. **TaskListView**
   - Upcoming tasks
   - Overdue tasks
   - Sort by due date, priority

2. **TaskFormView**
   - Create task
   - Link to asset
   - Set priority, due date
   - Mark complete

---

## Phase 3: Polish & Testing (Week 4)

### Dashboard

1. **DashboardView**
   - Summary statistics
   - Recent maintenance
   - Upcoming tasks
   - Quick actions

### Settings

1. **SettingsView**
   - Database backup/restore
   - Export data (JSON/CSV)
   - Reset all data
   - About / version info

### Testing & Coverage

1. **Achieve 85%+ Overall Coverage**
   - Run: `xcodebuild test -scheme HomeMaintMobile -enableCodeCoverage YES`
   - Check: Coverage report in Xcode
   - Add missing tests

2. **UI Testing (Critical Paths)**
   - Create asset → View → Edit → Delete
   - Log maintenance → View → Delete
   - Create task → Complete → Delete
   - Dashboard displays correctly

3. **Performance Testing**
   - Large dataset (100+ assets, 500+ maintenance records)
   - Scroll performance (60 FPS)
   - Database query speed (< 100ms)

---

## Phase 4: Refinement (Week 5)

### UX Improvements

1. **Loading States**
   - Skeleton views while loading
   - Pull to refresh animation
   - Empty states (no data)

2. **Error Handling**
   - User-friendly error messages
   - Retry mechanisms
   - Network error handling (future)

3. **Accessibility**
   - VoiceOver support
   - Dynamic Type support
   - High contrast mode

### iOS-Specific Features

1. **Widgets** (optional)
   - Upcoming tasks widget
   - Recent maintenance widget

2. **Siri Shortcuts** (optional)
   - "Show my recent maintenance"
   - "What tasks are due?"

3. **Notifications** (optional)
   - Task due date reminders
   - Warranty expiration alerts

---

## Development Best Practices

### Test-Driven Development (TDD)

**For every feature:**

1. **Write test first**
   ```swift
   func testAssetRepository_Create_ShouldReturnAssetWithId() {
       // Given
       let dto = AssetRepository.CreateAssetDTO(...)

       // When
       let asset = try! assetRepository.create(dto)

       // Then
       XCTAssertNotNil(asset.id)
       XCTAssertEqual(asset.name, dto.name)
   }
   ```

2. **Implement minimum code to pass**
3. **Refactor for clarity**
4. **Run tests** (⌘U)
5. **Check coverage** (must not decrease)

### Git Workflow

**Branch strategy:**
```bash
main          # Production-ready code
├── develop   # Integration branch
│   ├── feature/asset-list
│   ├── feature/maintenance-log
│   └── feature/dashboard
```

**Commit messages:**
```bash
git commit -m "Implement AssetRepository with CRUD operations

- Create, read, update, delete assets
- Custom query: findByHomeId
- Tests: 95% coverage

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Code Review Checklist

Before every PR:

- [ ] All tests pass (⌘U)
- [ ] Coverage ≥ 85% overall
- [ ] SwiftLint passes (no warnings)
- [ ] No force unwraps (`!`) - use `if let` or `guard let`
- [ ] No force try (`try!`) - use proper error handling
- [ ] No print statements - use `os_log` or remove
- [ ] Follows Repository + MVVM pattern
- [ ] CLAUDE.md updated if architecture changes

---

## Estimated Timeline

**MVP (Weeks 1-5):** Core features, single home, local SQLite

| Week | Focus | Deliverable |
|------|-------|------------|
| 1 | Foundation | Database + Repositories (90%+ coverage) |
| 2 | Assets | Asset CRUD with UI |
| 3 | Maintenance & Tasks | Log maintenance, manage tasks |
| 4 | Dashboard & Polish | Dashboard, settings, testing |
| 5 | Refinement | UX improvements, accessibility |

**Post-MVP:**
- v1.1: Data sync (import/export)
- v2.0: Multi-home, notifications, widgets

---

## Success Metrics

**Technical:**
- ✅ 85%+ test coverage
- ✅ 0 SwiftLint warnings
- ✅ < 2 min build time
- ✅ 60 FPS UI
- ✅ < 100ms DB queries

**Product:**
- ✅ All MVP features working
- ✅ < 5 critical bugs
- ✅ Positive internal testing feedback

---

## Getting Help

**Documentation:**
- `CLAUDE.md` - Architecture and patterns
- `README.md` - Quick start and commands
- `docs/XCODE_SETUP.md` - Project setup

**Examples:**
- HomeMaint web app: https://github.com/cjnemes/HomeMaint
- Same patterns, same schema, proven approach

**Troubleshooting:**
- Check `CLAUDE.md` Q&A section
- Review test fixtures for usage examples
- Consult Dev-Vault case studies

---

**You're ready to build! 🚀**

Start with Phase 1, Day 1 (Database & Repositories). Follow TDD approach. Maintain 85%+ coverage from day one.

Remember: **Test first, code second, coverage always.**
