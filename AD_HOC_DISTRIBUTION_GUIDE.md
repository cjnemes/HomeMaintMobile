# HomeMaintMobile - Ad Hoc Distribution Guide

This guide walks you through installing HomeMaintMobile on your physical iPhone for testing.

## Prerequisites

✅ **What You Need**:
1. Apple Developer Account (Individual or Organization) - $99/year
2. Physical iPhone connected to your Mac via USB
3. Xcode installed (already have this)
4. Your iPhone's UDID

## Step 1: Get Your iPhone's UDID

### Method A: Using Xcode (Recommended)
1. Connect your iPhone to your Mac via USB
2. Open Xcode
3. Go to **Window → Devices and Simulators** (⇧⌘2)
4. Select your iPhone from the left sidebar
5. Find the **Identifier** field - this is your UDID
6. Right-click the UDID and select **Copy**
7. Save it somewhere (you'll need it for Apple Developer Portal)

### Method B: Using Finder
1. Connect your iPhone via USB
2. Open Finder
3. Click your iPhone in the sidebar
4. Click on the text under your iPhone name (it cycles through info)
5. Keep clicking until you see the UDID
6. Right-click to copy

**Your UDID will look like**: `00008030-001234567890ABCD`

---

## Step 2: Register Your Device in Apple Developer Portal

1. Go to https://developer.apple.com/account
2. Sign in with your Apple ID
3. Navigate to **Certificates, Identifiers & Profiles**
4. Click **Devices** in the left sidebar
5. Click the **+** button to add a new device
6. Select **iOS, tvOS, watchOS**
7. Enter:
   - **Device Name**: Your iPhone name (e.g., "Chris's iPhone")
   - **Device ID (UDID)**: Paste the UDID you copied
8. Click **Continue** → **Register**

---

## Step 3: Register the App Identifier

1. Still in **Certificates, Identifiers & Profiles**
2. Click **Identifiers** in the left sidebar
3. Click the **+** button
4. Select **App IDs** → **Continue**
5. Select **App** → **Continue**
6. Fill in:
   - **Description**: HomeMaintMobile
   - **Bundle ID**: Select **Explicit** and enter: `JP-Digital.HomeMaintMobile`
7. **Capabilities**: Leave defaults (you can add later if needed)
8. Click **Continue** → **Register**

---

## Step 4: Create an Ad Hoc Provisioning Profile

1. Still in **Certificates, Identifiers & Profiles**
2. Click **Profiles** in the left sidebar
3. Click the **+** button
4. Select **Ad Hoc** → **Continue**
5. **App ID**: Select `JP-Digital.HomeMaintMobile`
6. Click **Continue**
7. **Select Certificates**: Check your development certificate
   - If you don't have one, you'll need to create it first (see Step 4a below)
8. Click **Continue**
9. **Select Devices**: Check your iPhone
10. Click **Continue**
11. **Provisioning Profile Name**: `HomeMaintMobile Ad Hoc`
12. Click **Generate**
13. Click **Download** to download the `.mobileprovision` file

### Step 4a: Create Development Certificate (if needed)

If you don't have a certificate:
1. Go to **Certificates** → click **+**
2. Select **Apple Development** → **Continue**
3. Follow the instructions to create a Certificate Signing Request (CSR):
   - Open **Keychain Access** on Mac
   - Go to **Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority**
   - Enter your email and name
   - Select **Saved to disk**
   - Click **Continue** and save the file
4. Upload the CSR file
5. Download the certificate and double-click to install in Keychain

---

## Step 5: Install the Provisioning Profile in Xcode

### Method A: Double-Click (Easiest)
1. Locate the downloaded `.mobileprovision` file
2. Double-click it
3. Xcode will automatically import it

### Method B: Manual Installation
1. Copy the `.mobileprovision` file to:
   ```
   ~/Library/MobileDevice/Provisioning Profiles/
   ```
2. Or open Xcode → **Settings** → **Accounts**
3. Select your Apple ID
4. Click **Download Manual Profiles**

---

## Step 6: Configure Xcode Project for Ad Hoc Distribution

1. Open `HomeMaintMobile.xcodeproj` in Xcode
2. Select the **HomeMaintMobile** project in the navigator
3. Select the **HomeMaintMobile** target
4. Go to the **Signing & Capabilities** tab
5. **Uncheck** "Automatically manage signing"
6. **Team**: Select your Apple Developer team
7. **Provisioning Profile**: Select "HomeMaintMobile Ad Hoc"
8. **Signing Certificate**: Should auto-select your development certificate

**Important**: Make sure both **Debug** and **Release** configurations are set correctly.

---

## Step 7: Build the Archive

1. In Xcode, connect your iPhone via USB
2. Select your iPhone as the build destination (top bar)
3. Go to **Product → Archive** (⌃⌘A)
4. Wait for the build to complete (2-5 minutes)
5. The **Organizer** window will open automatically
6. Select your archive from the list

---

## Step 8: Export the Archive for Ad Hoc Distribution

1. In the Organizer, click **Distribute App**
2. Select **Ad Hoc** → **Next**
3. Select **Re-sign** (or Upload if prompted) → **Next**
4. **Distribution Certificate**: Select your certificate
5. **Provisioning Profile**: Select "HomeMaintMobile Ad Hoc"
6. Click **Next**
7. Review the summary → **Export**
8. Choose a save location (e.g., Desktop)
9. Click **Export**

**Result**: You'll get a folder containing `HomeMaintMobile.ipa`

---

## Step 9: Install on Your iPhone

### Method A: Using Xcode Devices Window (Easiest)
1. Connect your iPhone via USB
2. Open **Window → Devices and Simulators** (⇧⌘2)
3. Select your iPhone
4. Click the **+** button under "Installed Apps"
5. Select the `HomeMaintMobile.ipa` file
6. Wait for installation to complete
7. App will appear on your iPhone home screen

### Method B: Using Apple Configurator (if Method A fails)
1. Download **Apple Configurator** from the Mac App Store (free)
2. Open Apple Configurator
3. Connect your iPhone
4. Double-click your device
5. Click **Add → Apps**
6. Select the `.ipa` file
7. Wait for installation

---

## Step 10: Trust the Developer on iPhone

**Important**: First time installing an ad hoc app requires trusting the developer profile.

1. On your iPhone, go to **Settings → General → VPN & Device Management**
2. Under "DEVELOPER APP", tap your Apple ID
3. Tap **Trust "[Your Name]"**
4. Tap **Trust** in the popup
5. Now you can open HomeMaintMobile!

---

## Troubleshooting

### Error: "Untrusted Developer"
- Follow Step 10 to trust the developer profile on your iPhone

### Error: "Unable to Install"
- Make sure your iPhone's UDID is registered in the Developer Portal
- Verify the provisioning profile includes your device
- Check that the bundle identifier matches exactly: `JP-Digital.HomeMaintMobile`

### Error: "Code Signing Failed"
- Verify your certificate is valid and not expired
- Check that the provisioning profile is downloaded and selected in Xcode
- Try refreshing provisioning profiles: Xcode → Settings → Accounts → Download Manual Profiles

### Error: "This application's application-identifier entitlement does not match"
- The bundle ID in Xcode must match the provisioning profile
- Verify in Xcode: Target → Signing & Capabilities → Bundle Identifier

### App Crashes Immediately on Launch
- Check the **Console** app on Mac while iPhone is connected
- Filter by "HomeMaintMobile" to see crash logs
- Most common: Missing entitlements or capabilities

---

## Current Project Configuration

**Bundle Identifier**: `JP-Digital.HomeMaintMobile`
**Xcode Project**: `HomeMaintMobile/HomeMaintMobile.xcodeproj`
**Main Scheme**: `HomeMaintMobile`
**Target iOS Version**: 17.0+

---

## Alternative: TestFlight Distribution (Recommended for Multiple Testers)

If you want to share with other testers or prefer an easier installation:

1. Follow Steps 1-6 above
2. In Step 8, select **App Store Connect** instead of Ad Hoc
3. Upload the build to TestFlight
4. Invite testers via email
5. Testers install via TestFlight app (no UDID registration needed for up to 10,000 external testers)

**Pros**:
- No UDID management
- Easier for testers to install
- Supports 90-day expiration (vs 7-day for ad hoc)

**Cons**:
- Requires App Store Connect access
- Builds reviewed by Apple (1-2 days)
- More complex initial setup

---

## Quick Reference Commands

### Check if your device is connected:
```bash
xcrun xctrace list devices
```

### View provisioning profiles:
```bash
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/
```

### Check certificate status:
```bash
security find-identity -v -p codesigning
```

### Build for device from command line:
```bash
xcodebuild -project HomeMaintMobile.xcodeproj \
  -scheme HomeMaintMobile \
  -configuration Release \
  -archivePath ./build/HomeMaintMobile.xcarchive \
  archive
```

### Export archive:
```bash
xcodebuild -exportArchive \
  -archivePath ./build/HomeMaintMobile.xcarchive \
  -exportPath ./build/export \
  -exportOptionsPlist ExportOptions.plist
```

---

## Next Steps After Installation

1. **Test the force unwrap fixes**: The app should no longer crash from nil values
2. **Verify UI functionality**: All screens should load properly
3. **Test database operations**: Create/edit/delete assets, tasks, maintenance records
4. **Monitor for crashes**: Check device Console app for any errors
5. **Report issues**: Create GitHub issues for any bugs found

---

## Support

- Apple Developer Documentation: https://developer.apple.com/documentation/
- Xcode Code Signing Guide: https://help.apple.com/xcode/mac/current/#/dev60b6fbbc7
- UDID Help: https://developer.apple.com/help/account/manage-devices/

---

**Last Updated**: October 27, 2025
**Project Version**: 1.0.0-MVP
**Safety Improvements**: PR #4 (Force unwrapping eliminated)
