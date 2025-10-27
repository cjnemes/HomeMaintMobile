# HomeMaint Mobile - Development Roadmap

**Project Status:** MVP Phase - Core Features Complete, Advanced Features In Progress
**Last Updated:** October 26, 2025
**Current Version:** 1.0.0-MVP

---

## 🎯 Project Vision

Build a comprehensive iOS mobile app for home maintenance tracking that enables homeowners to:
- Track all home assets and their maintenance history
- Schedule and complete maintenance tasks
- Capture and store photos/documents
- Manage service provider contacts
- Get insights on home maintenance costs and schedules

---

## ✅ Completed (Phase 1 - MVP Core)

### Database & Architecture
- ✅ SQLite database with GRDB
- ✅ Repository Pattern implementation
- ✅ MVVM architecture with SwiftUI
- ✅ 3 database migrations
- ✅ Auto-seeding service (categories, locations)
- ✅ 85%+ test coverage

### Features Implemented
- ✅ **Assets Management** - Full CRUD with categories and locations
- ✅ **Tasks Management** - Create, filter, search, complete tasks
- ✅ **Service Providers** - Company-focused contact management
- ✅ **Dashboard** - Statistics and navigation hub

### Data Models (All Complete)
- ✅ Home
- ✅ Asset
- ✅ Category
- ✅ Location
- ✅ MaintenanceTask
- ✅ MaintenanceRecord
- ✅ ServiceProvider
- ✅ Attachment

### Repositories (All Complete)
- ✅ BaseRepository (generic CRUD)
- ✅ HomeRepository
- ✅ AssetRepository
- ✅ CategoryRepository
- ✅ LocationRepository
- ✅ MaintenanceTaskRepository
- ✅ MaintenanceRecordRepository
- ✅ ServiceProviderRepository
- ✅ AttachmentRepository

---

## 🚧 Phase 2 - Advanced Features (Current)

### Priority 1: Maintenance Records UI
**Status:** Repository exists, UI needed
**Estimated Effort:** 4-6 hours
**Dependencies:** None

**Tasks:**
- [ ] Create MaintenanceRecordListViewModel (with tests)
- [ ] Create MaintenanceRecordListView (list, search, filter by asset)
- [ ] Create MaintenanceRecordFormView (create/edit)
- [ ] Create MaintenanceRecordDetailView (view record details)
- [ ] Wire up navigation from Assets and Dashboard
- [ ] Test end-to-end workflow

**Acceptance Criteria:**
- Users can log maintenance performed on assets
- Records include: date, type, cost, service provider, notes
- Can view history per asset
- Can search and filter records
- All views follow existing design patterns

---

### Priority 2: Photo/Document Capture & Storage
**Status:** FileStorageService exists, Camera/UI needed
**Estimated Effort:** 6-8 hours
**Dependencies:** Privacy permissions (Camera, Photo Library)

**Tasks:**
- [ ] Implement CameraService (wrap UIImagePickerController)
- [ ] Add privacy strings to Info.plist (NSCameraUsageDescription, NSPhotoLibraryUsageDescription)
- [ ] Test FileStorageService (exists but untested)
- [ ] Create ImagePickerView (SwiftUI wrapper)
- [ ] Create PhotoGridView (display thumbnails)
- [ ] Integrate photo picker into AssetFormView
- [ ] Integrate photo picker into MaintenanceRecordFormView
- [ ] Add photo viewing in detail views

**Acceptance Criteria:**
- Users can capture photos from camera
- Users can select photos from library
- Photos are stored with hash-based deduplication (SHA-256)
- Photos are linked to assets and maintenance records
- Thumbnails load quickly
- Full-size images can be viewed
- Photos are backed up with app data

---

### Priority 3: Attachments/Documents UI
**Status:** Repository exists, UI needed
**Estimated Effort:** 4-6 hours
**Dependencies:** Photo capture (Priority 2)

**Tasks:**
- [ ] Create AttachmentListView (show photos/docs for asset or record)
- [ ] Create AttachmentDetailView (view full-size image, metadata)
- [ ] Add attachment section to AssetDetailView
- [ ] Add attachment section to MaintenanceRecordDetailView
- [ ] Implement delete attachment functionality
- [ ] Add ability to attach PDFs (manuals, receipts)

**Acceptance Criteria:**
- View all attachments for an asset or maintenance record
- Delete attachments
- View full-size images with pinch-to-zoom
- Display file metadata (size, date, type)
- Support common formats (JPEG, PNG, PDF)

---

## 📚 Phase 3 - Documentation & Repository

### Documentation Tasks
**Estimated Effort:** 3-4 hours

- [ ] **README.md** (main documentation)
  - Project overview and features
  - Screenshots/demo GIF
  - Installation instructions
  - Quick start guide
  - Technology stack
  - Project structure
  - Contributing guidelines

- [ ] **ARCHITECTURE.md**
  - Repository Pattern explanation
  - MVVM structure
  - Data flow diagrams
  - Database schema
  - File organization
  - Design decisions

- [ ] **API_REFERENCE.md**
  - Repository method documentation
  - ViewModel documentation
  - Model field definitions
  - Code examples

- [ ] **SETUP.md**
  - Developer environment setup
  - Xcode version requirements
  - Swift Package Manager dependencies
  - Running tests
  - Building for device
  - Troubleshooting guide

- [ ] **CONTRIBUTING.md**
  - Code style guidelines
  - Pull request process
  - Testing requirements
  - Commit message format

### GitHub Repository Setup
**Estimated Effort:** 1-2 hours

