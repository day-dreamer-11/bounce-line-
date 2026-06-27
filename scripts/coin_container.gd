extends Node2D
## Spawns 5 coins at random positions + shows collection counter.

const COIN_COUNT := 5
const COIN_RADIUS := 18.0
const EDGE_MARGIN := 80.0
const BALL_SAFE_DIST := 200.0

var _collected := 0
var _label: Label = null
var _coin_scene: PackedScene = null


func _ready() -> void:
	_coin_scene = load("res://scenes/Coin.tscn")
	_create_ui()
	_spawn_coins()


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CoinUI"
	add_child(canvas)

	var card := PanelContainer.new()
	card.position = Vector2(16, 16)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1.0, 1.0, 1.0, 0.7)
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	card_style.shadow_size = 6
	card_style.shadow_color = Color(0, 0, 0, 0.1)
	card.add_theme_stylebox_override("panel", card_style)

	_label = Label.new()
	_label.text = "0 / %d" % COIN_COUNT
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color(0.85, 0.45, 0.15))
	card.add_child(_label)
	canvas.add_child(card)


func _spawn_coins() -> void:
	var bounds := Vector2(720, 1280)
	var ball_pos := Vector2(360, 130)
	var placed: Array[Vector2] = []

	for _i in COIN_COUNT:
		var pos := _find_valid_position(bounds, ball_pos, placed)
		placed.append(pos)
		var coin := _coin_scene.instantiate()
		coin.position = pos
		coin.collected.connect(_on_coin_collected)
		add_child(coin)


func _find_valid_position(bounds: Vector2, ball_pos: Vector2, existing: Array[Vector2]) -> Vector2:
	var margin := EDGE_MARGIN + COIN_RADIUS
	var min_spacing := COIN_RADIUS * 4.0

	for _attempt in 200:
		var x := randf_range(margin, bounds.x - margin)
		var y := randf_range(margin, bounds.y - margin)
		var pos := Vector2(x, y)

		if pos.distance_to(ball_pos) < BALL_SAFE_DIST:
			continue

		var ok := true
		for p in existing:
			if pos.distance_to(p) < min_spacing:
				ok = false
				break
		if ok:
			return pos

	return Vector2(randf_range(margin, bounds.x - margin), randf_range(margin, bounds.y - margin))


func _on_coin_collected() -> void:
	_collected += 1
	_label.text = "%d / %d" % [_collected, COIN_COUNT]

	var tw := create_tween()
	tw.tween_property(_label, "scale", Vector2(1.3, 1.3), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_label, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT)

	if _collected >= COIN_COUNT:
		get_tree().create_timer(0.7).timeout.connect(_show_victory)


func _show_victory() -> void:
	get_tree().paused = true

	var canvas := CanvasLayer.new()
	canvas.name = "VictoryUI"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# Overlay background
	var tex := load("res://assets/ui_overlay.png")
	if tex:
		var bg := TextureRect.new()
		bg.texture = tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		canvas.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	canvas.add_child(vbox)

	# Title with shadow
	vbox.add_child(_make_shadow_label("胜利!", 52, Color(0.85, 0.45, 0.15), Color(0, 0, 0, 0.25)))

	# Score
	var score := Label.new()
	score.text = "%d / %d" % [_collected, COIN_COUNT]
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 28)
	score.add_theme_color_override("font_color", Color(0.55, 0.35, 0.2))
	vbox.add_child(score)

	# Stars
	var stars := Label.new()
	stars.text = "★★★★★"
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 32)
	stars.add_theme_color_override("font_color", Color(1.0, 0.65, 0.15))
	vbox.add_child(stars)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var btn := _make_styled_button("再来一次", 200, 60)
	btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn)


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
	shadow.position = Vector2(3, 3)
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


func _make_styled_button(text: String, w: float, h: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.custom_minimum_size = Vector2(w, h)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.85, 0.45, 0.15)
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_left = 18
	normal.corner_radius_bottom_right = 18
	normal.shadow_size = 6
	normal.shadow_color = Color(0.6, 0.3, 0.1, 0.4)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.95, 0.55, 0.2)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.7, 0.35, 0.1)
	pressed.shadow_size = 2
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.pressed.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(0.93, 0.93), 0.06)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	)

	return btn
