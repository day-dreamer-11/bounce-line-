extends RigidBody2D
## Black ball — falls under gravity, bounces off lines, collects coins.

const RADIUS := 40.0
const COLOR := Color(0.0667, 0.0667, 0.0667)


func _ready() -> void:
	gravity_scale = 1.0
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
