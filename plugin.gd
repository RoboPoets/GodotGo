@tool
extends EditorPlugin


var android_export_plugin: AndroidExportPlugin = null


func _enable_plugin():
	add_autoload_singleton("Go", "res://addons/godot_go/go.gd")


func _disable_plugin():
	remove_autoload_singleton("Go")


func _enter_tree()-> void:
	android_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(android_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(android_export_plugin)
	android_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	func _supports_platform(platform) -> bool:
		if platform is EditorExportPlatformAndroid:
			return true
		return false


	func _get_android_libraries(platform:EditorExportPlatform, debug:bool) -> PackedStringArray:
		if debug:
			return PackedStringArray(["godot_go/bin/GodotGo-debug.aar"])
		return PackedStringArray(["godot_go/bin/GodotGo-release.aar"])


	func _get_name() -> String:
		return "GodotGo"
