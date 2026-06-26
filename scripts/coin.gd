extends Area2D
## Gold coin — disappears when touched by the ball.

const RADIUS := 16.0
const COLOR := Color(1.0, 0.835, 0.31)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
