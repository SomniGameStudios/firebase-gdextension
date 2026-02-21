@tool
extends EditorPlugin

var export_plugin: iOSExportPlugin

func _enter_tree() -> void:
	export_plugin = iOSExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null


class iOSExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return "GodotFirebaseiOS"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformIOS

	func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
		if not features.has("ios"):
			return
		const PLIST_PATH := "res://addons/GodotFirebaseiOS/GoogleService-Info.plist"
		if FileAccess.file_exists(PLIST_PATH):
			add_ios_bundle_file(PLIST_PATH)
		else:
			push_warning("GodotFirebaseiOS: GoogleService-Info.plist not found at " + PLIST_PATH + ". Firebase will fail to initialize. Place your GoogleService-Info.plist from the Firebase console into res://addons/GodotFirebaseiOS/")
