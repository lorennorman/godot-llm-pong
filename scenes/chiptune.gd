extends AudioStreamPlayer
## An original eight-bar loop rendered directly into Godot's audio generator.

const SAMPLE_RATE := 22050.0
const BPM := 144.0
const STEP_SAMPLES := int(SAMPLE_RATE * 60.0 / BPM / 4.0)
const STEP_SECONDS := float(STEP_SAMPLES) / SAMPLE_RATE
const ROOTS := [45, 41, 48, 43, 45, 41, 48, 43]
const MELODY := [
	[76, 0, 81, 0, 83, 81, 0, 76, 79, 0, 76, 0, 74, 76, 0, 0],
	[77, 0, 81, 0, 84, 81, 0, 77, 76, 0, 72, 0, 74, 76, 77, 0],
	[79, 0, 84, 0, 83, 79, 0, 76, 79, 0, 76, 0, 72, 74, 76, 0],
	[74, 0, 79, 0, 83, 81, 0, 79, 78, 0, 74, 0, 71, 74, 0, 0],
	[81, 0, 84, 0, 88, 84, 83, 81, 79, 0, 81, 0, 76, 79, 81, 0],
	[81, 0, 84, 0, 89, 88, 0, 84, 81, 0, 77, 0, 79, 81, 84, 0],
	[84, 0, 88, 0, 91, 88, 0, 84, 83, 0, 79, 0, 76, 79, 84, 0],
	[83, 0, 86, 0, 91, 86, 83, 79, 78, 0, 74, 0, 76, 79, 83, 0],
]

var playback: AudioStreamGeneratorPlayback
var step_index := -1
var sample_in_step := 0
var lead_frequency := 0.0
var bass_frequency := 0.0
var arp_frequency := 0.0
var lead_phase := 0.0
var bass_phase := 0.0
var arp_phase := 0.0
var kick_phase := 0.0
var noise := RandomNumberGenerator.new()
var muted := false


func _ready() -> void:
	noise.seed = 8675309
	advance_step()
	play()
	playback = get_stream_playback()
	fill_buffer()


func _process(_delta: float) -> void:
	fill_buffer()


func _exit_tree() -> void:
	stop()
	playback = null
	stream = null


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		muted = not muted
		volume_db = -80.0 if muted else -12.0


func fill_buffer() -> void:
	if playback == null:
		return
	var available := playback.get_frames_available()
	var frames := PackedVector2Array()
	frames.resize(available)
	for i in range(available):
		frames[i] = synthesize_frame()
	playback.push_buffer(frames)


func frequency(midi: int) -> float:
	return 440.0 * pow(2.0, float(midi - 69) / 12.0)


func advance_step() -> void:
	step_index = (step_index + 1) % 128
	sample_in_step = 0
	var bar := int(step_index / 16)
	var beat := step_index % 16
	var note: int = MELODY[bar][beat]
	lead_frequency = frequency(note) if note > 0 else 0.0
	bass_frequency = frequency(ROOTS[bar] + (12 if beat % 8 >= 6 else 0))
	var third := 3 if bar % 4 == 0 else 4
	var chord := [0, third, 7, 12]
	arp_frequency = frequency(ROOTS[bar] + 24 + chord[beat % 4])
	if beat % 8 == 0:
		kick_phase = 0.0


func synthesize_frame() -> Vector2:
	var t := float(sample_in_step) / SAMPLE_RATE
	var beat := step_index % 16
	var attack := minf(t / 0.003, 1.0)
	var release := clampf((STEP_SECONDS * 0.9 - t) / 0.018, 0.0, 1.0)
	lead_phase = fmod(lead_phase + lead_frequency / SAMPLE_RATE, 1.0)
	bass_phase = fmod(bass_phase + bass_frequency / SAMPLE_RATE, 1.0)
	arp_phase = fmod(arp_phase + arp_frequency / SAMPLE_RATE, 1.0)
	var lead := (1.0 if lead_phase < 0.25 else -1.0) * 0.16 * attack * release
	if lead_frequency == 0.0:
		lead = 0.0
	var bass_t := float(beat % 2) * STEP_SECONDS + t
	var bass_env := minf(bass_t / 0.004, 1.0) * clampf((STEP_SECONDS * 1.9 - bass_t) / 0.025, 0.0, 1.0)
	var bass := (1.0 - 4.0 * absf(bass_phase - 0.5)) * 0.23 * bass_env
	var arp := (1.0 if arp_phase < 0.5 else -1.0) * 0.055 * attack * exp(-t * 28.0) * release
	var kick_t := float(beat % 8) * STEP_SECONDS + t
	kick_phase = fmod(kick_phase + (48.0 + 110.0 * exp(-kick_t * 35.0)) / SAMPLE_RATE, 1.0)
	var kick := sin(kick_phase * TAU) * exp(-kick_t * 18.0) * 0.3
	var hiss := noise.randf_range(-1.0, 1.0)
	var snare := 0.0
	if beat % 8 == 4:
		snare = hiss * exp(-t * 32.0) * 0.17 * attack
	var hat := hiss * exp(-t * 95.0) * (0.065 if beat % 2 == 0 else 0.025) * attack
	var center := bass + kick + snare + hat
	var frame := Vector2(center + lead + arp * 0.55, center + lead * 0.75 + arp)
	sample_in_step += 1
	if sample_in_step >= STEP_SAMPLES:
		advance_step()
	return frame
