extends SceneTree

func _initialize() -> void:
	call_deferred("check_game")

func check_game() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var court = game.get_node("Court")
	var ball = court.ball
	assert(court.player_one.position == Vector2(65, 312.5))
	assert(court.player_two.position == Vector2(919, 312.5))
	game._physics_process(1.1)
	assert(ball.velocity.length() > 0)
	ball.position = Vector2(500, 134)
	ball.velocity = Vector2(100, -300)
	ball.step(0.02)
	assert(ball.velocity.y > 0)
	ball.position = Vector2(92, court.player_one.position.y + 45)
	ball.velocity = Vector2(-390, 0)
	ball.step(0.02)
	assert(ball.velocity.x > 0)
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
	assert(game.winner == 0)
	assert(ball.velocity == Vector2.ZERO)
	game.reset_match()
	assert(game.scores == [0, 0])
	assert(game.winner == -1 and court.is_serving())
	print("PASS: scene wiring, serve, wall/paddle bounces, pause, scoring, victory, restart")
	quit()
