extends StaticBody2D
## A drawn line — lasts 2 seconds then self-deletes. Only one can exist at a time.

const LENGTH := 150.0
const WIDTH := 4.0
const COLOR := Color(0.0667, 0.0667, 0.0667)
const LIFETIME := 2.0


func _ready() -> void:
	$Timer.start(LIFETIME)
	queue_redraw()


func _draw() -> void:
	var half := Vector2(LENGTH / 2.0, 0)
	draw_line(-half, half, COLOR, WIDTH)


func _on_timer_timeout() -> void:
	queue_free()
