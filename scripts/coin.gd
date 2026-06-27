extends Area2D
## Gold coin — gradient, glow, float & spin animation, collect particles.

const RADIUS := 18.0
const FILL_TOP := Color(1.0, 0.91, 0.35)
const FILL_BOTTOM := Color(0.95, 0.65, 0.05)
const RIM_COLOR := Color(0.85, 0.55, 0.02)
const GLOW_COLOR := Color(1.0, 0.75, 0.2, 0.3)
const HIGHLIGHT_COLOR := Color(1.0, 1.0, 0.85, 0.5)

signal collected

var _collect_tween: Tween = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_float_animation()
	_start_spin_animation()
	queue_redraw()


func _start_float_animation() -> void:
	var tw := create_tween().set_loops()
	var start_y := position.y
	tw.tween_property(self, "position:y", start_y - 8.0, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", start_y + 8.0, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _start_spin_animation() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(self, "scale:x", 0.3, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale:x", -0.3, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	# Glow
	draw_circle(Vector2.ZERO, RADIUS + 6, GLOW_COLOR)
	# Outer rim
	draw_circle(Vector2.ZERO, RADIUS, RIM_COLOR)
	# Main fill — gradient via layered circles
	var steps := 6
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var r: float = (RADIUS - 2.5) * (1.0 - t * 0.2)
		var col := FILL_TOP.lerp(FILL_BOTTOM, t)
		draw_circle(Vector2(0, t * 3), r, col)
	# Inner ring
	draw_arc(Vector2.ZERO, RADIUS - 3.5, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.25), 1.0)
	# Dollar sign (simple)
	var font_size := 18
	var sign_color := Color(0.95, 0.75, 0.15, 0.7)
	draw_string(ThemeDB.fallback_font, Vector2(-6, 7), "$", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, sign_color)
	# Highlight
	draw_circle(Vector2(-5, -7), 5.0, HIGHLIGHT_COLOR)


func _on_body_entered(_body: Node2D) -> void:
	collected.emit()
	_play_collect_animation()


func _play_collect_animation() -> void:
	if _collect_tween and _collect_tween.is_running():
		return
	# Prevent double-collect
	$CollisionShape2D.set_deferred("disabled", true)
	_collect_tween = create_tween()
	_collect_tween.set_parallel(true)
	_collect_tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_collect_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_collect_tween.chain().tween_callback(queue_free)
