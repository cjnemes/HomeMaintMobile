# HomeMaintMobile - Pre-Flight Checklist for Ad Hoc Installation

Complete this checklist before attempting to install on your physical iPhone.

## ✅ Pre-Installation Checklist

### 1. Apple Developer Account Setup
- [ ] You have an active Apple Developer account ($99/year)
- [ ] You can sign in at https://developer.apple.com/account
- [ ] Your account status is "Active" (not pending payment)

### 2. iPhone Preparation
- [ ] iPhone is charged (at least 50%)
- [ ] iPhone has iOS 17.0 or later installed
- [ ] You have a USB cable to connect iPhone to Mac
- [ ] iPhone is unlocked and trusted on this Mac
- [ ] "Find My iPhone" is temporarily disabled (makes installation easier)

### 3. Xcode Readiness
- [ ] Xcode is installed and up to date
- [ ] You can open `HomeMaintMobile.xcodeproj` without errors
- [ ] Project builds successfully (already verified ✅)
- [ ] You have admin access on your Mac

### 4. Information You'll Need
Write down these before starting:

**iPhone UDID**: _________________________________
- Get from: Xcode → Window → Devices and Simulators → Select iPhone → Copy Identifier

**Apple ID**: ____________________________________
- The email you use for Apple Developer account

**Bundle Identifier**: `JP-Digital.HomeMaintMobile` (already configured ✅)

---

## 📋 Installation Process Overview

**Estimated Time**: 20-30 minutes (first time)

**Steps Summary**:
1. Get iPhone UDID (2 min)
2. Register device in Developer Portal (5 min)
3. Create App ID if needed (3 min)
4. Create Ad Hoc provisioning profile (5 min)
5. Download and install profile (2 min)
6. Configure Xcode signing (3 min)
7. Archive the app (2-5 min)
8. Export for ad hoc (2 min)
9. Install on iPhone (2 min)
10. Trust developer certificate (1 min)

---

## 🚀 Quick Start Command

After completing the Developer Portal setup (Steps 1-5 in the guide), you can use Xcode GUI or command line:

### Option A: Xcode GUI (Recommended for first time)
1. Open `HomeMaintMobile.xcodeproj` in Xcode
2. Connect iPhone
3. Select iPhone as destination (top bar)
4. Product → Archive
5. Distribute App → Ad Hoc
6. Export
7. Install via Devices window

### Option B: Command Line (Advanced)
```bash
# Archive
xcodebuild archive \
  -project HomeMaintMobile/HomeMaintMobile.xcodeproj \
  -scheme HomeMaintMobile \
  -archivePath ./build/HomeMaintMobile.xcarchive

# Export (requires ExportOptions.plist)
xcodebuild -exportArchive \
  -archivePath ./build/HomeMaintMobile.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

---

## ⚠️ Common Issues & Quick Fixes

### Issue: "No signing certificate found"
**Fix**:
1. Xcode → Settings → Accounts
2. Select your Apple ID
3. Click "Download Manual Profiles"
4. Or create new certificate in Developer Portal

### Issue: "Device not registered"
**Fix**:
1. Go to https://developer.apple.com/account
2. Devices → Add your iPhone's UDID
3. Regenerate provisioning profile to include the new device

### Issue: "Build failed - Code signing error"
**Fix**:
1. Target → Signing & Capabilities
2. Uncheck "Automatically manage signing"
3. Manually select Team and Provisioning Profile

### Issue: "Unable to install app on iPhone"
**Fix**:
1. Settings → General → VPN & Device Management
2. Trust your developer certificate
3. Try installing again

---

## 🔍 Final Verification Before Installation

Run these checks:

### Check 1: Project Configuration
```bash
cd /Users/chris/dev/HomeMaintMobile
plutil -convert xml1 -o - HomeMaintMobile/HomeMaintMobile.xcodeproj/project.pbxproj | grep "PRODUCT_BUNDLE_IDENTIFIER" | head -3
```
**Expected**: Should show `JP-Digital.HomeMaintMobile`

### Check 2: Build Status
```bash
xcodebuild clean build \
  -project HomeMaintMobile/HomeMaintMobile.xcodeproj \
  -scheme HomeMaintMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```
**Expected**: `** BUILD SUCCEEDED **`

### Check 3: Available Devices
```bash
xcrun xctrace list devices
```
**Expected**: Your iPhone should be listed

---

## 📱 What to Test After Installation

Once installed on your iPhone:

### Critical Tests (Do These First):
1. **App Launch**: App opens without crashing ✓
2. **Navigation**: All tabs and screens load ✓
3. **Database**: Can create/view/edit/delete assets ✓
4. **Camera**: Photo capture works (if needed) ✓

### Regression Tests (Force Unwrap Fixes):
5. **Home Screen**: Loads without crashes ✓
6. **Asset List**: Displays assets correctly ✓
7. **Asset Detail**: Shows asset details ✓
8. **Task Management**: Create/edit tasks ✓
9. **Service Providers**: View/add providers ✓
10. **Maintenance Records**: Log maintenance ✓

### Edge Cases (Previously Crashed):
11. **Empty States**: App handles no data gracefully ✓
12. **Nil Values**: Doesn't crash on missing optional fields ✓
13. **Network Errors**: Handles errors without crashing ✓

---

## 📝 Notes

**Build Date**: October 27, 2025
**Version**: 1.0.0-MVP
**Git Branch**: `main`
**Git Commit**: Latest (post PR #4 merge)
**Safety Fixes**: All 72 force unwraps eliminated
**Test Coverage**: Infrastructure created (execution pending)

---

## 🆘 Need Help?

1. **Full Guide**: See `AD_HOC_DISTRIBUTION_GUIDE.md` for detailed step-by-step
2. **Apple Docs**: https://developer.apple.com/documentation/
3. **Bundle ID**: `JP-Digital.HomeMaintMobile`
4. **Project Location**: `/Users/chris/dev/HomeMaintMobile`

---

## ✅ Ready to Proceed?

If all checkboxes are checked above, you're ready to start!

**Next Step**: Follow `AD_HOC_DISTRIBUTION_GUIDE.md` starting at Step 1.

Good luck! 🚀
