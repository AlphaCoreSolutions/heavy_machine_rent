# App Name Standardization to "Ajjara"

## Current Status
- pubspec.yaml: "Ajjara" ✓
- Android: "Ajjara" ✓
- iOS: "Ajjara" ✓
- macOS: "$(PRODUCT_NAME)" (will inherit from pubspec) ✓
- Web: Title "Ajjara", manifest "Ajjara", apple-mobile-web-app-title "Ajjara" ✓
- Windows: "Ajjara" ✓
- Linux: "Ajjara" ✓

## Tasks
- [x] Update pubspec.yaml name to "Ajjara"
- [x] Update AndroidManifest.xml android:label to "Ajjara"
- [x] Update iOS Info.plist CFBundleDisplayName and CFBundleName to "Ajjara"
- [x] Update macOS Info.plist CFBundleName to "Ajjara" (if not using $(PRODUCT_NAME))
- [x] Update web/index.html title and apple-mobile-web-app-title to "Ajjara"
- [x] Update web/manifest.json name and short_name to "Ajjara"
- [x] Update windows/runner/main.cpp window title to "Ajjara"
- [x] Update linux/runner/my_application.cc titles to "Ajjara"
