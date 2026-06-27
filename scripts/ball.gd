extends RigidBody2D
## Player ball — blue-purple gradient, glow, squash & stretch, trail particles.

const RADIUS := 55.0
const GLOW_COLOR := Color(0.388, 0.4, 0.945, 0.15)
const BODY_TOP := Color(0.51, 0.46, 0.98)
const BODY_BOTTOM := Color(0.30, 0.22, 0.93)
const HIGHLIGHT_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const SHADOW_COLOR := Color(0.13, 0.10, 0.35, 0.25)

signal fell_off_screen

var _breath_tween: Tween = null
var _squash_tween: Tween = null
var _trail_particles: GPUParticles2D = null


func _ready() -> void:
	gravity_scale = 0.4

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.95
	mat.friction = 0.05
	physics_material_override = mat
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

	body_entered.connect(_on_body_entered)
	_create_trail_particles()
	_start_breath_animation()
	queue_redraw()


func _create_trail_particles() -> void:
	_trail_particles = GPUParticles2D.new()
	_trail_particles.name = "TrailParticles"
	_trail_particles.emitting = true
	_trail_particles.amount = 30
	_trail_particles.lifetime = 0.6
	_trail_particles.explosiveness = 1.0
	_trail_particles.process_material = _make_particle_material(Color(0.51, 0.46, 0.98, 0.5))
	add_child(_trail_particles)


func _make_particle_material(color: Color) -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_align_y = true
	mat.color = color
	mat.color_ramp = _make_color_ramp_gradient(color)
	mat.scale_min = 3.0
	mat.scale_max = 8.0
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 40.0
	mat.gravity = Vector3(0, 30, 0)
	mat.radial_accel_min = -30.0
	mat.radial_accel_max = -30.0
	mat.damping_min = 30.0
	mat.damping_max = 60.0
	return mat


func _make_color_ramp_gradient(base: Color) -> Gradient:
	var grad := Gradient.new()
	var c := base
	grad.set_color(0, Color(c.r, c.g, c.b, 0.6))
	grad.set_color(1, Color(c.r, c.g, c.b, 0.0))
	return grad


func _start_breath_animation() -> void:
	_breath_tween = create_tween().set_loops()
	_breath_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breath_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


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

	_play_squash_animation()


func _play_squash_animation() -> void:
	if _squash_tween and _squash_tween.is_running():
		_squash_tween.kill()
	_squash_tween = create_tween()
	_squash_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_squash_tween.tween_property(self, "scale", Vector2(1.25, 0.75), 0.08)
	_squash_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func _process(_delta: float) -> void:
	if global_position.y > 1350.0:
		fell_off_screen.emit()
		set_process(false)


func _draw() -> void:
	var s: float = scale.x
	# Shadow (offset downward)
	draw_circle(Vector2(3, 6) / s, RADIUS, SHADOW_COLOR)
	# Outer glow
	draw_circle(Vector2.ZERO, RADIUS + 10, GLOW_COLOR)
	draw_circle(Vector2.ZERO, RADIUS + 4, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, 0.25))
	# Main body — simulate vertical gradient with layered circles
	var steps := 8
	for i in range(steps):
		var t: float = float(i) / float(steps - 1)
		var r: float = RADIUS * (1.0 - t * 0.3)
		var col := BODY_TOP.lerp(BODY_BOTTOM, t)
		draw_circle(Vector2(0, t * RADIUS * 0.25), r, col)
	# Highlight (upper-left crescent)
	draw_circle(Vector2(-15, -22), 16.0, HIGHLIGHT_COLOR)
	draw_circle(Vector2(-10, -16), 8.0, Color(1.0, 1.0, 1.0, 0.2))
