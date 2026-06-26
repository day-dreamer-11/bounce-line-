extends RigidBody2D
## Black ball — falls under gravity, bounces off lines, collects coins.

const RADIUS := 40.0
const COLOR := Color(0.0667, 0.0667, 0.0667)


func _ready() -> void:
	gravity_scale = 0.4

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.95
	mat.friction = 0.05
	physics_material_override = mat
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
