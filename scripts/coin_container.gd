extends Node2D
## Spawns 5 coins at random non-overlapping positions.

const COIN_COUNT := 5
const COIN_RADIUS := 18.0
const EDGE_MARGIN := 80.0
const BALL_SAFE_DIST := 120.0

var _coin_scene: PackedScene = null


func _ready() -> void:
	_coin_scene = load("res://scenes/Coin.tscn")
	_spawn_coins()


func _spawn_coins() -> void:
	var bounds := get_viewport().get_visible_rect().size
	var ball_pos := Vector2(360, 100)
	var placed: Array[Vector2] = []

	for _i in COIN_COUNT:
		var pos := _find_valid_position(bounds, ball_pos, placed)
		placed.append(pos)
		var coin := _coin_scene.instantiate()
		coin.position = pos
		add_child(coin)


func _find_valid_position(bounds: Vector2, ball_pos: Vector2, existing: Array[Vector2]) -> Vector2:
	var margin := EDGE_MARGIN + COIN_RADIUS
	var min_spacing := COIN_RADIUS * 3.0

	for _attempt in 200:
		var x := randf_range(margin, bounds.x - margin)
		var y := randf_range(margin, bounds.y - margin)
		var pos := Vector2(x, y)

		if pos.distance_to(ball_pos) < BALL_SAFE_DIST:
			continue

		var ok := true
		for p in existing:
			if pos.distance_to(p) < min_spacing:
				ok = false
				break
		if ok:
			return pos

	# Fallback
	return Vector2(randf_range(margin, bounds.x - margin), randf_range(margin, bounds.y - margin))
