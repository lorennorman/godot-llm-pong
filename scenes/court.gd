class_name PongCourt
extends Node2D

signal point_scored(player: int)
signal paddle_hit(intensity: float)
signal served

@export var bounds := Rect2(24, 125, 952, 465)

@onready var player_one: PongPaddle = $PlayerOne
@onready var player_two: PongPaddle = $PlayerTwo
@onready var ball: PongBall = $Ball


func _ready() -> void:
	var center := bounds.get_center()
	player_one.configure(
		Rect2(bounds.position + Vector2(21, 0), Vector2(bounds.size.x / 2 - 71, bounds.size.y)),
		Vector2(bounds.position.x + 41, center.y - player_one.size.y / 2))
	player_two.configure(
		Rect2(Vector2(center.x + 50, bounds.position.y), Vector2(bounds.size.x / 2 - 71, bounds.size.y)),
		Vector2(bounds.end.x - 41 - player_two.size.x, center.y - player_two.size.y / 2))
	ball.configure(bounds, [player_one, player_two])
	ball.goal_scored.connect(_on_goal_scored)
	ball.paddle_hit.connect(paddle_hit.emit)
	ball.served.connect(served.emit)


func _on_goal_scored(player: int) -> void:
	point_scored.emit(player)


func prepare_serve(direction: float) -> void:
	player_one.reset()
	player_two.reset()
	ball.prepare_serve(direction)


func boost_paddle(player: int) -> void:
	var paddle := player_one if player == 0 else player_two
	paddle.boost()


func reset_paddle_upgrades() -> void:
	player_one.reset_upgrades()
	player_two.reset_upgrades()


func is_serving() -> bool:
	return ball.serve_timer > 0


func stop() -> void:
	ball.stop()


func step(delta: float) -> void:
	player_one.step(delta)
	player_two.step(delta)
	ball.step(delta)


func _draw() -> void:
	draw_rect(bounds, Color("0e1728"))
	draw_line(bounds.position, Vector2(bounds.end.x, bounds.position.y), Color("8191ae"), 2)
	draw_line(Vector2(bounds.position.x, bounds.end.y), bounds.end, Color("8191ae"), 2)
	for y in range(int(bounds.position.y + 12), int(bounds.end.y - 10), 26):
		draw_line(Vector2(bounds.get_center().x, y), Vector2(bounds.get_center().x, y + 12), Color("29364e"), 2)
