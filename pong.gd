extends Node2D
## Local two-player Pong. Everything is drawn in a fixed 1000 x 650 viewport.

const COURT := Rect2(24, 125, 952, 465)
const PADDLE_SIZE := Vector2(16, 90)
const PADDLE_SPEED := 360.0
const BALL_RADIUS := 9.0
const START_SPEED := 390.0
const MAX_SPEED := 850.0
const WIN_SCORE := 7
const WHITE := Color("eaf1ff")
const MUTED := Color("8191ae")
const BLUE := Color("66d9ff")
const PINK := Color("ff83b5")

var paddles: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var scores: Array[int] = [0, 0]
var ball := Vector2.ZERO
var velocity := Vector2.ZERO
var serve_timer := 0.0
var serve_direction := 1.0
var paused := false
var winner := -1
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	reset_match()


func reset_match() -> void:
	scores = [0, 0]
	winner = -1
	paused = false
	prepare_serve(1.0 if randf() > 0.5 else -1.0)


func prepare_serve(direction: float) -> void:
	paddles[0] = Vector2(65, COURT.get_center().y - PADDLE_SIZE.y / 2)
	paddles[1] = Vector2(919, paddles[0].y)
	ball = COURT.get_center()
	velocity = Vector2.ZERO
	serve_direction = direction
	serve_timer = 1.0
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			reset_match()
		elif event.physical_keycode == KEY_SPACE and winner < 0:
			paused = not paused
		queue_redraw()


func _physics_process(delta: float) -> void:
	if paused or winner >= 0:
		return
	move_paddles(delta)
	if serve_timer > 0:
		serve_timer -= delta
		if serve_timer <= 0:
			velocity = Vector2(serve_direction, randf_range(-0.45, 0.45)).normalized() * START_SPEED
	else:
		# Small steps keep collisions reliable even at the maximum ball speed.
		var steps := maxi(1, ceili(velocity.length() * delta / BALL_RADIUS))
		for step in range(steps):
			advance_ball(delta / steps)
			if serve_timer > 0 or winner >= 0:
				break
	queue_redraw()


func move_paddles(delta: float) -> void:
	var directions: Array[Vector2] = [
		Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))),
		Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)))
	]
	for i in range(2):
		paddles[i] += directions[i].limit_length() * PADDLE_SPEED * delta
		paddles[i].y = clampf(paddles[i].y, COURT.position.y, COURT.end.y - PADDLE_SIZE.y)
		var min_x := 45.0 if i == 0 else 550.0
		var max_x := 434.0 if i == 0 else 939.0
		paddles[i].x = clampf(paddles[i].x, min_x, max_x)


func advance_ball(delta: float) -> void:
	ball += velocity * delta
	if ball.y < COURT.position.y + BALL_RADIUS:
		ball.y = COURT.position.y + BALL_RADIUS
		velocity.y = absf(velocity.y)
	elif ball.y > COURT.end.y - BALL_RADIUS:
		ball.y = COURT.end.y - BALL_RADIUS
		velocity.y = -absf(velocity.y)

	for i in range(2):
		var approaching := velocity.x < 0 if i == 0 else velocity.x > 0
		if approaching and Rect2(paddles[i], PADDLE_SIZE).grow(BALL_RADIUS).has_point(ball):
			var offset := clampf((ball.y - paddles[i].y - PADDLE_SIZE.y / 2) / (PADDLE_SIZE.y / 2), -1, 1)
			var angle := offset * deg_to_rad(60.0)
			var direction := 1.0 if i == 0 else -1.0
			var speed := minf(velocity.length() * 1.06, MAX_SPEED)
			velocity = Vector2(direction * cos(angle), sin(angle)) * speed
			ball.x = paddles[i].x + PADDLE_SIZE.x + BALL_RADIUS if i == 0 else paddles[i].x - BALL_RADIUS

	if ball.x < COURT.position.x - BALL_RADIUS:
		award_point(1)
	elif ball.x > COURT.end.x + BALL_RADIUS:
		award_point(0)


func award_point(player: int) -> void:
	scores[player] += 1
	if scores[player] >= WIN_SCORE:
		winner = player
		velocity = Vector2.ZERO
	else:
		prepare_serve(-1.0 if player == 1 else 1.0)


func centered_text(text: String, center_x: float, baseline: float, size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(center_x - width / 2, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw() -> void:
	centered_text("PONG", 500, 38, 26, WHITE)
	centered_text("PLAYER 1  /  WASD", 190, 52, 18, BLUE)
	centered_text("PLAYER 2  /  ARROW KEYS", 810, 52, 18, PINK)
	centered_text(str(scores[0]), 425, 100, 46, BLUE)
	centered_text(str(scores[1]), 575, 100, 46, PINK)
	centered_text("FIRST TO %d" % WIN_SCORE, 500, 120, 12, MUTED)
	draw_rect(COURT, Color("0e1728"))
	draw_line(COURT.position, Vector2(COURT.end.x, COURT.position.y), MUTED, 2)
	draw_line(Vector2(COURT.position.x, COURT.end.y), COURT.end, MUTED, 2)
	for y in range(137, 580, 26):
		draw_line(Vector2(500, y), Vector2(500, y + 12), Color("29364e"), 2)
	draw_rect(Rect2(paddles[0], PADDLE_SIZE), BLUE)
	draw_rect(Rect2(paddles[1], PADDLE_SIZE), PINK)
	draw_circle(ball, BALL_RADIUS, WHITE)
	centered_text("Move within your half  |  SPACE pause  |  R restart", 500, 625, 17, MUTED)
	var message := ""
	if winner >= 0:
		message = "PLAYER %d WINS!  /  R TO PLAY AGAIN" % (winner + 1)
	elif paused:
		message = "PAUSED  /  SPACE TO RESUME"
	elif serve_timer > 0:
		message = "GET READY"
	if not message.is_empty():
		draw_rect(Rect2(180, 280, 640, 70), Color(0.035, 0.05, 0.09, 0.94))
		centered_text(message, 500, 325, 24, WHITE)
