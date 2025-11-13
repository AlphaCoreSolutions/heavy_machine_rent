# Replace 1.png with logo.png and Prepare for Publishing

## Code Changes
- [x] Update pubspec.yaml: Replace 1.png with logo.png in assets and flutter_native_splash config
- [x] Update lib/main.dart: Change Image.asset from 1.png to logo.png in _BootstrapHost
- [x] Update lib/screens/contract_screens/contract_details_screen.dart: Change Image.asset from 1.png to logo.png in _LogoBox

## Build and Publish Preparation
- [x] Run flutter pub get to update dependencies
- [x] Build Android APK: flutter build apk --release
- [x] Build Android App Bundle: flutter build appbundle --release
- [ ] Build iOS (if on macOS): flutter build ios --release
- [x] Build Web: flutter build web --release
- [x] Build macOS: flutter build macos --release
- [x] Build Windows: flutter build windows --release
- [x] Verify all platform configurations are correct
- [x] Test builds on respective platforms if possible
