# Firebase Mobile Integration Demo

A Godot 4.6 demo showing Firebase Authentication on **both iOS and Android** from a single project, using two different native plugin approaches.

> **Project structure**: The Godot project lives in the [`demo/`](demo/) folder. Open `demo/project.godot` in the Godot editor. Native plugin source code is in [`addons_source_code/`](addons_source_code/).

Firebase Authentication on both iOS and Android, using two different native plugin approaches:

- **iOS**: SwiftGodot GDExtension (`FirebaseAuthPlugin` registered in ClassDB)
- **Android**: Kotlin Engine singleton (`GodotFirebaseAndroid` via `Engine.get_singleton()`)

A unified wrapper autoload detects the platform at runtime and delegates to the correct backend.

## Purpose

This project serves two purposes:

1. **Demonstrate cross-platform Firebase integration** using a single Godot project with platform-specific native plugins. Shows that the SwiftGodot GDExtension approach for iOS is simpler (fewer files, less boilerplate, real typed classes) compared to the Engine singleton pattern used on Android.

2. **Provide a reference for platform-specific GDExtension plugins** and the challenges discussed in [godotengine/godot#105615](https://github.com/godotengine/godot/issues/105615).

Built on top of [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid) by Anish Mishra.

## Architecture

```
autoload/firebase_wrapper.gd    ← "Firebase" autoload singleton
    │
    ├─ Android: Engine.has_singleton("GodotFirebaseAndroid")
    │           → calls Java-style methods on Kotlin plugin
    │
    └─ iOS:    ClassDB.class_exists("FirebaseAuthPlugin")
               → calls snake_case methods on SwiftGodot class
```

### GDExtension vs Engine Singleton Comparison

| Aspect | Android (Engine Singleton) | iOS (GDExtension) |
|--------|---------------------------|-------------------|
| Registration | `Engine.get_singleton("Name")` | `ClassDB.class_exists("Name")` |
| Instantiation | Opaque `Object` from Engine | `ClassDB.instantiate()` → typed `RefCounted` |
| Method naming | Java-style (`signInAnonymously`) | Godot snake_case (`sign_in_anonymously`) |
| Editor support | No autocomplete, no type info | RefCounted subclass, editor-friendly |
| Boilerplate | Export plugin + Gradle injection + AAR | Single `.gdextension` file + framework |
| Signal data | Native `Dictionary` | JSON `String` |

## Requirements

**Both platforms:**
- Godot 4.4+
- Firebase project with Authentication enabled

**iOS:**
- Xcode 15+, Swift 5.9+
- iOS 17+ device (arm64)

**Android:**
- Android SDK, Gradle
- Android device or emulator (arm64-v8a)

## Setup

### 1. Firebase Console

- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Enable **Anonymous** and **Google Sign-In** providers under Authentication > Sign-in method

### 2. iOS Setup

- Register an iOS app in Firebase, download `GoogleService-Info.plist`
- Place it in the `demo/` folder (the Godot project root)
- After exporting from Godot, in the Xcode trampoline project add a `CFBundleURLTypes` entry with your `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`
- Build and deploy to device

### 3. Android Setup

- Register an Android app in Firebase, download `google-services.json`
- Place it in `demo/android/build/google-services.json` (after creating the Android export template)
- Enable Gradle build in export settings
- Build and deploy to device

## GDScript API

All methods are available through the `Firebase` autoload:

```gdscript
# Sign-in (both platforms)
Firebase.sign_in_anonymously()
Firebase.sign_in_with_google()
Firebase.link_anonymous_with_google()
Firebase.sign_out_user()
Firebase.is_signed_in()         # -> bool
Firebase.get_current_user()     # -> String (JSON)

# iOS only
Firebase.is_anonymous()         # -> bool
Firebase.get_uid()              # -> String

# Android only
Firebase.create_user_with_email_password(email, password)
Firebase.sign_in_with_email_password(email, password)
Firebase.send_password_reset_email(email)
Firebase.send_email_verification()
Firebase.delete_current_user()

# Helpers
Firebase.is_available()         # -> bool
Firebase.get_platform_name()    # -> "Android" | "iOS" | "None"
```

### Signals

```gdscript
# Both platforms
Firebase.auth_success(user_data: String)   # JSON user data
Firebase.auth_error(message: String)
Firebase.signed_out

# Link-specific (Android emits separately, iOS uses auth_success/auth_error)
Firebase.link_success(user_data: String)
Firebase.link_error(message: String)

# Android only
Firebase.password_reset_sent(success: bool)
Firebase.email_verification_sent(success: bool)
Firebase.user_deleted(success: bool)

# iOS only
Firebase.firebase_initialized
Firebase.firebase_error(message: String)
```

## Platform-Specific GDExtension Notes (godot#105615)

The iOS plugin uses a `.gdextension` file that only declares `ios.debug` and `ios.release` libraries. On non-iOS platforms:

- The `FirebaseAuthPlugin` class is not registered in ClassDB
- The wrapper detects this via `ClassDB.class_exists()` and falls back gracefully
- **Known issue**: Godot's GDExtension loader may emit warnings about missing libraries for the current platform. See [godotengine/godot#105615](https://github.com/godotengine/godot/issues/105615).

## License

MIT — see [LICENSE](LICENSE).
