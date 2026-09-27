extends Node2D
## World-space sparkles, advanced by the ball so they pause with gameplay.

const SPACING := 5.0
const MAX_PARTICLES := 240

var particles: Array[Dictionary] = []
var distance_to_next := 0.0


func clear() -> void:
	particles.clear()
	distance_to_next = 0.0
	queue_redraw()


func step(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var particle := particles[i]
		particle.age += delta
		if particle.age >= particle.lifetime:
			particles.remove_at(i)
		else:
			particle.position += particle.velocity * delta
			if particle.get("burst", false):
				particle.velocity *= exp(-4.0 * delta)
	queue_redraw()


func emit_burst(at: Vector2, tint: Color) -> void:
	for i in range(32):
		if particles.size() >= MAX_PARTICLES:
			particles.pop_front()
		var angle := TAU * float(i) / 32.0 + randf_range(-0.08, 0.08)
		particles.append({
			"position": at,
			"velocity": Vector2.from_angle(angle) * randf_range(100.0, 360.0),
			"age": 0.0,
			"lifetime": randf_range(0.25, 0.55),
			"size": randf_range(2.0, 5.0),
			"phase": randf_range(0, TAU),
			"color": tint.lerp(Color.WHITE, randf_range(0.0, 0.5)),
			"burst": true,
		})
	queue_redraw()


func emit_segment(from: Vector2, to: Vector2) -> void:
	var distance := from.distance_to(to)
	if is_zero_approx(distance):
		return
	while distance_to_next < distance:
		if particles.size() >= MAX_PARTICLES:
			particles.pop_front()
		particles.append({
			"position": from.lerp(to, distance_to_next / distance) + Vector2(0, randf_range(-4, 4)),
			"velocity": Vector2(randf_range(-18, 18), randf_range(-24, 24)),
			"age": 0.0,
			"lifetime": randf_range(0.22, 0.48),
			"size": randf_range(1.5, 3.8),
			"phase": randf_range(0, TAU),
			"color": Color("66d9ff").lerp(Color("fff1b8"), randf()),
		})
		distance_to_next += SPACING
	distance_to_next -= distance
	queue_redraw()


func _draw() -> void:
	for particle in particles:
		var remaining: float = 1.0 - particle.age / particle.lifetime
		var twinkle: float = 0.65 + 0.35 * sin(particle.age * 45.0 + particle.phase)
		var sparkle_size: float = particle.size * remaining * twinkle
		var center := to_local(particle.position)
		var tint: Color = particle.color
		tint.a = remaining * 0.16
		draw_circle(center, sparkle_size * 2.5, tint)
		tint.a = remaining * twinkle
		if particle.get("burst", false):
			var tail := to_local(particle.position - particle.velocity * 0.025)
			draw_line(tail, center, tint, 1.5, true)
		draw_line(center - Vector2(sparkle_size, 0), center + Vector2(sparkle_size, 0), tint, 1.0, true)
		draw_line(center - Vector2(0, sparkle_size), center + Vector2(0, sparkle_size), tint, 1.0, true)
		draw_circle(center, sparkle_size * 0.35, Color(1, 1, 1, remaining))
