extends Node2D
## Main game — Dune!+Ketchapp style: gradient bg, modern UI, animated countdown, frosted glass.

const LINE_WIDTH := 16.0
const POINT_LIFETIME := 2.0
const MIN_SAMPLE_DIST := 6.0

# Color palette
const BG_TOP := Color(0.91, 0.96, 1.0)
const BG_BOTTOM := Color(1.0, 0.96, 0.90)
const PURPLE := Color(0.49, 0.25, 0.95)
const PURPLE_LIGHT := Color(0.55, 0.35, 0.98)
const PURPLE_DARK := Color(0.39, 0.15, 0.85)
const DARK_TEXT := Color(0.2, 0.15, 0.4)

var _is_drawing := false
var _game_started := false
var _countdown_active := false
var _stroke_scene: PackedScene = null
var _strokes: Array[Node2D] = []

# Countdown colors
const COUNTDOWN_COLORS := [
	Color(0.30, 0.55, 1.0),   # Blue
	Color(0.25, 0.85, 0.45),  # Green
	Color(1.0, 0.65, 0.2),    # Orange
	Color(0.95, 0.25, 0.25),  # Red
]


func _ready() -> void:
	RenderingServer.set_default_clear_color(BG_TOP)
	_create_gradient_background()
	_create_borders()
	_create_start_screen()
	$Ball.fell_off_screen.connect(_on_game_over)


func _create_gradient_background() -> void:
	var bg := ColorRect.new()
	bg.name = "GradientBG"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader := ShaderMaterial.new()
	shader.shader = Shader.new()
	shader.shader.code = """
shader_type canvas_item;
uniform vec4 top_color : source_color;
uniform vec4 bottom_color : source_color;

void fragment() {
	float t = 1.0 - UV.y;
	COLOR = mix(top_color, bottom_color, t);
}
"""
	shader.set_shader_parameter("top_color", BG_TOP)
	shader.set_shader_parameter("bottom_color", BG_BOTTOM)
	bg.material = shader

	var canvas := CanvasLayer.new()
	canvas.name = "Background"
	canvas.layer = -1
	add_child(canvas)
	canvas.add_child(bg)


func _make_styled_button(text: String, w: float, h: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.flat = true
	btn.custom_minimum_size = Vector2(w, h)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = PURPLE
	normal.corner_radius_top_left = 28
	normal.corner_radius_top_right = 28
	normal.corner_radius_bottom_left = 28
	normal.corner_radius_bottom_right = 28
	normal.shadow_size = 8
	normal.shadow_color = Color(PURPLE.r, PURPLE.g, PURPLE.b, 0.35)
	normal.content_margin_left = 28
	normal.content_margin_right = 28
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = PURPLE_LIGHT
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = PURPLE_DARK
	pressed.shadow_size = 3
	pressed.shadow_color = Color(PURPLE.r, PURPLE.g, PURPLE.b, 0.15)
	btn.add_theme_stylebox_override("pressed", pressed)

	# Hover scale
	btn.mouse_entered.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)
	)

	# Press animation
	btn.pressed.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.06).set_ease(Tween.EASE_IN)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	)

	return btn


func _create_start_screen() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "StartScreen"
	add_child(canvas)

	# Semi-transparent overlay
	var bg := ColorRect.new()
	bg.color = Color(1.0, 1.0, 1.0, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 36)
	canvas.add_child(vbox)

	# Title with gradient color
	var title := Label.new()
	title.text = "Bounce Line"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", PURPLE)
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Draw. Bounce. Collect."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.4, 0.35, 0.55))
	vbox.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	var btn := _make_styled_button("Play", 200, 64)
	btn.pressed.connect(func():
		canvas.queue_free()
		_start_countdown()
	)
	vbox.add_child(btn)

	# Entrance animation
	vbox.modulate.a = 0.0
	vbox.position += Vector2(0, 30)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(vbox, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(vbox, "position", vbox.position - Vector2(0, 30), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _start_countdown() -> void:
	_countdown_active = true
	var ball: RigidBody2D = $Ball
	ball.freeze = true

	var canvas := CanvasLayer.new()
	canvas.name = "Countdown"
	add_child(canvas)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 140)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(label)

	_show_count(label, 3, ball, canvas)


func _show_count(label: Label, n: int, ball: RigidBody2D, canvas: CanvasLayer) -> void:
	if n <= 0:
		# Show GO! then start
		label.text = "GO!"
		label.add_theme_color_override("font_color", Color(0.25, 0.85, 0.45))
		label.scale = Vector2(0.3, 0.3)
		label.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(label, "modulate:a", 1.0, 0.15)
		tw.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15)
		tw.tween_property(label, "modulate:a", 0.0, 0.2).set_delay(0.1)
		tw.tween_callback(func():
			canvas.queue_free()
			ball.freeze = false
			_countdown_active = false
			_game_started = true
		)
		return

	var color_idx := 3 - n  # 3→0, 2→1, 1→2
	label.text = str(n)
	label.add_theme_color_override("font_color", COUNTDOWN_COLORS[color_idx])
	label.scale = Vector2(0.3, 0.3)
	label.modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "modulate:a", 1.0, 0.2)
	tw.tween_property(label, "scale", Vector2(1.15, 1.15), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.35).set_ease(Tween.EASE_IN)
	tw.tween_property(label, "modulate:a", 0.0, 0.2).set_delay(0.55)
	tw.tween_callback(func():
		_show_count(label, n - 1, ball, canvas)
	).set_delay(0.75)


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
	var ball_r: float = 60.0

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
	_show_game_over()


func _show_game_over() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "GameOverUI"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# Frosted glass background
	var bg := ColorRect.new()
	bg.color = Color(0.94, 0.95, 1.0, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 20)
	canvas.add_child(center)

	# Title
	var title := Label.new()
	title.text = "Game Over"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", PURPLE)
	center.add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "The ball fell off the screen"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.4, 0.35, 0.55))
	center.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	center.add_child(spacer)

	# Retry button
	var btn := _make_styled_button("Try Again", 200, 60)
	btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	center.add_child(btn)

	# Entrance animation
	canvas.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(canvas, "modulate:a", 1.0, 0.3)
	tw.tween_property(center, "scale", Vector2(1.0, 1.0), 0.5).from(Vector2(0.85, 0.85)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
