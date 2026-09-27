extends Node
## Short synthesized PCM cues, cached at startup for immediate playback.

const SAMPLE_RATE := 22050

@onready var cue_player: AudioStreamPlayer = $Cue
@onready var hit_player: AudioStreamPlayer = $Hit

var serve_sound: AudioStreamWAV
var win_sound: AudioStreamWAV
var hit_sounds: Array[AudioStreamWAV] = []


func _ready() -> void:
	serve_sound = synthesize([69, 76, 81], [0.07, 0.07, 0.16])
	win_sound = synthesize([69, 72, 76, 81, 76, 81, 84, 88], [0.1, 0.1, 0.1, 0.2, 0.1, 0.1, 0.1, 0.45])
	for note in [69, 72, 76, 81]:
		hit_sounds.append(synthesize([note], [0.085], true))


func play_serve() -> void:
	cue_player.stream = serve_sound
	cue_player.play()


func play_win() -> void:
	hit_player.stop()
	cue_player.stream = win_sound
	cue_player.play()


func play_hit(intensity: float) -> void:
	var index := clampi(int(intensity * hit_sounds.size()), 0, hit_sounds.size() - 1)
	hit_player.stream = hit_sounds[index]
	hit_player.play()


func stop_all() -> void:
	cue_player.stop()
	hit_player.stop()


func set_paused(value: bool) -> void:
	cue_player.stream_paused = value
	hit_player.stream_paused = value


func synthesize(notes: Array, durations: Array, impact := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	for n in range(notes.size()):
		var count := int(float(durations[n]) * SAMPLE_RATE)
		var start := data.size()
		data.resize(start + count * 2)
		var phase := 0.0
		var frequency := 440.0 * pow(2.0, float(notes[n] - 69) / 12.0)
		for i in range(count):
			var t := float(i) / SAMPLE_RATE
			var remaining := float(count - 1 - i) / SAMPLE_RATE
			var envelope := minf(t / 0.003, 1.0) * minf(remaining / 0.025, 1.0)
			var pitch := frequency
			if impact:
				pitch *= 1.0 + 1.8 * exp(-t * 70.0)
				envelope *= exp(-t * 22.0)
			phase = fmod(phase + pitch / SAMPLE_RATE, 1.0)
			var pulse := 1.0 if phase < 0.25 else -1.0
			var triangle := 1.0 - 4.0 * absf(phase - 0.5)
			var sample := (pulse * 0.7 + triangle * 0.3) * envelope * 0.4
			data.encode_s16(start + i * 2, int(sample * 32767.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = SAMPLE_RATE
	sound.data = data
	return sound
