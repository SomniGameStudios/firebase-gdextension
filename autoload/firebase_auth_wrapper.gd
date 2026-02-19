extends Node

## Wrapper autoload for FirebaseAuthPlugin (iOS GDExtension).
## Uses ClassDB to conditionally instantiate the plugin so this script
## parses without errors on non-iOS platforms where the class doesn't exist.

signal firebase_initialized
signal firebase_error(message: String)
signal auth_success(user_json: String)
signal auth_error(message: String)
signal signed_out

var _plugin: RefCounted = null

func _ready() -> void:
	if ClassDB.class_exists(&"FirebaseAuthPlugin"):
		_plugin = ClassDB.instantiate(&"FirebaseAuthPlugin")
		_plugin.connect("firebase_initialized", func(): firebase_initialized.emit())
		_plugin.connect("firebase_error", func(msg): firebase_error.emit(msg))
		_plugin.connect("auth_success", func(json): auth_success.emit(json))
		_plugin.connect("auth_error", func(msg): auth_error.emit(msg))
		_plugin.connect("signed_out", func(): signed_out.emit())
		_plugin.initialize()
	else:
		push_warning("FirebaseAuthPlugin not available. Auth calls will be no-ops.")

func sign_in_anonymously() -> void:
	if _plugin:
		_plugin.sign_in_anonymously()

func sign_in_with_google() -> void:
	if _plugin:
		_plugin.sign_in_with_google()

func link_anonymous_with_google() -> void:
	if _plugin:
		_plugin.link_anonymous_with_google()

func sign_out_user() -> void:
	if _plugin:
		_plugin.sign_out()

func is_signed_in() -> bool:
	if _plugin:
		return _plugin.is_signed_in()
	return false

func is_anonymous() -> bool:
	if _plugin:
		return _plugin.is_anonymous()
	return false

func get_uid() -> String:
	if _plugin:
		return _plugin.get_uid()
	return ""

func get_current_user() -> String:
	if _plugin:
		return _plugin.get_current_user()
	return ""