- [ ] Initialize Git repository (if not already)
- [ ] Create comprehensive .gitignore
- [ ] Choose and add LICENSE (MIT recommended)
- [ ] Create GitHub repository
- [ ] Push initial commit
- [ ] Configure branch protection (main branch)
- [ ] Add GitHub issue templates
- [ ] Add pull request template
- [ ] Configure GitHub Actions for CI (optional)
- [ ] Add topics/tags for discoverability

---

## 🎨 Phase 4 - Onboarding (Deferred)

**Status:** Deferred until Phases 2-3 complete
**Estimated Effort:** 4-6 hours

**Tasks:**
- [ ] Design onboarding flow (3-5 screens)
- [ ] Create OnboardingView with page navigation
- [ ] Explain key features with illustrations
- [ ] Add "Get Started" / "Skip" options
- [ ] Save onboarding completion flag
- [ ] Show only on first launch

**Screens:**
1. Welcome to HomeMaint Mobile
2. Track Your Home Assets
3. Schedule Maintenance Tasks
4. Capture Photos & Documents
5. Get Started

---

## 🔮 Phase 5 - Advanced Features (Future)

### Data Sync & Export
- [ ] iCloud sync support
- [ ] CSV/JSON data export
- [ ] Import from web app
- [ ] Backup/restore functionality

### Notifications & Reminders
- [ ] Warranty expiration alerts
- [ ] Upcoming task notifications
- [ ] Maintenance schedule reminders
- [ ] Push notification system

### Enhanced Features
- [ ] Recurring tasks automation
- [ ] Cost analytics and charts
- [ ] Multi-home support
- [ ] Siri shortcuts integration
- [ ] Home screen widgets
- [ ] iPad multi-window support
- [ ] Dark mode optimization

### Integration
- [ ] Calendar integration (add tasks to Calendar)
- [ ] Contacts integration (service providers)
- [ ] Maps integration (service provider locations)
- [ ] Share functionality (export reports)

---

## 📊 Effort Estimates Summary

| Phase | Component | Effort | Status |
|-------|-----------|--------|--------|
| 1 | Core MVP | 40 hours | ✅ Complete |
| 2 | Maintenance Records UI | 4-6 hours | 🚧 Pending |
| 2 | Photo/Document Capture | 6-8 hours | 🚧 Pending |
| 2 | Attachments UI | 4-6 hours | 🚧 Pending |
| 3 | Documentation | 3-4 hours | 🚧 Pending |
| 3 | GitHub Setup | 1-2 hours | 🚧 Pending |
| 4 | Onboarding | 4-6 hours | ⏸️ Deferred |
| 5 | Advanced Features | 30+ hours | ⏸️ Future |

**Phase 2-3 Total:** ~20-28 hours

---

## 🎯 Immediate Next Steps

### This Week
1. **Maintenance Records UI** - Complete full workflow
2. **Camera Integration** - Enable photo capture
3. **Basic Documentation** - README, setup guide

### Next Week
4. **Photo Storage & Display** - Complete attachment system
5. **Comprehensive Documentation** - Architecture, API reference
6. **GitHub Repository** - Publish with all docs

### Following Week
7. **Onboarding Flow** - Welcome new users
8. **Polish & Bug Fixes** - Address any issues
9. **TestFlight Beta** - Distribute to testers

---

## 🧪 Testing Strategy

Each new feature requires:
- [ ] Unit tests for repository methods (90%+ coverage)
- [ ] Unit tests for ViewModels (85%+ coverage)
- [ ] Manual testing in simulator
- [ ] Manual testing on physical device
- [ ] Edge case testing (empty states, errors, large datasets)

---

## 📝 Definition of Done

For each feature to be considered "complete":
- ✅ Code implements all acceptance criteria
- ✅ Unit tests written and passing (85%+ coverage)
- ✅ No compiler warnings introduced
- ✅ Follows Repository + MVVM pattern
- ✅ Tested on simulator and device
- ✅ Documentation updated (inline comments + guides)
- ✅ CLAUDE.md updated if architecture changes
- ✅ Committed to version control

---

## 🚀 Success Metrics

### Technical
- Maintain 85%+ test coverage
- Build time < 2 minutes
- App size < 50 MB
- Crash-free rate > 99%
- No critical bugs in production

### Product
- All core features functional
- Intuitive navigation
- Fast performance (60 FPS)
- Positive user feedback
- App Store ready

---

## 🎓 Learning & Best Practices

Throughout development, we're following:
- **Test-First Development** - Write tests before/during implementation
- **Repository Pattern** - Clean data access abstraction
- **MVVM** - Separation of concerns
- **SwiftUI Best Practices** - Proper state management
- **No Anti-Patterns** - Per CLAUDE.md guidelines
- **Incremental Development** - Small, testable changes
- **Documentation-Driven** - Keep docs in sync with code

---

## 📞 Questions & Decisions Log

### Resolved
- ✅ Use SQLite vs CoreData → SQLite (GRDB) for portability with web app
- ✅ Use Repository Pattern → Yes, matches web app, enables testing
- ✅ Single vs Multi-home → Single home for MVP
- ✅ Company vs Person for Service Providers → Company primary (recently updated)

### Pending
- ⏳ Photo storage limit per asset/record?
- ⏳ Maximum attachment file size?
- ⏳ PDF viewer built-in or external?
- ⏳ iCloud sync timeline?
- ⏳ TestFlight vs Ad Hoc for beta testing?

---

**Current Focus:** Phase 2 - Maintenance Records, Camera, and Attachments
**Target Completion:** 2-3 weeks
**Next Milestone:** Feature-complete app ready for onboarding and TestFlight beta
