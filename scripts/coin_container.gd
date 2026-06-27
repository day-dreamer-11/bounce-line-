extends Node2D
## Coin spawner + modern HUD card + victory screen.

const COIN_COUNT := 5
const COIN_RADIUS := 18.0
const EDGE_MARGIN := 80.0
const BALL_SAFE_DIST := 200.0

var _collected := 0
var _coin_scene: PackedScene = null
var _hud_card: PanelContainer = null
var _score_label: Label = null


func _ready() -> void:
	_coin_scene = load("res://scenes/Coin.tscn")
	_create_hud()
	_spawn_coins()

	# HUD entrance animation
	var tw := create_tween()
	tw.tween_property(_hud_card, "position:x", 16, 0.5).from(-200).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CoinUI"
	add_child(canvas)

	_hud_card = PanelContainer.new()
	_hud_card.position = Vector2(16, 16)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1.0, 1.0, 1.0, 0.75)
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(1.0, 1.0, 1.0, 0.5)
	card_style.corner_radius_top_left = 20
	card_style.corner_radius_top_right = 20
	card_style.corner_radius_bottom_left = 20
	card_style.corner_radius_bottom_right = 20
	card_style.shadow_size = 8
	card_style.shadow_color = Color(0, 0, 0, 0.1)
	_hud_card.add_theme_stylebox_override("panel", card_style)

	_score_label = Label.new()
	_score_label.text = "%d / %d" % [_collected, COIN_COUNT]
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.4))
	_hud_card.add_child(_score_label)

	canvas.add_child(_hud_card)


func _spawn_coins() -> void:
	var bounds := Vector2(720, 1280)
	var ball_pos := Vector2(360, 100)
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
	_score_label.text = "%d / %d" % [_collected, COIN_COUNT]

	# Score bounce animation
	var tw := create_tween()
	tw.tween_property(_score_label, "scale", Vector2(1.4, 1.4), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_score_label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	if _collected >= COIN_COUNT:
		# Small delay before victory
		var delay_tw := create_tween()
		delay_tw.tween_interval(0.3)
		delay_tw.tween_callback(_show_victory)


func _show_victory() -> void:
	get_tree().paused = true

	var canvas := CanvasLayer.new()
	canvas.name = "VictoryUI"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# Frosted glass background
	var bg := ColorRect.new()
	bg.color = Color(0.94, 0.96, 1.0, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 20)
	canvas.add_child(center)

	# Title
	var title := Label.new()
	title.text = "YOU WIN!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.39, 0.25, 0.95))
	center.add_child(title)

	# Stars
	var stars := Label.new()
	stars.text = "★★★★★"
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 36)
	center.add_child(stars)

	# Score
	var score := Label.new()
	score.text = "%d / %d" % [_collected, COIN_COUNT]
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.add_theme_font_size_override("font_size", 28)
	score.add_theme_color_override("font_color", Color(0.3, 0.2, 0.5))
	center.add_child(score)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	center.add_child(spacer)

	# Restart button
	var btn := _make_styled_button("Play Again", 220, 64)
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
	tw.tween_property(center, "scale", Vector2(1.0, 1.0), 0.5).from(Vector2(0.8, 0.8)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _make_styled_button(text: String, w: float, h: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.flat = true
	btn.custom_minimum_size = Vector2(w, h)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.49, 0.25, 0.95)
	normal.corner_radius_top_left = 28
	normal.corner_radius_top_right = 28
	normal.corner_radius_bottom_left = 28
	normal.corner_radius_bottom_right = 28
	normal.shadow_size = 6
	normal.shadow_color = Color(0.39, 0.25, 0.95, 0.3)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.55, 0.35, 0.98)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.39, 0.15, 0.85)
	pressed.shadow_size = 2
	btn.add_theme_stylebox_override("pressed", pressed)

	# Press animation
	btn.pressed.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.08).set_ease(Tween.EASE_IN)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	)

	return btn
