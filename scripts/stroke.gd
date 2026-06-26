extends Node2D
## A single stroke — owns a Line2D, manages point lifetimes independently.

const LINE_WIDTH := 16.0
const POINT_LIFETIME := 2.0
const MIN_SAMPLE_DIST := 6.0

var _points: Array[Dictionary] = []  # [{position, time}]

@onready var _line: Line2D = $Line2D


func _ready() -> void:
	_line.width = LINE_WIDTH
	_line.default_color = Color.BLACK
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.clear_points()


func add_point(pos: Vector2, time: float) -> void:
	if not _points.is_empty() and pos.distance_to(_points[-1].position) < MIN_SAMPLE_DIST:
		return
	_points.append({position = pos, time = time})


## Returns true when all points expired (ready to free).
func update_trail(now: float) -> bool:
	while not _points.is_empty() and now - _points[0].time > POINT_LIFETIME:
		_points.pop_front()

	if _points.is_empty():
		return true

	var pts := PackedVector2Array()
	pts.resize(_points.size())
	for i in _points.size():
		pts[i] = _points[i].position
	_line.points = pts
	return false
