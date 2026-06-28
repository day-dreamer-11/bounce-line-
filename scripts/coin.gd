extends Area2D
## Gold coin — texture from assets/coin.png, collision matches display.

const DISPLAY_RADIUS := 54.0

signal collected

var _collect_tween: Tween = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_texture()
	_start_float_animation()


func _setup_texture() -> void:
	var tex := load("res://assets/coin.png")
	if not tex:
		return

	var tex_size: float = tex.get_width()
	var scale_val: float = DISPLAY_RADIUS * 2 / tex_size

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2(scale_val, scale_val)
	add_child(sprite)

	var shape := CircleShape2D.new()
	shape.radius = DISPLAY_RADIUS
	$CollisionShape2D.shape = shape


func _start_float_animation() -> void:
	var tw := create_tween().set_loops()
	var start_y := position.y
	tw.tween_property(self, "position:y", start_y - 6.0, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", start_y + 6.0, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _on_body_entered(_body: Node2D) -> void:
	collected.emit()
	_play_collect_animation()


func _play_collect_animation() -> void:
	if _collect_tween and _collect_tween.is_running():
		return
	$CollisionShape2D.set_deferred("disabled", true)
	_collect_tween = create_tween()
	_collect_tween.set_parallel(true)
	_collect_tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_collect_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	_collect_tween.chain().tween_callback(queue_free)
