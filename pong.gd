extends Node2D
## Local two-player Pong. Everything is drawn in a fixed 1000 x 650 viewport.

const WIN_SCORE := 7
const WHITE := Color("eaf1ff")
const MUTED := Color("8191ae")
const BLUE := Color("66d9ff")
const PINK := Color("ff83b5")

@onready var court: PongCourt = $Court
@onready var shake_camera = $ShakeCamera
@onready var sound_effects = $SoundEffects

var scores: Array[int] = [0, 0]
var paused := false
var winner := -1
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	court.point_scored.connect(award_point)
	court.paddle_hit.connect(shake_camera.shake)
	court.paddle_hit.connect(sound_effects.play_hit)
	court.served.connect(sound_effects.play_serve)
	reset_match()


func reset_match() -> void:
	scores = [0, 0]
	winner = -1
	paused = false
	sound_effects.stop_all()
	sound_effects.set_paused(false)
	shake_camera.clear()
	court.reset_paddle_upgrades()
	prepare_serve(1.0 if randf() > 0.5 else -1.0)


func prepare_serve(direction: float) -> void:
	court.prepare_serve(direction)
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			reset_match()
		elif event.physical_keycode == KEY_SPACE and winner < 0:
			paused = not paused
			sound_effects.set_paused(paused)
		queue_redraw()


func _physics_process(delta: float) -> void:
	if paused:
		return
	shake_camera.step(delta)
	if winner >= 0:
		return
	court.step(delta)
	queue_redraw()


func award_point(player: int) -> void:
	scores[player] += 1
	court.boost_paddle(1 - player)
	if scores[player] >= WIN_SCORE:
		winner = player
		court.stop()
		sound_effects.play_win()
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
	centered_text("Move within your half  |  SPACE pause  |  R restart  |  M music", 500, 625, 17, MUTED)
	var message := ""
	if winner >= 0:
		message = "PLAYER %d WINS!  /  R TO PLAY AGAIN" % (winner + 1)
	elif paused:
		message = "PAUSED  /  SPACE TO RESUME"
	elif court.is_serving():
		message = "GET READY"
	if not message.is_empty():
		draw_rect(Rect2(180, 280, 640, 70), Color(0.035, 0.05, 0.09, 0.94))
		centered_text(message, 500, 325, 24, WHITE)
