extends Node
## Sons gerados por síntese simples (autoload "Sfx"). Nenhum arquivo de áudio
## externo: tudo é criado como AudioStreamWAV na inicialização.

const RATE := 22050

var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var ambient: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 1337
	for i in 16:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	_build_all()
	ambient = AudioStreamPlayer.new()
	ambient.stream = streams["ambient"]
	ambient.volume_db = -16.0
	add_child(ambient)


func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not streams.has(sound):
		return
	var chosen: AudioStreamPlayer = null
	for p in players:
		if not p.playing:
			chosen = p
			break
	if chosen == null:
		chosen = players[0]
		players.push_back(players.pop_front())
	chosen.stream = streams[sound]
	chosen.volume_db = volume_db
	chosen.pitch_scale = pitch * randf_range(0.94, 1.06)
	chosen.play()


func start_ambient() -> void:
	if not ambient.playing:
		ambient.play()


func stop_ambient() -> void:
	ambient.stop()


# ---------------------------------------------------------------- síntese

func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)


func _to_stream(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s


## Gera `dur` segundos chamando gen(t, dur) -> float para cada amostra.
func _synth(dur: float, gen: Callable) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = gen.call(float(i) / RATE, dur)
	return out


func _sq(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0


func _build_all() -> void:
	var lp := [0.0]
	var ph := [0.0]

	# Rebite: estalo metálico com queda de tom.
	ph[0] = 0.0
	streams["shot"] = _to_stream(_synth(0.1, func(t: float, d: float) -> float:
		var f := lerpf(1100.0, 280.0, t / d)
		ph[0] += f / RATE
		var e := pow(1.0 - t / d, 2.0)
		return (_sq(ph[0]) * 0.3 + _noise() * 0.25) * e))

	# Tiro do guarda: mais grave e sujo.
	ph[0] = 0.0
	lp[0] = 0.0
	streams["eshot"] = _to_stream(_synth(0.16, func(t: float, d: float) -> float:
		var f := lerpf(260.0, 90.0, t / d)
		ph[0] += f / RATE
		lp[0] = lerpf(lp[0], _noise(), 0.35)
		var e := pow(1.0 - t / d, 1.6)
		return (_sq(ph[0]) * 0.25 + lp[0] * 0.6) * e))

	streams["hit"] = _to_stream(_synth(0.08, func(t: float, d: float) -> float:
		return _noise() * 0.5 * (1.0 - t / d)))

	streams["clang"] = _to_stream(_synth(0.3, func(t: float, _d: float) -> float:
		return (sin(TAU * 1250.0 * t) + 0.6 * sin(TAU * 1830.0 * t) + 0.3 * sin(TAU * 2710.0 * t)) * exp(-t * 16.0) * 0.22))

	streams["ricochet"] = _to_stream(_synth(0.12, func(t: float, d: float) -> float:
		return (sin(TAU * lerpf(2400.0, 1400.0, t / d) * t) * 0.25 + _noise() * 0.15) * (1.0 - t / d)))

	lp[0] = 0.0
	streams["explosion"] = _to_stream(_synth(0.9, func(t: float, _d: float) -> float:
		lp[0] = lerpf(lp[0], _noise(), 0.09)
		return (lp[0] * 2.2 * exp(-t * 4.0) + sin(TAU * 55.0 * t) * 0.5 * exp(-t * 6.0))))

	lp[0] = 0.0
	streams["steam"] = _to_stream(_synth(1.0, func(t: float, d: float) -> float:
		var n := _noise()
		lp[0] = lerpf(lp[0], n, 0.25)
		var hp: float = n - lp[0]
		var e := minf(t / 0.05, 1.0) * clampf((d - t) / 0.35, 0.0, 1.0)
		return hp * 0.45 * e))

	ph[0] = 0.0
	streams["jump"] = _to_stream(_synth(0.12, func(t: float, d: float) -> float:
		ph[0] += lerpf(260.0, 520.0, t / d) / RATE
		return sin(TAU * ph[0]) * 0.18 * (1.0 - t / d)))

	lp[0] = 0.0
	streams["land"] = _to_stream(_synth(0.12, func(t: float, d: float) -> float:
		lp[0] = lerpf(lp[0], _noise(), 0.12)
		return (sin(TAU * lerpf(110.0, 50.0, t / d) * t) * 0.4 + lp[0] * 0.8) * (1.0 - t / d)))

	lp[0] = 0.0
	streams["step"] = _to_stream(_synth(0.035, func(t: float, d: float) -> float:
		lp[0] = lerpf(lp[0], _noise(), 0.3)
		return lp[0] * 0.6 * (1.0 - t / d)))

	streams["lever"] = _to_stream(_synth(0.2, func(t: float, _d: float) -> float:
		var click := 0.0
		if t < 0.015 or (t > 0.1 and t < 0.115):
			click = _noise() * 0.6
		return click + sin(TAU * 180.0 * t) * 0.2 * exp(-t * 10.0)))

	lp[0] = 0.0
	ph[0] = 0.0
	streams["door"] = _to_stream(_synth(0.8, func(t: float, d: float) -> float:
		ph[0] += 55.0 / RATE
		lp[0] = lerpf(lp[0], _noise(), 0.05)
		var e := minf(t / 0.08, 1.0) * (1.0 - t / d)
		return (_sq(ph[0]) * 0.12 + lp[0] * 1.2) * e))

	streams["pickup"] = _to_stream(_synth(0.26, func(t: float, _d: float) -> float:
		var f := 660.0 if t < 0.1 else 990.0
		var local_t := fmod(t, 0.1) if t < 0.2 else t - 0.2
		return sin(TAU * f * t) * 0.25 * exp(-local_t * 12.0)))

	streams["heal"] = _to_stream(_synth(0.4, func(t: float, d: float) -> float:
		return sin(TAU * lerpf(440.0, 880.0, t / d) * t) * 0.2 * (1.0 - t / d) + _noise() * 0.05 * (1.0 - t / d)))

	ph[0] = 0.0
	streams["hurt"] = _to_stream(_synth(0.25, func(t: float, d: float) -> float:
		ph[0] += lerpf(420.0, 140.0, t / d) / RATE
		return _sq(ph[0]) * 0.22 * (1.0 - t / d)))

	ph[0] = 0.0
	streams["death"] = _to_stream(_synth(0.9, func(t: float, d: float) -> float:
		ph[0] += lerpf(300.0, 50.0, t / d) / RATE
		return _sq(ph[0]) * 0.2 * (1.0 - t / d)))

	streams["blip"] = _to_stream(_synth(0.04, func(t: float, d: float) -> float:
		return _sq(t * 880.0) * 0.1 * (1.0 - t / d)))

	streams["alert"] = _to_stream(_synth(0.18, func(t: float, d: float) -> float:
		return _sq(t * (700.0 if t < 0.09 else 940.0)) * 0.12 * (1.0 - t / d)))

	ph[0] = 0.0
	streams["grapple"] = _to_stream(_synth(0.25, func(t: float, _d: float) -> float:
		if t < 0.12:
			ph[0] += lerpf(1600.0, 500.0, t / 0.12) / RATE
			return sin(TAU * ph[0]) * 0.18
		var tt := t - 0.12
		return (sin(TAU * 900.0 * tt) + sin(TAU * 1370.0 * tt)) * 0.18 * exp(-tt * 20.0)))

	lp[0] = 0.0
	streams["spark"] = _to_stream(_synth(0.2, func(t: float, d: float) -> float:
		var n := _noise()
		lp[0] = lerpf(lp[0], n, 0.5)
		var crackle := 1.0 if _rng.randf() < 0.3 else 0.2
		return (n - lp[0]) * 0.6 * crackle * (1.0 - t / d)))

	streams["throw"] = _to_stream(_synth(0.15, func(t: float, d: float) -> float:
		return _noise() * 0.18 * sin(PI * t / d)))

	lp[0] = 0.0
	streams["crash"] = _to_stream(_synth(0.6, func(t: float, _d: float) -> float:
		lp[0] = lerpf(lp[0], _noise(), 0.2)
		return (lp[0] * 1.2 + (sin(TAU * 820.0 * t) + sin(TAU * 1190.0 * t)) * 0.15) * exp(-t * 6.0)))

	ph[0] = 0.0
	streams["lift"] = _to_stream(_synth(0.5, func(t: float, d: float) -> float:
		ph[0] += 70.0 / RATE
		return _sq(ph[0]) * 0.1 * sin(PI * t / d) + _noise() * 0.04))

	streams["clunk"] = _to_stream(_synth(0.2, func(t: float, _d: float) -> float:
		return (sin(TAU * 90.0 * t) * 0.5 + _noise() * 0.2) * exp(-t * 18.0)))

	streams["grab"] = _to_stream(_synth(0.06, func(t: float, d: float) -> float:
		return _noise() * 0.3 * (1.0 - t / d)))

	streams["cover"] = _to_stream(_synth(0.1, func(t: float, d: float) -> float:
		return (sin(TAU * 150.0 * t) * 0.3 + _noise() * 0.1) * (1.0 - t / d)))

	streams["menu"] = _to_stream(_synth(0.06, func(t: float, d: float) -> float:
		return sin(TAU * 620.0 * t) * 0.18 * (1.0 - t / d)))

	# Zumbido ambiente das caldeiras (loop de 2 s; frequências fecham o ciclo).
	lp[0] = 0.0
	streams["ambient"] = _to_stream(_synth(2.0, func(t: float, _d: float) -> float:
		lp[0] = lerpf(lp[0], _noise(), 0.02)
		return sin(TAU * 50.0 * t) * 0.25 + sin(TAU * 75.0 * t) * 0.12 + sin(TAU * 0.5 * t) * 0.05 + lp[0] * 0.8), true)
