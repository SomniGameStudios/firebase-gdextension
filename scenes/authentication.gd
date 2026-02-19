extends Control

@onready var output: RichTextLabel = %OutputPanel
@onready var email_input: LineEdit = %EmailInput
@onready var password_input: LineEdit = %PasswordInput

func _ready() -> void:
	Firebase.auth_success.connect(_on_auth_success)
	Firebase.auth_error.connect(_on_auth_error)
	Firebase.signed_out.connect(_on_signed_out)
	Firebase.link_success.connect(_on_link_success)
	Firebase.link_error.connect(_on_link_error)
	Firebase.password_reset_sent.connect(_on_password_reset_sent)
	Firebase.email_verification_sent.connect(_on_email_verification_sent)
	Firebase.user_deleted.connect(_on_user_deleted)
	Firebase.firebase_initialized.connect(_on_firebase_initialized)
	Firebase.firebase_error.connect(_on_firebase_error)

	_log("platform", Firebase.get_platform_name())

# --- Signal handlers ---

func _on_auth_success(user_data: String) -> void:
	_log("auth_success", user_data)

func _on_auth_error(message: String) -> void:
	_log("auth_error", message)

func _on_signed_out() -> void:
	_log("signed_out", "OK")

func _on_link_success(user_data: String) -> void:
	_log("link_success", user_data)

func _on_link_error(message: String) -> void:
	_log("link_error", message)

func _on_password_reset_sent(success: bool) -> void:
	_log("password_reset_sent", str(success))

func _on_email_verification_sent(success: bool) -> void:
	_log("email_verification_sent", str(success))

func _on_user_deleted(success: bool) -> void:
	_log("user_deleted", str(success))

func _on_firebase_initialized() -> void:
	_log("firebase_initialized", "OK")

func _on_firebase_error(message: String) -> void:
	_log("firebase_error", message)

# --- Logging ---

func _log(context: String, message: String) -> void:
	var t = Time.get_time_string_from_system()
	output.text += "[%s] %s: %s\n" % [t, context, message]
	await get_tree().process_frame
	output.scroll_to_line(output.get_line_count())

# --- Navigation ---

func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://main.tscn"))

# --- Sign-in (both platforms) ---

func _on_sign_in_anonymous_pressed() -> void:
	_log("action", "Signing in anonymously...")
	Firebase.sign_in_anonymously()

func _on_sign_in_google_pressed() -> void:
	_log("action", "Signing in with Google...")
	Firebase.sign_in_with_google()

func _on_link_anonymous_google_pressed() -> void:
	_log("action", "Linking anonymous account with Google...")
	Firebase.link_anonymous_with_google()

# --- Sign-in (Android only - email) ---

func _on_email_sign_up_pressed() -> void:
	_log("action", "Creating user with email...")
	Firebase.create_user_with_email_password(email_input.text, password_input.text)

func _on_email_sign_in_pressed() -> void:
	_log("action", "Signing in with email...")
	Firebase.sign_in_with_email_password(email_input.text, password_input.text)

func _on_email_verification_pressed() -> void:
	_log("action", "Sending email verification...")
	Firebase.send_email_verification()

func _on_password_reset_pressed() -> void:
	_log("action", "Sending password reset email...")
	Firebase.send_password_reset_email(email_input.text)

# --- Query ---

func _on_get_user_pressed() -> void:
	var user = Firebase.get_current_user()
	_log("get_current_user", user if user else "(no user)")

func _on_get_uid_pressed() -> void:
	var uid = Firebase.get_uid()
	_log("get_uid", uid if uid else "(no uid)")

func _on_is_signed_in_pressed() -> void:
	_log("is_signed_in", str(Firebase.is_signed_in()))

func _on_is_anonymous_pressed() -> void:
	_log("is_anonymous", str(Firebase.is_anonymous()))

# --- Sign-out / Delete ---

func _on_sign_out_pressed() -> void:
	_log("action", "Signing out...")
	Firebase.sign_out_user()

func _on_delete_user_pressed() -> void:
	_log("action", "Deleting current user...")
	Firebase.delete_current_user()

# --- Utility ---

func _on_clear_output_pressed() -> void:
	output.text = ""
