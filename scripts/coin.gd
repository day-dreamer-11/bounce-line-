extends Area2D
## Gold coin — disappears when touched by the ball.

const RADIUS := 18.0
const FILL_COLOR := Color(1.0, 0.835, 0.31)
const RIM_COLOR := Color(0.9, 0.7, 0.1)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	# Outer rim
	draw_circle(Vector2.ZERO, RADIUS, RIM_COLOR)
	# Inner face
	draw_circle(Vector2.ZERO, RADIUS - 3.0, FILL_COLOR)
	# Center dot
	draw_circle(Vector2.ZERO, 4.0, RIM_COLOR)


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
