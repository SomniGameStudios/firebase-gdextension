extends Control

@onready var output: RichTextLabel = %OutputPanel

func _ready() -> void:
	FirebaseAuth.firebase_initialized.connect(_on_signal.bind("firebase_initialized"))
	FirebaseAuth.firebase_error.connect(_on_signal_msg.bind("firebase_error"))
	FirebaseAuth.auth_success.connect(_on_signal_msg.bind("auth_success"))
	FirebaseAuth.auth_error.connect(_on_signal_msg.bind("auth_error"))
	FirebaseAuth.signed_out.connect(_on_signal.bind("signed_out"))

func _on_signal(context: String) -> void:
	_log(context, "OK")

func _on_signal_msg(arg: String, context: String) -> void:
	_log(context, arg)

func _log(context: String, message: String) -> void:
	var t = Time.get_time_string_from_system()
	output.text += "[%s] %s: %s\n" % [t, context, message]
	await get_tree().process_frame
	output.scroll_to_line(output.get_line_count())

# --- Navigation ---

func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(preload("res://main.tscn"))

# --- Sign-in ---

func _on_sign_in_anonymous_pressed() -> void:
	_log("action", "Signing in anonymously...")
	FirebaseAuth.sign_in_anonymously()

func _on_sign_in_google_pressed() -> void:
	_log("action", "Signing in with Google...")
	FirebaseAuth.sign_in_with_google()

func _on_link_anonymous_google_pressed() -> void:
	_log("action", "Linking anonymous account with Google...")
	FirebaseAuth.link_anonymous_with_google()

# --- Query ---

func _on_get_user_pressed() -> void:
	var user = FirebaseAuth.get_current_user()
	_log("get_current_user", user if user else "(no user)")

func _on_get_uid_pressed() -> void:
	var uid = FirebaseAuth.get_uid()
	_log("get_uid", uid if uid else "(no uid)")

func _on_is_signed_in_pressed() -> void:
	_log("is_signed_in", str(FirebaseAuth.is_signed_in()))

func _on_is_anonymous_pressed() -> void:
	_log("is_anonymous", str(FirebaseAuth.is_anonymous()))

# --- Sign-out ---

func _on_sign_out_pressed() -> void:
	_log("action", "Signing out...")
	FirebaseAuth.sign_out_user()

# --- Utility ---

func _on_clear_output_pressed() -> void:
	output.text = ""
