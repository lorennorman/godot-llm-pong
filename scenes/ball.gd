class_name PongBall
extends Node2D

signal goal_scored(player: int)
signal paddle_hit(intensity: float)
signal served

@export var radius := 9.0
@export var start_speed := 390.0
@export var max_speed := 850.0
@export var base_hit_speed_boost := 0.06
@export var net_hit_speed_bonus := 0.24
@export var color := Color("eaf1ff")

var velocity := Vector2.ZERO
var serve_timer := 0.0
var serve_direction := 1.0
var court_bounds := Rect2()
var paddles: Array[PongPaddle] = []

@onready var trail = $Trail


func configure(bounds: Rect2, court_paddles: Array[PongPaddle]) -> void:
	court_bounds = bounds
	paddles = court_paddles


func prepare_serve(direction: float) -> void:
	trail.clear()
	position = court_bounds.get_center()
	velocity = Vector2.ZERO
	serve_direction = direction
	serve_timer = 1.0


func stop() -> void:
	velocity = Vector2.ZERO


func step(delta: float) -> void:
	trail.step(delta)
	if serve_timer > 0:
		serve_timer -= delta
		if serve_timer <= 0:
			velocity = Vector2(serve_direction, randf_range(-0.45, 0.45)).normalized() * start_speed
			served.emit()
		return
	# Small steps keep collisions reliable at maximum speed.
	var steps := maxi(1, ceili(velocity.length() * delta / radius))
	for index in range(steps):
		if advance(delta / steps):
			break


func advance(delta: float) -> bool:
	var previous_position := global_position
	position += velocity * delta
	if position.y < court_bounds.position.y + radius:
		position.y = court_bounds.position.y + radius
		velocity.y = absf(velocity.y)
	elif position.y > court_bounds.end.y - radius:
		position.y = court_bounds.end.y - radius
		velocity.y = -absf(velocity.y)

	for paddle in paddles:
		var approaching := velocity.x < 0 if paddle.player == 0 else velocity.x > 0
		var rect := paddle.get_rect()
		if approaching and rect.grow(radius).has_point(position):
			var offset := clampf((position.y - rect.get_center().y) / (rect.size.y / 2), -1, 1)
			var angle := offset * deg_to_rad(60.0)
			var direction := 1.0 if paddle.player == 0 else -1.0
			# Moving toward the net adds power, symmetrically for both players.
			var net_distance := absf(rect.get_center().x - court_bounds.get_center().x)
			var net_proximity := clampf(1.0 - net_distance / (court_bounds.size.x / 2), 0.0, 1.0)
			var multiplier := 1.0 + base_hit_speed_boost + net_hit_speed_bonus * net_proximity
			var speed := minf(velocity.length() * multiplier * paddle.bounce_strength, max_speed)
			velocity = Vector2(direction * cos(angle), sin(angle)) * speed
			position.x = rect.end.x + radius if paddle.player == 0 else rect.position.x - radius
			var contact := Vector2(
				paddle.size.x if paddle.player == 0 else 0.0,
				clampf(position.y - paddle.position.y, 0.0, paddle.size.y))
			trail.emit_burst(paddle.to_global(contact), paddle.color)
			paddle_hit.emit(speed / max_speed)

	trail.emit_segment(previous_position, global_position)
	var scorer := -1
	if position.x < court_bounds.position.x - radius:
		scorer = 1
	elif position.x > court_bounds.end.x + radius:
		scorer = 0
	if scorer >= 0:
		stop()
		goal_scored.emit(scorer)
		return true
	return false


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
