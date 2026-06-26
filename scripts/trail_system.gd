extends Node2D
## Real-time trail — smooth snake-like tail following the mouse.

const LINE_WIDTH := 16.0
const POINT_LIFETIME := 2.0
const MIN_SAMPLE_DIST := 6.0

var _is_drawing := false

## {position: Vector2, time: float}
var _points: Array[Dictionary] = []

@onready var _line: Line2D = $Line2D


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.98, 0.98, 0.98))

	_line.clear_points()
	_line.width = LINE_WIDTH
	_line.default_color = Color.BLACK
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.joint_mode = Line2D.LINE_JOINT_ROUND


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_drawing = true
			_points.clear()  # Don't connect to old trail
		else:
			_is_drawing = false


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	if _is_drawing:
		var pos := get_global_mouse_position()
		if _points.is_empty() or pos.distance_to(_points[-1].position) >= MIN_SAMPLE_DIST:
			_points.append({position = pos, time = now})

	while not _points.is_empty() and now - _points[0].time > POINT_LIFETIME:
		_points.pop_front()

	var pts := PackedVector2Array()
	pts.resize(_points.size())
	for i in _points.size():
		pts[i] = _points[i].position
	_line.points = pts
