extends RigidBody2D
## Player ball — texture from assets/ball.png, collision matches displayed size.

const DISPLAY_RADIUS := 80.0

signal fell_off_screen


func _ready() -> void:
	gravity_scale = 0.4

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.95
	mat.friction = 0.05
	physics_material_override = mat
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

	body_entered.connect(_on_body_entered)
	_setup_texture()


func _setup_texture() -> void:
	var tex := load("res://assets/ball.png")
	if not tex:
		return

	var sprite := Sprite2D.new()
	sprite.texture = tex
	var tex_size: float = tex.get_width()
	sprite.scale = Vector2(DISPLAY_RADIUS * 2 / tex_size, DISPLAY_RADIUS * 2 / tex_size)
	add_child(sprite)

	var shape := CircleShape2D.new()
	shape.radius = DISPLAY_RADIUS
	$CollisionShape2D.shape = shape


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
