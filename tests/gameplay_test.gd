extends SceneTree

func _initialize() -> void:
	call_deferred("check_game")

func check_game() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var court = game.get_node("Court")
	var ball = court.ball
	var initial_speed_one: float = court.player_one.speed
	var initial_speed_two: float = court.player_two.speed
	assert(court.player_one.position == Vector2(65, 312.5))
	assert(court.player_two.position == Vector2(919, 312.5))
	game._physics_process(1.1)
	assert(ball.velocity.length() > 0)
	assert(game.sound_effects.cue_player.stream == game.sound_effects.serve_sound)
	assert(game.sound_effects.cue_player.playing)
	ball.position = Vector2(500, 134)
	ball.velocity = Vector2(100, -300)
	ball.step(0.02)
	assert(ball.velocity.y > 0)
	ball.position = Vector2(92, court.player_one.position.y + 45)
	ball.velocity = Vector2(-390, 0)
	ball.step(0.02)
	assert(ball.velocity.x > 0)
	assert(game.sound_effects.hit_player.playing)
	game.paused = true
	var before: Vector2 = ball.position
	game._physics_process(0.1)
	assert(ball.position == before)
	game.paused = false
	for point in range(7):
		ball.serve_timer = 0
		ball.position = Vector2(990, 200)
		ball.velocity = Vector2(390, 0)
		game._physics_process(0.02)
		assert(game.scores[0] == point + 1)
		assert(is_equal_approx(court.player_one.speed, initial_speed_one))
		assert(is_equal_approx(court.player_two.speed, initial_speed_two * pow(1.1, point + 1)))
		assert(court.player_one.size == Vector2(16, 90))
		assert(is_equal_approx(court.player_one.bounce_strength, 1.0))
		assert(is_equal_approx(court.player_two.size.y, 90 * pow(1.1, point + 1)))
		assert(is_equal_approx(court.player_two.bounce_strength, pow(1.1, point + 1)))
		assert(court.player_two.get_rect().position.y >= court.bounds.position.y)
		assert(court.player_two.get_rect().end.y <= court.bounds.end.y)
	assert(game.winner == 0)
	assert(game.sound_effects.cue_player.stream == game.sound_effects.win_sound)
	assert(game.sound_effects.cue_player.playing)
	assert(ball.velocity == Vector2.ZERO)
	game.reset_match()
	assert(game.scores == [0, 0])
	assert(game.winner == -1 and court.is_serving())
	assert(court.player_two.size == Vector2(16, 90))
	assert(is_equal_approx(court.player_two.bounce_strength, 1.0))
	assert(is_equal_approx(court.player_one.speed, initial_speed_one))
	assert(is_equal_approx(court.player_two.speed, initial_speed_two))
	ball.serve_timer = 0
	ball.position = Vector2(10, 200)
	ball.velocity = Vector2(-390, 0)
	game._physics_process(0.02)
	assert(game.scores == [0, 1])
	assert(is_equal_approx(court.player_one.size.y, 99.0))
	assert(is_equal_approx(court.player_one.bounce_strength, 1.1))
	assert(court.player_two.size == Vector2(16, 90))
	assert(is_equal_approx(court.player_two.bounce_strength, 1.0))
	assert(is_equal_approx(court.player_one.speed, initial_speed_one * 1.1))
	assert(is_equal_approx(court.player_two.speed, initial_speed_two))
	game.reset_match()
	var left_far := hit_speed(court, court.player_one, 65.0, 390.0)
	var left_mid := hit_speed(court, court.player_one, 250.0, 390.0)
	var left_near := hit_speed(court, court.player_one, 434.0, 390.0)
	assert(left_far < left_mid and left_mid < left_near)
	var right_far := hit_speed(court, court.player_two, 919.0, 390.0)
	var right_near := hit_speed(court, court.player_two, 550.0, 390.0)
	assert(is_equal_approx(left_far, right_far))
	assert(is_equal_approx(left_near, right_near))
	game.award_point(1)
	assert(is_equal_approx(hit_speed(court, court.player_one, 65.0, 390.0), left_far * 1.1))
	assert(is_equal_approx(hit_speed(court, court.player_two, 919.0, 390.0), right_far))
	game.award_point(0)
	assert(is_equal_approx(hit_speed(court, court.player_two, 919.0, 390.0), right_far * 1.1))
	assert(is_equal_approx(hit_speed(court, court.player_one, 434.0, 840.0), ball.max_speed))
	assert(is_equal_approx(hit_speed(court, court.player_two, 550.0, 840.0), ball.max_speed))
	game.reset_match()
	assert(court.player_one.size == Vector2(16, 90))
	assert(court.player_two.size == Vector2(16, 90))
	assert(is_equal_approx(hit_speed(court, court.player_one, 65.0, 390.0), left_far))
	assert(is_equal_approx(hit_speed(court, court.player_two, 919.0, 390.0), right_far))
	print("PASS: gameplay, paddle upgrades, net hit power, symmetry, speed cap, restart")
	quit()


func hit_speed(court: PongCourt, paddle: PongPaddle, x: float, incoming_speed: float) -> float:
	paddle.position.x = x
	var ball := court.ball
	var direction := 1.0 if paddle.player == 0 else -1.0
	var face_x := paddle.position.x + paddle.size.x if paddle.player == 0 else paddle.position.x
	ball.serve_timer = 0
	ball.position = Vector2(face_x + direction * (ball.radius + 1), paddle.position.y + paddle.size.y / 2)
	ball.velocity = Vector2(-direction * incoming_speed, 0)
	ball.step(0.01)
	assert(ball.velocity.x * direction > 0)
	return ball.velocity.length()
