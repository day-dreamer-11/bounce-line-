extends RigidBody2D
## Player ball — uses texture from assets/ball.png

const RADIUS := 72.0

signal fell_off_screen


func _ready() -> void:
	gravity_scale = 0.4

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.95
	mat.friction = 0.05
	physics_material_override = mat
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

	body_entered.connect(_on_body_entered)
	_create_sprite()


func _create_sprite() -> void:
	var tex := load("res://assets/ball.png")
	if not tex:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2(RADIUS * 2 / tex.get_width(), RADIUS * 2 / tex.get_height())
	add_child(sprite)


func _on_body_entered(body: Node) -> void:
	var is_stroke := false
	var parent := body.get_parent()
	if parent and parent.has_method("add_point"):
		is_stroke = true
	elif body.has_method("reset_timer"):
		is_stroke = true

	if is_stroke:
		var vel := linear_velocity
		vel.y *= 1.3 if vel.y < 0 else 1.0
		vel.y -= 150.0
		linear_velocity = vel


func _process(_delta: float) -> void:
	if global_position.y > 1350.0:
		fell_off_screen.emit()
		set_process(false)
