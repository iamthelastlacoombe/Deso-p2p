# Quick Build Guide for DeSo P2P iOS App

## Ad Hoc Distribution (Fastest Method)

### Prerequisites
1. Apple Developer Account (Individual or Organization)
2. Xcode 14.0 or later
3. Device UDIDs for testing

### Quick Steps

1. **Register Test Devices**
```bash
# In Xcode:
1. Window -> Devices and Simulators
2. Connect iOS device
3. Copy UDID
4. Add UDID to your Apple Developer account
```

2. **Create Ad Hoc Profile**
```bash
# In Apple Developer Portal:
1. Certificates -> Create New
2. Select "Ad Hoc Distribution"
3. Choose your app ID
4. Select test devices
5. Download profile
```

3. **Build & Archive**
```bash
# Using Xcode:
1. Select "Any iOS Device" as build target
2. Product -> Archive
3. Window -> Organizer
4. Select archive -> Distribute App
5. Select "Ad Hoc" -> Next
6. Choose your Ad Hoc profile
7. Export IPA
```

4. **Quick Command Line Build**
```bash
# One-line build command:
xcodebuild -scheme DeSoP2P archive -archivePath build/DeSoP2P.xcarchive && xcodebuild -exportArchive -archivePath build/DeSoP2P.xcarchive -exportPath build/DeSoP2P -exportOptionsPlist exportOptions.plist
```

### Distribution
1. Use Apple's TestFlight (recommended)
2. Or distribute IPA directly to registered devices


## Distribution Methods (In Order of Speed)

1. **Ad Hoc Distribution**
   - Quickest method for internal testing
   - Requires device UDID registration
   - Limited to 100 devices

2. **TestFlight**
   - Apple-approved method
   - Upload through Xcode
   - Users can install within minutes

3. **Enterprise Distribution**
   - For internal company use
   - Requires Enterprise Account
   - No device limit


## Pre-build Checklist (Essential)
- [ ] Device UDIDs registered
- [ ] Ad Hoc profile downloaded
- [ ] Network permissions in Info.plist
- [ ] DeSo node configuration verified

## Quick Debugging
- Check Console.app for logs
- Verify DeSo node connectivity
- Test transaction signing

For urgent support, contact development team.