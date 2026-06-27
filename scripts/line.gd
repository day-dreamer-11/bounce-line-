extends StaticBody2D
## A drawn line segment — purple gradient with glow, lasts 2 seconds.

const LENGTH := 150.0
const WIDTH := 5.0
const GLOW_WIDTH := 14.0
const COLOR := Color(0.45, 0.35, 0.95, 0.85)
const GLOW_COLOR := Color(0.45, 0.35, 0.95, 0.25)
const LIFETIME := 2.0

var _fade_tween: Tween = null


func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)
	# Entrance pop animation
	scale = Vector2(0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	queue_redraw()


func reset_timer() -> void:
	$Timer.stop()
	$Timer.start(LIFETIME)
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	modulate.a = 1.0
	queue_redraw()


func _draw() -> void:
	var half := Vector2(LENGTH / 2.0, 0)
	# Glow layer
	draw_line(-half, half, GLOW_COLOR, GLOW_WIDTH)
	# Main line
	draw_line(-half, half, COLOR, WIDTH)
	# Bright core
	draw_line(-half, half, Color(0.55, 0.45, 0.98, 0.5), 2.0)


func _on_timer_timeout() -> void:
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	_fade_tween.tween_callback(func(): visible = false)
