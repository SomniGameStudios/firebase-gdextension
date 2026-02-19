extends Control

@onready var output: RichTextLabel = %OutputPanel
@onready var email_input: LineEdit = %EmailInput
@onready var password_input: LineEdit = %PasswordInput

func _ready() -> void:
	FirebaseWrapper.auth_success.connect(_on_auth_success)
	FirebaseWrapper.auth_error.connect(_on_auth_error)
	FirebaseWrapper.signed_out.connect(_on_signed_out)
	FirebaseWrapper.link_success.connect(_on_link_success)
	FirebaseWrapper.link_error.connect(_on_link_error)
	FirebaseWrapper.password_reset_sent.connect(_on_password_reset_sent)
	FirebaseWrapper.email_verification_sent.connect(_on_email_verification_sent)
	FirebaseWrapper.user_deleted.connect(_on_user_deleted)
	FirebaseWrapper.firebase_initialized.connect(_on_firebase_initialized)
	FirebaseWrapper.firebase_error.connect(_on_firebase_error)

	_log("platform", FirebaseWrapper.get_platform_name())

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
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	output.scroll_to_line(output.get_line_count())

# --- Navigation ---

func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://main.tscn"))

# --- Sign-in (both platforms) ---

func _on_sign_in_anonymous_pressed() -> void:
	_log("action", "Signing in anonymously...")
	FirebaseWrapper.sign_in_anonymously()

func _on_sign_in_google_pressed() -> void:
	_log("action", "Signing in with Google...")
	FirebaseWrapper.sign_in_with_google()

func _on_link_anonymous_google_pressed() -> void:
	_log("action", "Linking anonymous account with Google...")
	FirebaseWrapper.link_anonymous_with_google()

# --- Sign-in (Android only - email) ---

func _on_email_sign_up_pressed() -> void:
	_log("action", "Creating user with email...")
	FirebaseWrapper.create_user_with_email_password(email_input.text, password_input.text)

func _on_email_sign_in_pressed() -> void:
	_log("action", "Signing in with email...")
	FirebaseWrapper.sign_in_with_email_password(email_input.text, password_input.text)

func _on_email_verification_pressed() -> void:
	_log("action", "Sending email verification...")
	FirebaseWrapper.send_email_verification()

func _on_password_reset_pressed() -> void:
	_log("action", "Sending password reset email...")
	FirebaseWrapper.send_password_reset_email(email_input.text)

# --- Query ---

func _on_get_user_pressed() -> void:
	var user = FirebaseWrapper.get_current_user()
	_log("get_current_user", user if user else "(no user)")

func _on_get_uid_pressed() -> void:
	var uid = FirebaseWrapper.get_uid()
	_log("get_uid", uid if uid else "(no uid)")

func _on_is_signed_in_pressed() -> void:
	_log("is_signed_in", str(FirebaseWrapper.is_signed_in()))

func _on_is_anonymous_pressed() -> void:
	_log("is_anonymous", str(FirebaseWrapper.is_anonymous()))

# --- Sign-out / Delete ---

func _on_sign_out_pressed() -> void:
	_log("action", "Signing out...")
	FirebaseWrapper.sign_out_user()

func _on_delete_user_pressed() -> void:
	_log("action", "Deleting current user...")
	FirebaseWrapper.delete_current_user()

# --- Utility ---

func _on_clear_output_pressed() -> void:
	output.text = ""
