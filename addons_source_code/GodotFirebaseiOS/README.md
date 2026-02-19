# godot-firebase-ios (⚠️ WORK IN PROGRESS)

Firebase Auth plugin for Godot 4 on iOS, built with SwiftGodot.

## Features
- Anonymous Authentication
- Google Sign-In
- Link anonymous account to Google

## Requirements
- Xcode 15+, Swift 5.9+, iOS 17+

## Setup

### 1. Firebase Console
- Enable **Anonymous** and **Google Sign-In** providers in Authentication > Sign-in method.
- Download `GoogleService-Info.plist` and place it in your Godot project's `ios/build/`.

### 2. URL Scheme (required for Google Sign-In)
In the Xcode trampoline project, open `Stepland Proto-Info.plist` and add a `CFBundleURLTypes` entry with your `REVERSED_CLIENT_ID` value from `GoogleService-Info.plist`.

### 3. Build the Framework
1. Open this repo in Xcode.
2. Select the `GodotFirebaseiOS` scheme, set destination to **Any iOS Device (arm64)**.
3. Build with **Product > Build** (Release).
4. **Product > Show Build Folder in Finder**.
5. Navigate to `Release-iphoneos/PackageFrameworks/GodotFirebaseiOS.framework`.
6. Copy it into your Godot project's `addons/GodotFirebaseiOS/GodotFirebaseiOS.framework`.

### 4. Export from Godot
Export for iOS as usual. The `.gdextension` file in `addons/GodotFirebaseiOS/` loads the plugin automatically. Then open the Xcode trampoline project, archive, and upload to TestFlight.

## GDScript API

All methods are available through the `FirebaseAuthWrapper` autoload:

```gdscript
FirebaseAuthWrapper.sign_in_anonymously()
FirebaseAuthWrapper.sign_in_with_google()
FirebaseAuthWrapper.link_anonymous_with_google()
FirebaseAuthWrapper.sign_out()
FirebaseAuthWrapper.is_signed_in()
FirebaseAuthWrapper.get_uid()
```

Signals: `auth_success(user_data)`, `auth_error(message)`, `signed_out()`
