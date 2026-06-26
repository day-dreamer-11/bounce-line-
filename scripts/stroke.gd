extends Node2D
## A single stroke — Line2D visual + collision for ball bounce.

const LINE_WIDTH := 16.0
const POINT_LIFETIME := 2.0
const MIN_SAMPLE_DIST := 6.0

var _points: Array[Dictionary] = []

@onready var _line: Line2D = $Line2D
@onready var _collision: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D


func _ready() -> void:
	_line.width = LINE_WIDTH
	_line.default_color = Color.BLACK
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.clear_points()

	_collision.polygon = PackedVector2Array()
	_collision.disabled = true


func add_point(pos: Vector2, time: float) -> void:
	if not _points.is_empty() and pos.distance_to(_points[-1].position) < MIN_SAMPLE_DIST:
		return
	_points.append({position = pos, time = time})


## Returns true when all points expired.
func update_trail(now: float) -> bool:
	while not _points.is_empty() and now - _points[0].time > POINT_LIFETIME:
		_points.pop_front()

	if _points.is_empty():
		return true

	# Update visual
	var pts := PackedVector2Array()
	pts.resize(_points.size())
	for i in _points.size():
		pts[i] = _points[i].position
	_line.points = pts

	# Update collision polygon
	_build_collision_polygon()

	return false


func _build_collision_polygon() -> void:
	var count := _points.size()
	if count < 2:
		_collision.disabled = true
		return

	var half := LINE_WIDTH / 2.0
	var left := PackedVector2Array()
	var right := PackedVector2Array()

	for i in count:
		var pos: Vector2 = _points[i].position
		var dir: Vector2
		if i == 0:
			dir = (_points[1].position - pos).normalized()
		elif i == count - 1:
			dir = (pos - _points[i - 1].position).normalized()
		else:
			dir = (_points[i + 1].position - _points[i - 1].position).normalized()

		var perp := Vector2(-dir.y, dir.x)
		left.append(pos + perp * half)
		right.append(pos - perp * half)

	# Reverse right side to create continuous polygon
	right.reverse()
	var poly := left + right
	_collision.polygon = poly
	_collision.disabled = false
