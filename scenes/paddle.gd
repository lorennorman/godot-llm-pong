class_name PongPaddle
extends Node2D

@export_enum("Player 1", "Player 2") var player: int = 0
@export var size := Vector2(16, 90)
@export var speed := 360.0
@export var color := Color("66d9ff")

var movement_bounds := Rect2()
var starting_position := Vector2.ZERO


func configure(bounds: Rect2, spawn: Vector2) -> void:
	movement_bounds = bounds
	starting_position = spawn
	reset()


func reset() -> void:
	position = starting_position


func step(delta: float) -> void:
	var keys := [KEY_W, KEY_A, KEY_S, KEY_D] if player == 0 else [KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]
	var direction := Vector2(
		float(Input.is_physical_key_pressed(keys[3])) - float(Input.is_physical_key_pressed(keys[1])),
		float(Input.is_physical_key_pressed(keys[2])) - float(Input.is_physical_key_pressed(keys[0]))
	)
	position += direction.limit_length() * speed * delta
	position = position.clamp(movement_bounds.position, movement_bounds.end - size)


func get_rect() -> Rect2:
	return Rect2(position, size)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
