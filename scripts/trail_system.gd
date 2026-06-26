extends Node2D
## Real-time trail — each stroke is independent, old strokes fade from head to tail.

const LINE_WIDTH := 16.0
const POINT_LIFETIME := 2.0
const MIN_SAMPLE_DIST := 6.0

var _is_drawing := false
var _game_started := false
var _countdown_active := false
var _stroke_scene: PackedScene = null

var _strokes: Array[Node2D] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.98, 0.98, 0.98))
	_stroke_scene = load("res://scenes/Stroke.tscn")
	_create_borders()
	_create_start_screen()
	$Ball.fell_off_screen.connect(_on_game_over)


func _make_button(text: String, font_size: int, w: float, h: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.flat = false
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(0.0667, 0.0667, 0.0667))
	btn.custom_minimum_size = Vector2(w, h)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0667, 0.0667, 0.0667)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = Color(0.95, 0.95, 0.95)
	btn.add_theme_stylebox_override("hover", hover)

	return btn


func _create_start_screen() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "StartScreen"
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.98, 0.98, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 32)
	canvas.add_child(vbox)

	var title := Label.new()
	title.text = "弹弹球"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.0667, 0.0667, 0.0667))
	vbox.add_child(title)

	var btn := _make_button("开始游戏", 28, 220, 72)
	btn.pressed.connect(func():
		canvas.queue_free()
		_start_countdown()
	)
	vbox.add_child(btn)


func _start_countdown() -> void:
	_countdown_active = true
	var ball: RigidBody2D = $Ball
	ball.freeze = true

	var cc := CanvasLayer.new()
	cc.name = "Countdown"
	add_child(cc)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 120)
	label.add_theme_color_override("font_color", Color(0.0667, 0.0667, 0.0667, 0.2))
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.add_child(label)

	_show_count(label, 3, ball, cc)


func _show_count(label: Label, n: int, ball: RigidBody2D, canvas: CanvasLayer) -> void:
	if n <= 0:
		canvas.queue_free()
		ball.freeze = false
		_countdown_active = false
		_game_started = true
		return

	label.text = str(n)
	label.modulate.a = 0.2

	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 0.45, 0.5)
	tw.tween_property(label, "modulate:a", 0.2, 0.5)
	tw.tween_callback(func():
		_show_count(label, n - 1, ball, canvas)
	)


func _create_borders() -> void:
	var w := 720.0
	var h := 1280.0
	var t := 40.0

	_add_wall("Top",    Vector2(w / 2, -t / 2),       Vector2(w + t * 2, t))
	_add_wall("Left",   Vector2(-t / 2, h / 2),        Vector2(t, h + t * 2))
	_add_wall("Right",  Vector2(w + t / 2, h / 2),     Vector2(t, h + t * 2))


func _add_wall(name: String, pos: Vector2, rect_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "Wall_" + name
	body.position = pos
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = rect_size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _input(event: InputEvent) -> void:
	if not _game_started:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_drawing = true
			_spawn_stroke()
		else:
			_is_drawing = false


func _process(_delta: float) -> void:
	if not _game_started:
		return
	var now := Time.get_ticks_msec() / 1000.0

	if _is_drawing and not _strokes.is_empty():
		var pos := get_global_mouse_position()
		var stroke := _strokes[-1]
		if not _segment_hits_ball(pos, stroke):
			stroke.add_point(pos, now)

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


func _segment_hits_ball(pos: Vector2, stroke: Node2D) -> bool:
	var last_pos: Vector2 = stroke.get_last_point()
	var ball_pos: Vector2 = $Ball.global_position
	var ball_r: float = 60.0  # slightly larger than visual for feel

	var seg: Vector2 = pos - last_pos
	var to_ball: Vector2 = ball_pos - last_pos
	var seg_len: float = seg.length()
	if seg_len < 1.0:
		return to_ball.length() < ball_r

	var t: float = clampf(to_ball.dot(seg) / (seg_len * seg_len), 0.0, 1.0)
	var closest: Vector2 = last_pos + seg * t
	return closest.distance_to(ball_pos) < ball_r


func _on_game_over() -> void:
	get_tree().paused = true
	_show_result("游戏结束")


func _show_result(text: String) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ResultScreen"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.98, 0.98, 0.98, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 28)
	canvas.add_child(vbox)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(0.0667, 0.0667, 0.0667))
	vbox.add_child(label)

	var btn := _make_button("再来一次", 24, 200, 60)
	btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn)
