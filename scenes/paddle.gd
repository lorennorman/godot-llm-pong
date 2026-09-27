class_name PongPaddle
extends Node2D

@export_enum("Player 1", "Player 2") var player: int = 0
@export var size := Vector2(16, 90)
@export var speed := 360.0
@export var bounce_strength := 1.0
@export var color := Color("66d9ff")
@export var motion_blur_duration := 0.12

@onready var starting_speed: float = speed
@onready var starting_size: Vector2 = size
@onready var starting_bounce_strength: float = bounce_strength

var movement_bounds := Rect2()
var starting_position := Vector2.ZERO
var motion_samples: Array[Dictionary] = []


func configure(bounds: Rect2, spawn: Vector2) -> void:
	movement_bounds = bounds
	starting_position = spawn
	reset()


func reset() -> void:
	position = starting_position
	position.y = movement_bounds.get_center().y - size.y / 2
	motion_samples.clear()
	queue_redraw()


func boost() -> void:
	speed *= 1.1
	bounce_strength *= 1.1
	var old_height := size.y
	size.y = minf(size.y * 1.1, movement_bounds.size.y)
	position.y -= (size.y - old_height) / 2
	position = position.clamp(movement_bounds.position, movement_bounds.end - size)
	motion_samples.clear()
	queue_redraw()


func reset_upgrades() -> void:
	speed = starting_speed
	size = starting_size
	bounce_strength = starting_bounce_strength
	motion_samples.clear()
	queue_redraw()


func step(delta: float) -> void:
	for i in range(motion_samples.size() - 1, -1, -1):
		motion_samples[i].age += delta
		if motion_samples[i].age >= motion_blur_duration:
			motion_samples.remove_at(i)
	var previous_position := position
	var keys := [KEY_W, KEY_A, KEY_S, KEY_D] if player == 0 else [KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]
	var direction := Vector2(
		float(Input.is_physical_key_pressed(keys[3])) - float(Input.is_physical_key_pressed(keys[1])),
		float(Input.is_physical_key_pressed(keys[2])) - float(Input.is_physical_key_pressed(keys[0]))
	)
	position += direction.limit_length() * speed * delta
	position = position.clamp(movement_bounds.position, movement_bounds.end - size)
	var distance := previous_position.distance_to(position)
	if distance > 0.01 and motion_blur_duration > 0:
		# Closely spaced silhouettes produce a smooth smear along the actual path.
		var count := mini(100, ceili(distance / 3.0))
		for i in range(count):
			var weight := float(i) / count
			motion_samples.append({
				"position": previous_position.lerp(position, weight),
				"age": delta * (1.0 - weight),
			})
		while motion_samples.size() > 100:
			motion_samples.pop_front()
	queue_redraw()


func get_rect() -> Rect2:
	return Rect2(position, size)


func _draw() -> void:
	var body := Rect2(Vector2.ZERO, size)
	for sample in motion_samples:
		var fade := clampf(1.0 - float(sample.age) / maxf(motion_blur_duration, 0.001), 0.0, 1.0)
		var ghost := Rect2(Vector2(sample.position) - position, size)
		draw_rect(ghost.grow(3.0), Color(color, color.a * fade * fade * 0.012))
		draw_rect(ghost.grow(1.0), Color(color, color.a * fade * fade * 0.025))
		draw_rect(ghost, Color(color, color.a * fade * fade * 0.07))
	draw_rect(body, color)
