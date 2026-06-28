extends Node2D
## Real-time trail — each stroke is independent, old strokes fade from head to tail.

const LINE_WIDTH := 16.0
const POINT_LIFETIME := 2.0
const MIN_SAMPLE_DIST := 6.0

# Color palette from sample: blue-purple + gold accents
const COLOR_PRIMARY := Color(0.35, 0.49, 0.93)
const COLOR_PRIMARY_DARK := Color(0.20, 0.31, 0.72)
const COLOR_GOLD := Color(0.96, 0.90, 0.78)
const COLOR_GOLD_DARK := Color(0.85, 0.65, 0.15)
const COLOR_WHITE := Color(0.98, 0.98, 0.99)
const COLOR_SHADOW := Color(0.0, 0.0, 0.0, 0.3)

var _is_drawing := false
var _game_started := false
var _countdown_active := false
var _stroke_scene: PackedScene = null

var _strokes: Array[Node2D] = []

# Speed tracking
var _ball_last_pos: Vector2 = Vector2.ZERO
var _ball_speed: float = 0.0

# Particle system for sparkles
var _sparkles: CPUParticles2D = null


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.98, 0.98, 0.98))
	_create_background()
	_stroke_scene = load("res://scenes/Stroke.tscn")
	_create_borders()
	_create_start_screen()
	_setup_sparkles()
	$Ball.fell_off_screen.connect(_on_game_over)


func _create_background() -> void:
	var tex := load("res://assets/background.png")
	if not tex:
		return
	var canvas := CanvasLayer.new()
	canvas.name = "BackgroundLayer"
	canvas.layer = -1
	add_child(canvas)
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)


func _setup_sparkles() -> void:
	_sparkles = CPUParticles2D.new()
	_sparkles.name = "Sparkles"
	_sparkles.emitting = false
	_sparkles.one_shot = false
	_sparkles.amount = 6
	_sparkles.lifetime = 0.4
	_sparkles.explosiveness = 0.35
	_sparkles.spread = 50.0
	_sparkles.speed_scale = 0.5
	_sparkles.gravity = Vector2(0, -8)
	_sparkles.scale_amount_min = 0.8
	_sparkles.scale_amount_max = 3.0
	_sparkles.color = Color.WHITE

	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(0.85, 0.78, 1.0, 0.7),
		Color(0.62, 0.42, 1.0, 0.0)
	])
	_sparkles.color_ramp = ramp

	var dot_tex := _make_dot_texture(16)
	_sparkles.texture = dot_tex
	add_child(_sparkles)


func _make_dot_texture(size: int = 16) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx := size / 2.0
	for x in size:
		for y in size:
			var d := Vector2(x - cx + 0.5, y - cx + 0.5).length() / cx
			var a := 1.0 - smoothstep(0.0, 1.0, d)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _make_overlay_bg(canvas: CanvasLayer) -> void:
	var tex := load("res://assets/background.png")
	if not tex:
		return
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)


func _make_shadow_label(text: String, font_size: int, main_color: Color, shadow_color: Color) -> Control:
	var ctrl := Control.new()
	ctrl.custom_minimum_size = Vector2(0, font_size * 1.4)

	var shadow := Label.new()
	shadow.text = text
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shadow.add_theme_font_size_override("font_size", font_size)
	shadow.add_theme_color_override("font_color", shadow_color)
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.position = Vector2(2, 2)
	ctrl.add_child(shadow)

	var main := Label.new()
	main.text = text
	main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.add_theme_font_size_override("font_size", font_size)
	main.add_theme_color_override("font_color", main_color)
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.add_child(main)

	return ctrl


