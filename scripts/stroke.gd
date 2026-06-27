extends Node2D
## Drawn stroke — colorful gradient trail with glow, collision for ball bounce.

const LINE_WIDTH := 20.0
const GLOW_WIDTH := 32.0
const POINT_LIFETIME := 2.0
const MIN_SAMPLE_DIST := 6.0
const MAX_TOTAL_DIST := 400.0

const TRAIL_COLOR := Color(0.45, 0.35, 0.95, 0.85)
const TRAIL_END_COLOR := Color(0.55, 0.45, 0.98, 0.0)
const GLOW_COLOR := Color(0.45, 0.35, 0.95, 0.2)

var _points: Array[Dictionary] = []
var _total_dist: float = 0.0

@onready var _line: Line2D = $Line2D
@onready var _glow: Line2D = $Glow
@onready var _collision: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D


func _ready() -> void:
	_setup_line(_line, LINE_WIDTH, TRAIL_COLOR)
	_setup_line(_glow, GLOW_WIDTH, GLOW_COLOR)
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	_glow.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.clear_points()
	_glow.clear_points()

	_collision.polygon = PackedVector2Array()
	_collision.disabled = true

	var mat := PhysicsMaterial.new()
	mat.bounce = 1.0
	mat.friction = 0.0
	$StaticBody2D.physics_material_override = mat


func _setup_line(line: Line2D, width: float, color: Color) -> void:
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND


func add_point(pos: Vector2, time: float) -> void:
	if not _points.is_empty():
		if pos.distance_to(_points[-1].position) < MIN_SAMPLE_DIST:
			return
		_total_dist += pos.distance_to(_points[-1].position)
	_points.append({position = pos, time = time})


func get_last_point() -> Vector2:
	if _points.is_empty():
		return Vector2.ZERO
	return _points[-1].position


func update_trail(now: float) -> bool:
	while not _points.is_empty() and now - _points[0].time > POINT_LIFETIME:
		_pop_front()

	while _total_dist > MAX_TOTAL_DIST and _points.size() >= 2:
		_pop_front()

	if _points.is_empty():
		return true

	var pts := PackedVector2Array()
	pts.resize(_points.size())
	for i in _points.size():
		pts[i] = _points[i].position
	_line.points = pts
	_glow.points = pts

	# Fade alpha based on point age
	_update_gradient(now)

	_build_collision_polygon()
	return false


func _update_gradient(now: float) -> void:
	var count := _points.size()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array()
	grad.colors = PackedColorArray()

	for i in count:
		var age: float = now - _points[i].time
		var alpha: float = clampf(1.0 - age / POINT_LIFETIME, 0.0, 1.0) * 0.85
		var t: float = float(i) / max(count - 1, 1)
		grad.add_point(t, Color(TRAIL_COLOR.r, TRAIL_COLOR.g, TRAIL_COLOR.b, alpha))

	_line.gradient = grad

	# Glow gradient
	var glow_grad := Gradient.new()
	for i in count:
		var age: float = now - _points[i].time
		var alpha: float = clampf(1.0 - age / POINT_LIFETIME, 0.0, 1.0) * 0.2
		var t: float = float(i) / max(count - 1, 1)
		glow_grad.add_point(t, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha))
	_glow.gradient = glow_grad


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

	right.reverse()
	var poly := left + right
	_collision.polygon = poly
	_collision.disabled = false


func _pop_front() -> void:
	if _points.size() < 2:
		_points.pop_front()
		return
	_total_dist -= _points[0].position.distance_to(_points[1].position)
	_points.pop_front()
