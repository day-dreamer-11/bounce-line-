extends Node2D
## Energy trail stroke — multi-layer glow.

const COLOR_CORE := Color("9D6BFF")
const COLOR_MID := Color("6F7DFF")
const COLOR_EDGE := Color("5FD8FF")

const POINT_LIFETIME := 2.0
const FADE_DURATION := 1.0
const MIN_SAMPLE_DIST := 2.0
const TRAIL_MIN_LEN := 300.0
const TRAIL_MAX_LEN := 450.0
const COLLISION_HALF := 8.0

var _points: Array[Dictionary] = []
var _total_dist: float = 0.0
var _max_length: float = TRAIL_MIN_LEN
var _fading: bool = false

@onready var _outer: Line2D = $OuterLine
@onready var _mid: Line2D = $MidLine
@onready var _core: Line2D = $CoreLine
@onready var _collision: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D


func _ready() -> void:
	_setup_line(_outer, 48.0, Color(COLOR_EDGE.r, COLOR_EDGE.g, COLOR_EDGE.b, 0.06))
	_setup_line(_mid, 28.0, Color(COLOR_MID.r, COLOR_MID.g, COLOR_MID.b, 0.18))
	_setup_line(_core, 16.0, COLOR_CORE)

	var curve := Curve.new()
	curve.bake_resolution = 32
	curve.add_point(Vector2(0.0, 0.1), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	curve.add_point(Vector2(0.3, 0.4), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	curve.add_point(Vector2(0.7, 0.8), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	curve.add_point(Vector2(1.0, 1.0), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	_core.width_curve = curve

	var mat := PhysicsMaterial.new()
	mat.bounce = 1.0
	mat.friction = 0.0
	$StaticBody2D.physics_material_override = mat
	_collision.polygon = PackedVector2Array()
	_collision.disabled = true


func _setup_line(line: Line2D, base_width: float, color: Color) -> void:
	line.width = base_width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.15, 0.4, 0.7, 1.0])
	grad.colors = PackedColorArray([
		Color(COLOR_EDGE, 0.0),
		Color(COLOR_EDGE.r, COLOR_EDGE.g, COLOR_EDGE.b, 0.2),
		COLOR_EDGE,
		COLOR_MID,
		COLOR_CORE
	])
	line.gradient = grad


func set_speed_factor(factor: float) -> void:
	_max_length = lerp(TRAIL_MIN_LEN, TRAIL_MAX_LEN, clampf(factor, 0.0, 1.0))


func add_point(pos: Vector2, time: float) -> void:
	if not _points.is_empty():
		var d := pos.distance_to(_points[-1].position)
		if d < MIN_SAMPLE_DIST:
			return
		_total_dist += d
	_points.append({position = pos, time = time})


func get_last_point() -> Vector2:
	if _points.is_empty():
		return Vector2.ZERO
	return _points[-1].position


func update_trail(now: float) -> bool:
	if _fading:
		_update_visuals()
		return false

	while not _points.is_empty() and now - _points[0].time > POINT_LIFETIME:
		_pop_front()

	while _total_dist > _max_length and _points.size() >= 2:
		_pop_front()

	if _points.is_empty():
		return true

	_update_visuals()
	return false


func _update_visuals() -> void:
	if _points.is_empty():
		return

	var pts := PackedVector2Array()
	pts.resize(_points.size())
	for i in _points.size():
		pts[i] = _points[i].position

	_outer.points = pts
	_mid.points = pts
	_core.points = pts

	_build_collision(pts)


func _build_collision(pts: PackedVector2Array) -> void:
	var count := pts.size()
	if count < 2:
		_collision.disabled = true
		return

	var left := PackedVector2Array()
	var right := PackedVector2Array()

	for i in count:
		var pos := pts[i]
		var dir: Vector2
		if i == 0:
			dir = (pts[1] - pos).normalized()
		elif i == count - 1:
			dir = (pos - pts[i - 1]).normalized()
		else:
			dir = (pts[i + 1] - pts[i - 1]).normalized()

		var perp := Vector2(-dir.y, dir.x)
		left.append(pos + perp * COLLISION_HALF)
		right.append(pos - perp * COLLISION_HALF)

	right.reverse()
	_collision.polygon = left + right
	_collision.disabled = false


func start_fade() -> void:
	if _fading:
		return
	_fading = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_outer, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mid, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	tw.tween_property(_core, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(queue_free)


func _pop_front() -> void:
	if _points.size() < 2:
		_points.pop_front()
		return
	_total_dist -= _points[0].position.distance_to(_points[1].position)
	_points.pop_front()
