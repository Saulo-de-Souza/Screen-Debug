@tool
@icon("res://addons/screen_debug/icon.svg")


## ScreenDebug
## Displays a runtime debug overlay for inspecting properties and calling methods.
class_name ScreenDebug extends CanvasLayer


#region EXPORTS
@export_group("Debug", "debug_")
## Enables or disables the debug overlay visibility and process.
@export var debug_active: bool = true:
	set(value):
		debug_active = value
		visible = debug_active


## Optional title displayed at the top of the debug panel.
@export_placeholder("Title") var debug_title: String


## CanvasLayer rendering layer.
@export_range(0, 10, 1, "or_less", "or_greater") var debug_layer: int = 1:
	set(value):
		debug_layer = value
		layer = debug_layer


## Target node whose properties and methods will be inspected.
@export var debug_target: Node


@export_group("Debug/Font", "debug_")
## Font size for both normal and bold text.
@export_range(0.0, 40.0, 0.01, "or_greater") var debug_font_size: float = 30.0:
	set(value):
		debug_font_size = value
		if is_instance_valid(_screen_debug):
			_screen_debug.normal_font_size = debug_font_size
			_screen_debug.bold_font_size = debug_font_size


## Vertical spacing between text lines.
@export_range(0.0, 40.0, 0.01, "or_greater") var debug_line_spacing: float = 0.0:
	set(value):
		debug_line_spacing = value
		if is_instance_valid(_screen_debug):
			_screen_debug.line_separation = debug_line_spacing


## Outline thickness applied to the font.
@export_range(0.0, 40.0, 0.01, "or_greater") var debug_font_outline: float = 0.0:
	set(value):
		debug_font_outline = value
		if is_instance_valid(_screen_debug):
			_screen_debug.outline_size = debug_font_outline


## Default font color.
@export_color_no_alpha() var debug_default_font_color: Color = Color.WHITE:
	set(value):
		debug_default_font_color = value
		if is_instance_valid(_screen_debug):
			_screen_debug.default_font_color = debug_default_font_color


## Font color used for property and method keys.
@export_color_no_alpha() var debug_key_font_color: Color = Color.WHITE:
	set(value):
		debug_key_font_color = value


## Font color used for property and method values.
@export_color_no_alpha() var debug_value_font_color: Color = Color.WHITE:
	set(value):
		debug_value_font_color = value


@export_group("Debug/Background", "debug_")
## Background panel color.
@export_color_no_alpha() var debug_background_color: Color = Color.BLACK:
	set(value):
		debug_background_color = value
		if is_instance_valid(_screen_debug):
			_screen_debug.display_color = debug_background_color


## Background panel opacity.
@export_range(0.0, 1.0, 0.0001) var debug_background_opacity: float = 0.3:
	set(value):
		debug_background_opacity = value
		if is_instance_valid(_screen_debug):
			_screen_debug.display_opacity = debug_background_opacity


## Background panel size.
@export var debug_background_size: Vector2 = Vector2(500, 500):
	set(value):
		debug_background_size = value
		if is_instance_valid(_screen_debug):
			_screen_debug.set_display_size(debug_background_size)


## Background panel position on screen.
@export var debug_background_position: Vector2 = Vector2(0, 0):
	set(value):
		debug_background_position = value
		if is_instance_valid(_screen_debug):
			_screen_debug.display_position = debug_background_position


## Inner padding between background and text.
@export_range(0.0, 1000.0, 0.01, "or_greater") var debug_background_padding: float = 50.0:
	set(value):
		debug_background_padding = value
		if is_instance_valid(_screen_debug):
			_screen_debug.margin = debug_background_padding


@export_group("Debug/Config")
## Number of decimal places for float formatting.
@export_range(0, 4, 1, "prefer_slider") var floats_decimal_places: int = 2

## Number of decimal places for vector component formatting.
@export_range(0, 4, 1, "prefer_slider") var floats_vector_places: int = 2

## Time interval (in seconds) between debug updates.
@export_range(0.05, 2.0, 0.05) var update_interval := 0.2

## List of methods that are blocked from execution for safety.
@export var not_allowed_methods: PackedStringArray = ["queue_free", "add_child", "set_process", "move_and_slide"]

## Dictionary mapping labels to property paths.
@export var properties: Dictionary[String, String]

## Dictionary mapping labels to method calls.
@export var methods: Dictionary[String, String]
#endregion


#region CONSTANTS
const PARAM_FORMAT_HINT := """
Param format:
String:value
int:10
float:0.5
bool:true
Vector2:x,y
Vector3:x,y,z
Vector4:x,y,z,w
"""
#endregion


#region PRIVATE PROPERTIES
var _screen_debug_packed_scene: PackedScene = preload("res://addons/screen_debug/scenes/screen_debug_packed_scene.tscn")
var _screen_debug: Panel
var _accum := 0.0
var _warned: bool = false
#endregion


#region ENGINE METHODS
func _ready() -> void:
	_screen_debug = _screen_debug_packed_scene.duplicate(true).instantiate()

	_screen_debug.normal_font_size = debug_font_size
	_screen_debug.bold_font_size = debug_font_size
	_screen_debug.line_separation = debug_line_spacing
	_screen_debug.outline_size = debug_font_outline
	_screen_debug.default_font_color = debug_default_font_color
	_screen_debug.display_color = debug_background_color
	_screen_debug.display_opacity = debug_background_opacity
	_screen_debug.display_size = debug_background_size
	_screen_debug.display_position = debug_background_position
	_screen_debug.margin = debug_background_padding

	add_child.call_deferred(_screen_debug)
	await _screen_debug.tree_entered


