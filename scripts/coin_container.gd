extends Node2D
## Spawns 5 coins at random positions + shows collection counter.

const COIN_COUNT := 5
const COIN_RADIUS := 54.0
const EDGE_MARGIN := 110.0
const BALL_SAFE_DIST := 380.0

const COLOR_BLUE := Color(0.35, 0.49, 0.93)
const COLOR_WHITE := Color(0.98, 0.98, 0.99)
const COLOR_SHADOW := Color(0.0, 0.0, 0.0, 0.3)
const COLOR_GOLD := Color(0.96, 0.90, 0.78)

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
	card_style.bg_color = Color(0.05, 0.08, 0.15, 0.65)
	card_style.corner_radius_top_left = 18
	card_style.corner_radius_top_right = 18
	card_style.corner_radius_bottom_left = 18
	card_style.corner_radius_bottom_right = 18
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(COLOR_BLUE.r, COLOR_BLUE.g, COLOR_BLUE.b, 0.4)
	card_style.shadow_size = 8
	card_style.shadow_color = Color(0, 0, 0, 0.2)
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 8
	card_style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_style)

	_label = Label.new()
	_label.text = "0 / %d" % COIN_COUNT
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", COLOR_GOLD)
	card.add_child(_label)
	canvas.add_child(card)


func _spawn_coins() -> void:
	var bounds := Vector2(720, 1280)
	var ball_pos: Vector2 = get_node("../Ball").position
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

	var tex := load("res://assets/background.png")
	if tex:
		var bg := TextureRect.new()
		bg.texture = tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		canvas.add_child(bg)

	# Dark overlay for contrast
	var overlay := ColorRect.new()
	overlay.color = Color(0.05, 0.08, 0.15, 0.35)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-85, -200)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	canvas.add_child(vbox)

	vbox.add_child(_make_shadow_label("胜利!", 54, COLOR_WHITE, COLOR_SHADOW))

	var score := Label.new()
	score.text = "%d / %d" % [_collected, COIN_COUNT]
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 26)
	score.add_theme_color_override("font_color", COLOR_GOLD)
	vbox.add_child(score)

	var stars := Label.new()
	stars.text = "★★★★★"
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 34)
	stars.add_theme_color_override("font_color", Color(0.96, 0.75, 0.15))
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


func _make_styled_button(text: String, w: float, h: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", COLOR_GOLD)
	btn.custom_minimum_size = Vector2(w, h)

	const BORDER := Color(0.96, 0.82, 0.35, 0.9)

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
	hover.shadow_color = Color(COLOR_BLUE.r, COLOR_BLUE.g, COLOR_BLUE.b, 0.5)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.20, 0.31, 0.72)
	pressed.border_color = Color(0.75, 0.60, 0.15, 0.8)
	pressed.shadow_size = 4
	pressed.shadow_color = Color(0, 0, 0, 0.2)
	pressed.content_margin_top = 4
	pressed.content_margin_bottom = -4
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_stylebox_override("focus", normal)

	btn.pressed.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(0.93, 0.93), 0.06)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	)

	return btn
