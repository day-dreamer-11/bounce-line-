extends Node2D
## Handles drag input — creates short lines for the ball to bounce off.

const LINE_LENGTH := 150.0

var _drag_start: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _current_line: Node2D = null
var _line_scene: PackedScene = null


func _ready() -> void:
	_line_scene = load("res://scenes/Line.tscn")
	# Pre-create the line instance for instant response
	_current_line = _line_scene.instantiate()
	_current_line.visible = false
	add_child(_current_line)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start = get_global_mouse_position()
			_is_dragging = true
		elif _is_dragging:
			_is_dragging = false
			_place_line(_drag_start, get_global_mouse_position())


func _place_line(start_pos: Vector2, end_pos: Vector2) -> void:
	var direction := end_pos - start_pos
	if direction.length() < 10.0:
		return

	var clamped_end := start_pos + direction.normalized() * LINE_LENGTH
	var midpoint := (start_pos + clamped_end) / 2.0
	var angle := direction.angle()

	_current_line.position = midpoint
	_current_line.rotation = angle
	_current_line.visible = true
	_current_line.reset_timer()


func _remove_current_line() -> void:
	if _current_line:
		_current_line.visible = false