func _process(delta):
	if is_development():
		return
	_accum += delta
	if _accum < update_interval:
		return
	_accum = 0.0

	_update_debug()
#endregion


#region INTERNAL EXECUTION
func _execute_method(key: String, raw: String, debug_target: Node) -> String:
	var div := raw.split("/")
	var method := div[0]

	if not_allowed_methods.size() > 0 and not_allowed_methods.has(method):
		push_warning("Method not allowed: %s" % method)
		return ""


	if not debug_target.has_method(method):
		push_warning("Method (%s) not found." % method)
		return ""

	var args: Array = []

	for i in range(1, div.size()):
		var param := _parse_param(div[i])
		if param == null:
			push_warning("Invalid param in (%s)\n%s" % [raw, PARAM_FORMAT_HINT])

			return ""
		args.append(param)

	var callable := Callable(debug_target, method)
	if not callable.is_valid():
		push_warning("Callable invalid: %s" % method)
		return ""

	var result := callable.callv(args)
	var raw2: Variant = result
	var value: String = format_value(raw2)
	
	if value.contains("tool mode"):
		value = ""
	var result_format: String = "[color=%s][b]%s[/b]:[/color] [color=%s]" + value + "[/color]\n"
	return result_format % [debug_key_font_color.to_html(), key, debug_value_font_color.to_html()]


func _parse_param(text: String) -> Variant:
	text = text.strip_edges()

	if text.begins_with("String:"):
		return text.replace("String:", "")

	if text.begins_with("int:"):
		return int(text.replace("int:", ""))

	if text.begins_with("float:"):
		return float(text.replace("float:", ""))

	if text.begins_with("bool:"):
		var v := text.replace("bool:", "")
		if v == "true":
			return true
		if v == "false":
			return false
		return null

	if text.begins_with("Vector2:"):
		var p := text.replace("Vector2:", "").split(",")
		if p.size() != 2:
			return null
		return Vector2(p[0].to_float(), p[1].to_float())

	if text.begins_with("Vector3:"):
		var p := text.replace("Vector3:", "").split(",")
		if p.size() != 3:
			return null
		return Vector3(p[0].to_float(), p[1].to_float(), p[2].to_float())

	if text.begins_with("Vector4:"):
		var p := text.replace("Vector4:", "").split(",")
		if p.size() != 4:
			return null
		return Vector4(
			p[0].to_float(),
			p[1].to_float(),
			p[2].to_float(),
			p[3].to_float()
		)

	return null


func _update_debug() -> void:
	if not debug_active:
		return

	if not is_instance_valid(debug_target):
		return
		
	if not is_instance_valid(_screen_debug):
		return

	_screen_debug.clear_text()
		
	if debug_title.strip_edges() != "":
		_screen_debug.append_text("[color=%s][b]%s[/b][/color]\n" % [debug_default_font_color.to_html(), debug_title])

	# Properties
	for key in properties:
		var prop := properties[key]
		if prop:
			var raw: Variant = debug_target.get_indexed(NodePath(prop))
			var value: String = format_value(raw)

			if value.contains("tool mode"):
				value = ""

			_screen_debug.append_text("[color=%s][b]%s[/b]:[/color] " % [debug_key_font_color.to_html(), key])
			_screen_debug.append_text("[color=%s]%s[/color]" % [debug_value_font_color.to_html(), value + "\n"])

	# Methods
	for key in methods:
		var raw := methods[key]
		if raw:
			_screen_debug.append_text(_execute_method(key, raw, debug_target))


func format_value(v: Variant) -> String:
	match typeof(v):
		TYPE_FLOAT:
			return _format_float(v, floats_decimal_places)

		TYPE_INT:
			return str(v)

		TYPE_BOOL:
			return str(v)

		TYPE_VECTOR2:
			return _format_vector2(v, floats_vector_places)

		TYPE_VECTOR3:
			return _format_vector3(v, floats_vector_places)

		TYPE_VECTOR4:
			return _format_vector4(v, floats_vector_places)

		_:
			return str(v)


func _format_float(v: float, decimals: int) -> String:
	decimals = clamp(decimals, 0, 10)
	var format := "%." + str(decimals) + "f"
	return format % v


func _format_vector2(v: Vector2, decimals: int) -> String:
	return "Vector2(%s, %s)" % [
		_format_float(v.x, decimals),
		_format_float(v.y, decimals)
	]


func _format_vector3(v: Vector3, decimals: int) -> String:
	return "Vector3(%s, %s, %s)" % [
		_format_float(v.x, decimals),
		_format_float(v.y, decimals),
		_format_float(v.z, decimals)
	]


func _format_vector4(v: Vector4, decimals: int) -> String:
	return "Vector4(%s, %s, %s, %s)" % [
		_format_float(v.x, decimals),
		_format_float(v.y, decimals),
		_format_float(v.z, decimals),
		_format_float(v.w, decimals)
	]


func is_development() -> bool:
	if not Engine.is_editor_hint() and not OS.is_debug_build():
		set_process(false)
		set_physics_process(false)
		debug_active = false

		if not _warned:
			push_warning(
				"ScreenDebug detected in RELEASE build. " +
				"Remove it before publishing the game."
			)
			_warned = true

		return true
	return false
#endregion
