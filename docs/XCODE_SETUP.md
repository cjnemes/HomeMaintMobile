# Xcode Project Setup Guide

Step-by-step guide to create the HomeMaint Mobile Xcode project with proper configuration.

## Prerequisites

- macOS 14+ (Sonoma or later)
- Xcode 15.2+ installed
- Command Line Tools: `xcode-select --install`

## Step 1: Create New Xcode Project

1. **Open Xcode**
2. **File → New → Project** (or ⌘⇧N)
3. **Select template:**
   - Platform: **iOS**
   - Template: **App**
   - Click **Next**

## Step 2: Configure Project

**Project Configuration:**
- **Product Name:** `HomeMaintMobile`
- **Team:** Select your Apple Developer account (or "None" for local dev)
- **Organization Identifier:** `com.yourdomain` (e.g., `com.cjnemes`)
- **Bundle Identifier:** Auto-generated (e.g., `com.cjnemes.HomeMaintMobile`)
- **Interface:** **SwiftUI**
- **Language:** **Swift**
- **Storage:** **None** (we'll use GRDB.swift)
- **Include Tests:** ✅ **Checked**

Click **Next**.

## Step 3: Choose Location

1. Navigate to: `/Users/chris/dev/HomeMaintMobile`
2. **IMPORTANT:** **Uncheck** "Create Git repository" (we already have one)
3. Click **Create**

Xcode will create:
```
HomeMaintMobile/
├── HomeMaintMobile.xcodeproj
├── HomeMaintMobile/
│   ├── HomeMaintMobileApp.swift
│   ├── ContentView.swift
│   ├── Assets.xcassets/
│   └── Preview Content/
├── HomeMaintMobileTests/
│   └── HomeMaintMobileTests.swift
└── HomeMaintMobileUITests/
    ├── HomeMaintMobileUITests.swift
    └── HomeMaintMobileUITestsLaunchTests.swift
```

## Step 4: Configure Project Settings

### A. General Settings

1. Select **HomeMaintMobile** project in Navigator
2. Select **HomeMaintMobile** target (under TARGETS)
3. **General tab:**

**Identity:**
- Display Name: `HomeMaint`
- Bundle Identifier: `com.cjnemes.HomeMaintMobile`

**Deployment Info:**
- Minimum Deployments: **iOS 17.0**
- Supported Destinations: **iPhone, iPad**
- Device Orientation:
  - ✅ Portrait
  - ✅ Landscape Left
  - ✅ Landscape Right
  - ❌ Upside Down (iPhone only)

### B. Capabilities

1. **Signing & Capabilities tab:**
2. Click **+ Capability**
3. Add:
   - **App Groups** (for shared storage if needed later)

### C. Info.plist Configuration

1. Select `HomeMaintMobile/Info.plist` (or Info tab in target)
2. Add keys:

**Camera & Photo Library Permissions:**
```xml
<key>NSCameraUsageDescription</key>
<string>HomeMaint needs camera access to capture photos of your assets and maintenance records.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>HomeMaint needs photo library access to attach photos to assets and maintenance records.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>HomeMaint needs permission to save photos to your library.</string>
```

## Step 5: Add Swift Package Dependencies

1. **File → Add Package Dependencies...**
2. Search for: `https://github.com/groue/GRDB.swift`
3. **Dependency Rule:** Up to Next Major Version `6.0.0 < 7.0.0`
4. Click **Add Package**
5. Select **GRDB** library
6. Click **Add Package**

**Additional recommended packages:**
- SwiftLint: `https://github.com/realm/SwiftLint` (for code quality)

## Step 6: Organize File Structure

### A. Create Groups

In **HomeMaintMobile** folder, create these groups (folders):

1. Right-click `HomeMaintMobile` → **New Group**
2. Create:
   - `Models`
   - `Repositories`
   - `ViewModels`
   - `Views`
   - `Services`
   - `Utils`

### B. Move Existing Files

- Move `ContentView.swift` → `Views/`
- Move `HomeMaintMobileApp.swift` → Root (keep here)

### C. Add Boilerplate Files

Copy templates from `/Users/chris/dev/HomeMaintMobile/templates/Swift/`:

1. **DatabaseService.swift:**
   - Drag from Finder → `Services/` group
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Add to target: `HomeMaintMobile`

2. **BaseRepository.swift:**
   - Drag from Finder → `Repositories/` group

3. **AssetModel.swift:**
   - Drag from Finder → `Models/` group

Final structure:
```
HomeMaintMobile/
├── HomeMaintMobileApp.swift
├── Models/
│   └── AssetModel.swift
├── Repositories/
│   └── BaseRepository.swift
├── ViewModels/
├── Views/
│   └── ContentView.swift
├── Services/
│   └── DatabaseService.swift
└── Utils/
```

## Step 7: Initialize Database on App Launch

Edit `HomeMaintMobileApp.swift`:

```swift
import SwiftUI

@main
struct HomeMaintMobileApp: App {

    init() {
        // Initialize database on app launch
        do {
            try DatabaseService.shared.initialize()
        } catch {
            print("❌ Failed to initialize database: \(error)")
            // In production, show error UI to user
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Step 8: Configure Build Settings

### A. Enable Strict Concurrency Checking

1. Select **HomeMaintMobile** project
2. Select **HomeMaintMobile** target
3. **Build Settings tab**
4. Search for: `Strict Concurrency Checking`
5. Set to: **Minimal** (or **Targeted** for Swift 6 readiness)

### B. Enable Code Coverage

1. **Product → Scheme → Edit Scheme...** (or ⌘<)
2. Select **Test** in left sidebar
3. **Options tab**
4. ✅ **Code Coverage** → Check "Gather coverage for all targets"
5. Click **Close**

## Step 9: Configure SwiftLint

### A. Install SwiftLint

```bash
brew install swiftlint
```

### B. Add Run Script Phase

1. Select **HomeMaintMobile** target
2. **Build Phases tab**
3. Click **+** → **New Run Script Phase**
4. Drag to position **before** "Compile Sources"
5. Name: `SwiftLint`
6. Script:
```bash
if which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```
7. ✅ Check "Based on dependency analysis"

## Step 10: Build & Test

### A. Build Project

1. **Product → Build** (⌘B)
2. Verify no errors

### B. Run Tests

1. **Product → Test** (⌘U)
2. Verify initial tests pass

### C. Run on Simulator

1. Select simulator: **iPhone 15** (or your preference)
2. **Product → Run** (⌘R)
3. App should launch successfully

## Step 11: Verify Setup

Run these checks:

```bash
# From /Users/chris/dev/HomeMaintMobile

# 1. SwiftLint
swiftlint lint

# 2. Build from command line
xcodebuild clean build \
  -scheme HomeMaintMobile \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# 3. Run tests
xcodebuild test \
  -scheme HomeMaintMobile \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# 4. Check coverage
xcodebuild test \
  -scheme HomeMaintMobile \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

## Step 12: Commit Initial Setup

```bash
git add .
git commit -m "Initial Xcode project setup with GRDB.swift

- SwiftUI app targeting iOS 17+
- GRDB.swift for SQLite database
- Repository Pattern architecture
- DatabaseService with migrations
- XCTest configured with coverage
- SwiftLint integrated

🤖 Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Troubleshooting

### Issue: "No such module 'GRDB'"

**Solution:**
1. **File → Packages → Resolve Package Versions**
2. Wait for Swift Package Manager to download
3. Clean Build Folder: **Product → Clean Build Folder** (⌘⇧K)
4. Build again: **Product → Build** (⌘B)

### Issue: "Command SwiftLint failed"

**Solution:**
1. Install SwiftLint: `brew install swiftlint`
2. Or temporarily disable SwiftLint build phase

### Issue: "Signing requires a development team"

**Solution:**
1. **Signing & Capabilities tab**
2. Select your team (or "Add Account..." to add Apple ID)
3. Or set **Automatically manage signing** and select team

### Issue: Database initialization fails

**Solution:**
1. Check console for error message
2. Verify DatabaseService.swift syntax (no compile errors)
3. Check file permissions for Documents directory

## Next Steps

After successful setup:

1. **Review CLAUDE.md** - Architecture and development guidelines
2. **Create first repository** - AssetRepository (extends BaseRepository)
3. **Build first view** - Asset list with ViewModel
4. **Write tests** - Start with repository tests (aim for 90%+ coverage)
5. **Implement features** - Follow Repository + MVVM pattern

See `README.md` for development workflow and `CLAUDE.md` for architecture details.

---

**Estimated Time:** 30-45 minutes

**Verification:**
- ✅ Project builds without errors
- ✅ Tests run successfully
- ✅ App launches in simulator
- ✅ Database initializes (check console logs)
- ✅ SwiftLint runs (no errors)
- ✅ Code coverage enabled
