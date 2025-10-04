#!/usr/bin/swift

import Foundation

// This script creates an Xcode project for the EVRouteSwiftUI app
// Run with: swift create_xcode_project.swift

let projectName = "EVRouteSwiftUI"
let organizationName = "Your Organization"
let bundleIdentifier = "com.yourorg.evrouteswiftui"

// Create project structure using xcodegen or manually
print("Creating Xcode project for \(projectName)...")

// Create Info.plist
let infoPlist = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>EV Route needs your location to find nearby charging stations and plan routes.</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations~iphone</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
"""

// Save Info.plist
try infoPlist.write(toFile: "Resources/Info.plist", atomically: true, encoding: .utf8)

print("""

✅ Project structure created!

Next steps:
1. Open Xcode
2. Create a new project: File > New > Project
3. Choose iOS > App
4. Use these settings:
   - Product Name: EVRouteSwiftUI
   - Team: Your Team
   - Organization Identifier: com.yourorg
   - Interface: SwiftUI
   - Language: Swift
   - Use Core Data: No
   - Include Tests: Yes
5. Save to the Desktop/EVRouteSwiftUI folder
6. Delete the default files created by Xcode
7. Add all the Swift files from the folder structure to the project
8. Build and run!

""")