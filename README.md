# Firebase iOS GDExtension Demo

A minimal Godot 4.6 demo showing Firebase Authentication on iOS via a **SwiftGodot GDExtension** plugin.

This project serves two purposes:

1. **Demonstrate that integrating Firebase on iOS with SwiftGodot is simpler** than the [godot-mobile-plugins](https://github.com/godot-mobile-plugins/godot-firebase) approach — fewer files, less boilerplate, real typed classes instead of opaque singletons.

2. **Provide a reference for platform-specific GDExtension plugins** and the challenges discussed in [godotengine/godot#105615](https://github.com/godotengine/godot/issues/105615).

Modeled after [GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid) by Anish Mishra.

## How It Works

The `GodotFirebaseiOS.framework` in `addons/GodotFirebaseiOS/` is a compiled SwiftGodot GDExtension that registers a `FirebaseAuthPlugin` class into Godot's ClassDB. The demo wraps it with a thin autoload ([autoload/firebase_auth_wrapper.gd](autoload/firebase_auth_wrapper.gd)) that:

- Uses `ClassDB.class_exists()` + `ClassDB.instantiate()` so the script **parses without errors on non-iOS platforms**
- Re-emits all signals for scene scripts to connect to
- Provides safe no-op fallbacks when the plugin is unavailable (editor, desktop)

### GDExtension vs Engine Singleton (godot-mobile-plugins)

| Aspect | godot-mobile-plugins (Singleton) | This demo (GDExtension) |
|--------|----------------------------------|------------------------|
| Registration | `Engine.get_singleton("PluginName")` | `ClassDB.class_exists("FirebaseAuthPlugin")` |
| Instantiation | Opaque `Object` from Engine | `ClassDB.instantiate()` → typed `RefCounted` |
| Method naming | Java-style (`signInAnonymously`) | Godot snake_case (`sign_in_anonymously`) |
| Editor support | No autocomplete, no type info | RefCounted subclass, editor-friendly |
| Boilerplate | Export plugin GDScript + module wrappers + Gradle injection | Single `.gdextension` file + framework |

## Requirements

- Godot 4.4+
- Xcode 15+, Swift 5.9+
- iOS 17+ device or simulator (arm64)

## Setup

### 1. Firebase Console

- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Enable **Anonymous** and **Google Sign-In** providers under Authentication > Sign-in method
- Register an iOS app with your bundle identifier
- Download `GoogleService-Info.plist`

### 2. Godot Project

- Place `GoogleService-Info.plist` in your Godot project root (it will be copied to the iOS export)
- Update `export_presets.cfg` with your bundle identifier

### 3. Xcode (after Godot export)

- Export the project for iOS from Godot
- In the Xcode trampoline project, add a `CFBundleURLTypes` entry in Info.plist with your `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` (required for Google Sign-In)
- Build, archive, and deploy to device or TestFlight

## GDScript API

All methods are available through the `FirebaseAuth` autoload:

```gdscript
# Sign-in
FirebaseAuth.sign_in_anonymously()
FirebaseAuth.sign_in_with_google()
FirebaseAuth.link_anonymous_with_google()

# Query
FirebaseAuth.is_signed_in()    # -> bool
FirebaseAuth.is_anonymous()    # -> bool
FirebaseAuth.get_uid()         # -> String
FirebaseAuth.get_current_user() # -> String (JSON)

# Sign-out
FirebaseAuth.sign_out_user()
```

### Signals

```gdscript
FirebaseAuth.firebase_initialized   # Firebase ready
FirebaseAuth.firebase_error(msg)    # Initialization error
FirebaseAuth.auth_success(user_json) # Auth succeeded (JSON user data)
FirebaseAuth.auth_error(msg)        # Auth failed
FirebaseAuth.signed_out             # User signed out
```

## Platform-Specific GDExtension Notes (godot#105615)

This plugin only targets iOS — the `.gdextension` file only declares `ios.debug` and `ios.release` libraries. On non-iOS platforms:

- The `FirebaseAuthPlugin` class is not registered in ClassDB
- The autoload wrapper detects this via `ClassDB.class_exists()` and gracefully falls back to no-ops
- **Known issue**: Godot's GDExtension loader may emit warnings about missing libraries for the current platform, even though the extension was never meant to run there. See [godotengine/godot#105615](https://github.com/godotengine/godot/issues/105615) for discussion.

## License

MIT — see [LICENSE](LICENSE).
