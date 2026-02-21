# Firebase Mobile Integration Demo

A Godot 4.4+ project demonstrating Firebase Authentication on **iOS and Android** from a single codebase.

> The Godot project lives in [`demo/`](demo/). Open `demo/project.godot` in the Godot editor.
> iOS plugin source is in [`addons_source_code/GodotFirebaseiOS/`](addons_source_code/GodotFirebaseiOS/).

## Features

- [x] Anonymous Sign-In (iOS + Android)
- [x] Google Sign-In (iOS + Android)
- [x] Link Anonymous → Google (iOS + Android)
- [x] Sign Out (iOS + Android)
- [x] Delete Account (iOS + Android)
- [x] Email/Password Auth (Android only)
- [ ] Email/Password Auth (iOS — coming soon)

---

## Architecture

A unified `FirebaseWrapper` autoload detects the platform at runtime and delegates to the correct native backend:

- **iOS** — SwiftGodot GDExtension (`FirebaseAuthPlugin` registered in ClassDB)
- **Android** — Kotlin Engine singleton ([GodotFirebaseAndroid](https://github.com/syntaxerror247/GodotFirebaseAndroid) by Anish Mishra)

```
autoload/firebase_wrapper.gd
    ├── Android: Engine.get_singleton("GodotFirebaseAndroid")
    └── iOS:     ClassDB.instantiate("FirebaseAuthPlugin")
```

---

## 🚀 Quick Start

### 1. Firebase Console

- Go to [console.firebase.google.com](https://console.firebase.google.com)
- Create a project and enable **Authentication → Sign-in Methods**: **Anonymous** and **Google**

---

### 2. iOS Setup

**a) Download credentials**
- Register an iOS app in the Firebase Console
- Download `GoogleService-Info.plist`
- Place it in `demo/addons/GodotFirebaseiOS/` (gitignored — never commit)

**b) Enable the plugin**
- In Godot: **Project → Project Settings → Plugins** → enable **GodotFirebaseiOS**

**c) Export**
- Export for iOS from Godot — the export plugin automatically:
  - Copies `GoogleService-Info.plist` into the Xcode project (Copy Bundle Resources)
  - Injects the `REVERSED_CLIENT_ID` URL scheme into `Info.plist` (required for Google Sign-In)
- Build and run in Xcode on a physical device (arm64)

---

### 3. Android Setup

- Register an Android app in the Firebase Console
- Download `google-services.json` and place it in:
  ```
  demo/android/build/google-services.json
  ```
- Follow the [GodotFirebaseAndroid setup guide](https://syntaxerror247.github.io/GodotFirebaseAndroid)
- Enable Gradle build in **Project → Export → Android**

---

## 🔨 Building the iOS Plugin from Source

After modifying Swift source files under `addons_source_code/GodotFirebaseiOS/`:

```bash
./scripts/build_ios_plugin.sh
```

This builds the Swift package with `xcodebuild` and copies the resulting `GodotFirebaseiOS.framework` into `demo/addons/GodotFirebaseiOS/` automatically.

**Requirements:** Xcode 15+, Swift 5.9+, macOS 14+

---

## 📖 GDScript API

All methods and signals are available through the `FirebaseWrapper` autoload.

### Methods — Both Platforms

```gdscript
FirebaseWrapper.sign_in_anonymously()
FirebaseWrapper.sign_in_with_google()
FirebaseWrapper.link_anonymous_with_google()
FirebaseWrapper.sign_out()
FirebaseWrapper.delete_current_user()
FirebaseWrapper.is_signed_in()           # -> bool
FirebaseWrapper.get_current_user_data()  # -> Dictionary
FirebaseWrapper.is_available()           # -> bool
FirebaseWrapper.get_platform_name()      # -> "Android" | "iOS" | "None"
```

### Methods — Android Only

```gdscript
FirebaseWrapper.create_user_with_email_password(email, password)
FirebaseWrapper.sign_in_with_email_password(email, password)
FirebaseWrapper.send_password_reset_email(email)
FirebaseWrapper.send_email_verification()
```

### Signals — Both Platforms

```gdscript
FirebaseWrapper.auth_success(current_user_data: Dictionary)
FirebaseWrapper.auth_failure(error_message: String)
FirebaseWrapper.sign_out_success(success: bool)
FirebaseWrapper.link_with_google_success(current_user_data: Dictionary)
FirebaseWrapper.link_with_google_failure(error_message: String)
FirebaseWrapper.user_deleted(success: bool)
```

### Signals — Android Only

```gdscript
FirebaseWrapper.password_reset_sent(success: bool)
FirebaseWrapper.email_verification_sent(success: bool)
```

### User Data Dictionary

`auth_success` and `get_current_user_data()` return a `Dictionary` with:

| Key | Type | Description |
|-----|------|-------------|
| `uid` | `String` | Firebase user ID |
| `email` | `String` | User email (empty for anonymous users) |
| `displayName` | `String` | Display name |
| `photoURL` | `String` | Profile photo URL |
| `isAnonymous` | `bool` | Whether the account is anonymous |

### Example

```gdscript
func _ready() -> void:
    FirebaseWrapper.auth_success.connect(_on_auth_success)
    FirebaseWrapper.auth_failure.connect(_on_auth_failure)

func _on_auth_success(user_data: Dictionary) -> void:
    print("Signed in: ", user_data.get("uid", ""))

func _on_auth_failure(error_message: String) -> void:
    print("Auth failed: ", error_message)

# Sign in anonymously
FirebaseWrapper.sign_in_anonymously()

# Sign in with Google
FirebaseWrapper.sign_in_with_google()

# Upgrade anonymous account to Google
FirebaseWrapper.link_anonymous_with_google()
```

---

## License

MIT — see [LICENSE](LICENSE).
