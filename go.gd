extends Node


## Emits when the geolocation plugin updates the device's current position.
signal location_changed(location:Vector2)

## Emits when a user grants an explicit permission request made by the app.
signal permissions_granted

## Emits when a user denies an explicit permission request made by the app.
signal permissions_denied

## Emits when the app encounters a permission problem that is caused by users
## changing permission settings outside the app.
signal permissions_revoked

const _android_plugin_name := "GodotGo"
const _ios_plugin_name := "GodotGo"

@onready var _os := OS.get_name()

var _android_plugin = null
var _ios_plugin = null

# The debug location is only ever used on desktop systems. Instead of the
# device's GPS module, movement input is read from the keyboard. This allows
# users to test location data functionality without the need for mobile devices.
var _debug_location := Vector2.ZERO

# The scale defines the debug movement sensitivity.
var _debug_input_scale := 0.0005

func _ready() -> void:
	if _os == "Android":
		if Engine.has_singleton(_android_plugin_name):
			_android_plugin = Engine.get_singleton(_android_plugin_name)
			_android_plugin.location_updated.connect(_on_location_updated)
			_android_plugin.permissions_revoked.connect(_on_permissions_revoked)
		else:
			printerr("Couldn't find native geolocation library " + _android_plugin_name)

	if _os == "iOS":
		printerr("Geolocation on iOS devices is not yet supported")

	set_physics_process(_os != "Android" and _os != "iOS")
	get_tree().on_request_permissions_result.connect(_on_permission_request_result)


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_down", "ui_up", "ui_left", "ui_right")
	if dir.is_zero_approx():
		return

	_debug_location += dir * _debug_input_scale * delta
	location_changed.emit(_debug_location)


func _on_location_updated(lat:String, long:String) -> void:
	location_changed.emit(Vector2(float(lat), float(long)))


func _on_permissions_revoked() -> void:
	permissions_revoked.emit()


func _on_permission_request_result(perm:String, granted:bool):
	if granted:
		call_deferred("emit_signal", "permissions_granted")
	else:
		call_deferred("emit_signal", "permissions_denied")


func activate_location_updates() -> void:
	if _has_all_permissions():
		_activate_location_updates()
		return

	if not permissions_granted.is_connected(_activate_location_updates):
		permissions_granted.connect(_activate_location_updates)

	OS.request_permissions()


func deactivate_location_updates() -> void:
	if _os == "Android" && _android_plugin:
		_android_plugin.deactivate_location_updates()


func set_debug_location(loc:Vector2) -> void:
	_debug_location = loc
	location_changed.emit(_debug_location)


func get_single_location_update() -> void:
	if _has_all_permissions():
		_get_single_location_update()
		return

	if not permissions_granted.is_connected(_get_single_location_update):
		permissions_granted.connect(_get_single_location_update)

	OS.request_permissions()


func _has_all_permissions() -> bool:
	var perms := OS.get_granted_permissions()
	prints(perms)
	return "android.permission.ACCESS_COARSE_LOCATION" in perms \
		and "android.permission.ACCESS_FINE_LOCATION" in perms


func _activate_location_updates() -> void:
	if permissions_granted.is_connected(_activate_location_updates):
		permissions_granted.disconnect(_activate_location_updates)

	if _os == "Android" && _android_plugin:
		_android_plugin.activate_location_updates()


func _get_single_location_update() -> void:
	if permissions_granted.is_connected(_get_single_location_update):
		permissions_granted.disconnect(_get_single_location_update)

	if _os == "Android" && _android_plugin:
		_android_plugin.get_location_update()
