extends Camera2D

@export var shake_duration := 0.18
@export var max_shake_pixels := 8.0

var remaining := 0.0
var strength := 0.0
var random := RandomNumberGenerator.new()


func shake(intensity: float) -> void:
	strength = maxf(strength, lerpf(3.0, max_shake_pixels, clampf(intensity, 0.0, 1.0)))
	remaining = shake_duration
	update_offset()


func clear() -> void:
	remaining = 0.0
	strength = 0.0
	offset = Vector2.ZERO


func step(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0:
		clear()
	else:
		update_offset()


func update_offset() -> void:
	var fade := remaining / maxf(shake_duration, 0.001)
	offset = Vector2.from_angle(random.randf_range(0.0, TAU)) * strength * fade * fade
