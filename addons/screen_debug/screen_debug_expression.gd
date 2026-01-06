@tool
class_name ScreenDebugExpression extends Resource

@export var visible: bool = true

@export var label: String

@export_multiline var expression: String


var _owner: ScreenDebug


func _init_owner(p_owner: ScreenDebug) -> void:
	_owner = p_owner
