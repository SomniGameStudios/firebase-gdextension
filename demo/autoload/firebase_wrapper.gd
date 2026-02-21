extends Node

## Unified Firebase wrapper that detects the platform at runtime and delegates
## to the appropriate native plugin:
##   - Android: Engine singleton "GodotFirebaseAndroid" (Kotlin AAR)
##   - iOS: GDExtension class "FirebaseAuthPlugin" (SwiftGodot framework)
##   - Desktop/editor: no-ops with warning

# --- Unified auth signals — match GodotFirebaseAndroid Auth API exactly ---
signal auth_success(current_user_data: Dictionary)
signal auth_failure(error_message: String)
signal sign_out_success(success: bool)
signal link_success(current_user_data: Dictionary)
signal link_failure(error_message: String)
signal password_reset_sent(success: bool)
signal email_verification_sent(success: bool)
signal user_deleted(success: bool)

enum Platform { NONE, ANDROID, IOS }

var _platform: int = Platform.NONE
var _android_plugin: Object = null  # Engine singleton
var _ios_plugin: RefCounted = null   # GDExtension class

func _ready() -> void:
	if Engine.has_singleton("GodotFirebaseAndroid"):
		_platform = Platform.ANDROID
		_android_plugin = Engine.get_singleton("GodotFirebaseAndroid")
		_connect_android_signals()
		print("Firebase: Android plugin initialized")
	elif ClassDB.class_exists(&"FirebaseAuthPlugin"):
		_platform = Platform.IOS
		_ios_plugin = ClassDB.instantiate(&"FirebaseAuthPlugin")
		_connect_ios_signals()
		_ios_plugin.initialize()
		print("Firebase: iOS plugin initialized")
	else:
		push_warning("Firebase: No native plugin available. Auth calls will be no-ops.")

# --- Android signal connections ---

func _connect_android_signals() -> void:
	_android_plugin.connect("auth_success", _on_android_auth_success)
	_android_plugin.connect("auth_failure", _on_android_auth_failure)
	_android_plugin.connect("link_with_google_success", _on_android_link_success)
	_android_plugin.connect("link_with_google_failure", _on_android_link_failure)
	_android_plugin.connect("sign_out_success", _on_android_sign_out_success)
	_android_plugin.connect("password_reset_sent", _on_android_password_reset_sent)
	_android_plugin.connect("email_verification_sent", _on_android_email_verification_sent)
	_android_plugin.connect("user_deleted", _on_android_user_deleted)

func _on_android_auth_success(user_dict: Dictionary) -> void:
	auth_success.emit(user_dict)

func _on_android_auth_failure(msg: String) -> void:
	auth_failure.emit(msg)

func _on_android_link_success(user_dict: Dictionary) -> void:
	link_success.emit(user_dict)

func _on_android_link_failure(msg: String) -> void:
	link_failure.emit(msg)

func _on_android_sign_out_success(success: bool) -> void:
	sign_out_success.emit(success)

func _on_android_password_reset_sent(success: bool) -> void:
	password_reset_sent.emit(success)

func _on_android_email_verification_sent(success: bool) -> void:
	email_verification_sent.emit(success)

func _on_android_user_deleted(success: bool) -> void:
	user_deleted.emit(success)

# --- iOS signal connections ---

func _connect_ios_signals() -> void:
	# Internal iOS signals (log only, not part of public API)
	_ios_plugin.connect("firebase_initialized", _on_ios_firebase_initialized)
	_ios_plugin.connect("firebase_error", _on_ios_firebase_error)
	# Public signals — match Android API
	_ios_plugin.connect("auth_success", _on_ios_auth_success)
	_ios_plugin.connect("auth_failure", _on_ios_auth_failure)
	_ios_plugin.connect("sign_out_success", _on_ios_sign_out_success)

func _on_ios_firebase_initialized() -> void:
	print("Firebase: iOS initialized successfully")

func _on_ios_firebase_error(msg: String) -> void:
	push_error("Firebase: iOS initialization error: " + msg)

func _on_ios_auth_success(user_dict: Dictionary) -> void:
	auth_success.emit(user_dict)

func _on_ios_auth_failure(msg: String) -> void:
	auth_failure.emit(msg)

func _on_ios_sign_out_success(success: bool) -> void:
	sign_out_success.emit(success)

# --- Helpers ---

func is_available() -> bool:
	return _platform != Platform.NONE

func get_platform_name() -> String:
	match _platform:
		Platform.ANDROID: return "Android"
		Platform.IOS: return "iOS"
		_: return "None"

# --- Auth methods (both platforms) ---

func sign_in_anonymously() -> void:
	match _platform:
		Platform.ANDROID: _android_plugin.signInAnonymously()
		Platform.IOS: _ios_plugin.sign_in_anonymously()

func sign_in_with_google() -> void:
	match _platform:
		Platform.ANDROID: _android_plugin.signInWithGoogle()
		Platform.IOS: _ios_plugin.sign_in_with_google()

func link_anonymous_with_google() -> void:
	match _platform:
		Platform.ANDROID: _android_plugin.linkAnonymousWithGoogle()
		Platform.IOS: _ios_plugin.link_anonymous_with_google()

func sign_out() -> void:
	match _platform:
		Platform.ANDROID: _android_plugin.signOut()
		Platform.IOS: _ios_plugin.sign_out()

func is_signed_in() -> bool:
	match _platform:
		Platform.ANDROID: return _android_plugin.isSignedIn()
		Platform.IOS: return _ios_plugin.is_signed_in()
	return false

func get_current_user_data() -> Dictionary:
	match _platform:
		Platform.ANDROID:
			return _android_plugin.getCurrentUser()
		Platform.IOS:
			return _ios_plugin.get_current_user_data()
	return {}

# --- Android-only methods ---

func create_user_with_email_password(email: String, password: String) -> void:
	if _platform == Platform.ANDROID:
		_android_plugin.createUserWithEmailPassword(email, password)

func sign_in_with_email_password(email: String, password: String) -> void:
	if _platform == Platform.ANDROID:
		_android_plugin.signInWithEmailPassword(email, password)

func send_password_reset_email(email: String) -> void:
	if _platform == Platform.ANDROID:
		_android_plugin.sendPasswordResetEmail(email)

func send_email_verification() -> void:
	if _platform == Platform.ANDROID:
		_android_plugin.sendEmailVerification()

func delete_current_user() -> void:
	if _platform == Platform.ANDROID:
		_android_plugin.deleteUser()