func _make_button(text: String, font_size: int, w: float, h: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", COLOR_GOLD)
	btn.custom_minimum_size = Vector2(w, h)

	# Gold border
	const BORDER := Color(0.96, 0.82, 0.35, 0.9)
	const BORDER_SOFT := Color(0.96, 0.82, 0.35, 0.4)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.18, 0.28, 0.62)
	normal.corner_radius_top_left = 24
	normal.corner_radius_top_right = 24
	normal.corner_radius_bottom_left = 24
	normal.corner_radius_bottom_right = 24
	normal.border_width_left = 3
	normal.border_width_right = 3
	normal.border_width_top = 3
	normal.border_width_bottom = 3
	normal.border_color = BORDER
	normal.shadow_size = 14
	normal.shadow_color = Color(0, 0, 0, 0.45)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.25, 0.36, 0.72)
	hover.border_color = Color(1.0, 0.92, 0.55, 0.95)
	hover.shadow_size = 20
	hover.shadow_color = Color(COLOR_PRIMARY.r, COLOR_PRIMARY.g, COLOR_PRIMARY.b, 0.5)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = COLOR_PRIMARY_DARK
	pressed.border_color = Color(0.75, 0.60, 0.15, 0.8)
	pressed.shadow_size = 4
	pressed.shadow_color = Color(0, 0, 0, 0.2)
	# Shift down to simulate press
	pressed.content_margin_top = 4
	pressed.content_margin_bottom = -4
	btn.add_theme_stylebox_override("pressed", pressed)

	# Focus style same as normal
	btn.add_theme_stylebox_override("focus", normal)

	btn.mouse_entered.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.12).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
	)
	btn.pressed.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.05)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	)

	return btn


func _create_start_screen() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "StartScreen"
	add_child(canvas)

	_make_overlay_bg(canvas)

	var overlay := ColorRect.new()
	overlay.color = Color(0.05, 0.08, 0.15, 0.3)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-85, -200)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	canvas.add_child(vbox)

	vbox.add_child(_make_shadow_label("弹弹球", 58, COLOR_WHITE, COLOR_SHADOW))

	var subtitle := Label.new()
	subtitle.text = "Draw · Bounce · Collect"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", COLOR_GOLD)
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var btn := _make_button("开始游戏", 26, 200, 64)
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

	var overlay := ColorRect.new()
	overlay.color = Color(0.05, 0.08, 0.15, 0.25)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.add_child(overlay)

	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.add_child(ctrl)

	_show_count(ctrl, 3, ball, cc)


func _show_count(ctrl: Control, n: int, ball: RigidBody2D, canvas: CanvasLayer) -> void:
	if n <= 0:
		canvas.queue_free()
		ball.freeze = false
		_countdown_active = false
		_game_started = true
		_ball_last_pos = ball.global_position
		return

	for child in ctrl.get_children():
		child.queue_free()

	var count_colors := [
		Color(0.35, 0.49, 0.93),
		Color(0.40, 0.60, 0.55),
		Color(0.95, 0.55, 0.15),
	]
	var label := _make_shadow_label(str(n), 150, count_colors[3 - n], COLOR_SHADOW)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.modulate.a = 0.0
	label.scale = Vector2(0.4, 0.4)
	ctrl.add_child(label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "modulate:a", 1.0, 0.12)
	tw.tween_property(label, "scale", Vector2(1.15, 1.15), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.12).set_delay(0.3)
	tw.tween_property(label, "modulate:a", 0.0, 0.12).set_delay(0.55)
	tw.tween_callback(func():
		_show_count(ctrl, n - 1, ball, canvas)
	).set_delay(0.67)


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


func _process(delta: float) -> void:
	if not _game_started:
		return
	var now := Time.get_ticks_msec() / 1000.0

	var ball_pos: Vector2 = $Ball.global_position
	_ball_speed = _ball_last_pos.distance_to(ball_pos) / max(delta, 0.0001)
	_ball_last_pos = ball_pos
	var speed_factor := clampf(_ball_speed / 600.0, 0.0, 1.0)

	if _is_drawing and not _strokes.is_empty():
		var pos := get_global_mouse_position()
		var stroke := _strokes[-1]
		if not _segment_hits_ball(pos, stroke):
			stroke.add_point(pos, now)
		stroke.set_speed_factor(speed_factor)
		_sparkles.position = pos
		_sparkles.emitting = true
		_sparkles.amount = int(lerp(4.0, 12.0, speed_factor))
		_sparkles.speed_scale = lerp(0.3, 0.8, speed_factor)
	else:
		_sparkles.emitting = false

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
	s.tree_exited.connect(_on_stroke_freed.bind(s))


func _on_stroke_freed(s: Node2D) -> void:
	_strokes.erase(s)


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
	get_tree().create_timer(0.7).timeout.connect(func(): _show_result("游戏结束"))


func _show_result(text: String) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ResultScreen"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	_make_overlay_bg(canvas)

	var overlay := ColorRect.new()
	overlay.color = Color(0.05, 0.08, 0.15, 0.35)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-85, -200)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	canvas.add_child(vbox)

	vbox.add_child(_make_shadow_label(text, 50, COLOR_WHITE, COLOR_SHADOW))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	var btn := _make_button("再来一次", 24, 200, 60)
	btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn)
