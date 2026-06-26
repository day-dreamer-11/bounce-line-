extends Node2D
## Real-time trail — each stroke is independent, old strokes fade from head to tail.

const LINE_WIDTH := 16.0
const POINT_LIFETIME := 2.0
const MIN_SAMPLE_DIST := 6.0

var _is_drawing := false
var _stroke_scene: PackedScene = null

## Active strokes — each manages its own Line2D and point lifetimes.
var _strokes: Array[Node2D] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.98, 0.98, 0.98))
	_stroke_scene = load("res://scenes/Stroke.tscn")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_drawing = true
			_spawn_stroke()
		else:
			_is_drawing = false


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	if _is_drawing and not _strokes.is_empty():
		var pos := get_global_mouse_position()
		var stroke := _strokes[-1]
		stroke.add_point(pos, now)

	# Update all strokes, remove expired ones
	var i := 0
	while i < _strokes.size():
		var s := _strokes[i]
		if s.update_trail(now):
			s.queue_free()
			_strokes.remove_at(i)
		else:
			i += 1


func _spawn_stroke() -> void:
	var s := _stroke_scene.instantiate()
	add_child(s)
	_strokes.append(s)
	s.add_point(get_global_mouse_position(), Time.get_ticks_msec() / 1000.0)
