extends RefCounted
## Síntese da trilha procedural (usada pelo autoload Music, roda em thread).

const RATE := 22050

## Escalas (semitons a partir da tônica)
const MINOR := [0, 2, 3, 5, 7, 8, 10]
const DORIAN := [0, 2, 3, 5, 7, 9, 10]
const PHRYGIAN := [0, 1, 3, 5, 7, 8, 10]
const HARM_MINOR := [0, 2, 3, 5, 7, 8, 11]
const MAJOR := [0, 2, 4, 5, 7, 9, 11]

## Receita de cada faixa.
## root: nota MIDI da tônica do baixo; prog: graus da escala por compasso;
## arp/lead: timbres; drums: padrão por 16 avos (k=bumbo, s=caixa, h=chimbal,
## c=metal/bigorna, t=tique de relógio, .=nada); swing: 0..0.3
const TRACKS := {
	"menu": {"bpm": 72, "root": 38, "scale": MINOR, "prog": [0, 5, 3, 4, 0, 5, 6, 4],
		"bass": "pedal", "pad": 0.5, "arp": "musicbox", "arp_rate": 4, "lead": "none",
		"drums": "", "swing": 0.0, "seed": 11},
	"act1": {"bpm": 84, "root": 38, "scale": MINOR, "prog": [0, 0, 5, 6, 0, 0, 3, 4],
		"bass": "ostinato", "pad": 0.32, "arp": "pluck", "arp_rate": 2, "lead": "steam",
		"drums": "k...c...k.k.c...", "swing": 0.0, "seed": 21},
	"act2": {"bpm": 96, "root": 40, "scale": PHRYGIAN, "prog": [0, 1, 0, 6, 0, 1, 3, 1],
		"bass": "walk", "pad": 0.25, "arp": "bouzouki", "arp_rate": 4, "lead": "reed",
		"drums": "k.h.s.hhk.h.s.h.", "swing": 0.18, "seed": 31},
	"act3": {"bpm": 108, "root": 40, "scale": HARM_MINOR, "prog": [0, 5, 3, 4, 0, 5, 1, 4],
		"bass": "ostinato", "pad": 0.3, "arp": "harpsichord", "arp_rate": 4, "lead": "glass",
		"drums": "t.t.t.t.t.t.t.t.", "swing": 0.0, "seed": 41},
	"act4": {"bpm": 66, "root": 33, "scale": PHRYGIAN, "prog": [0, 0, 1, 0, 0, 0, 6, 1],
		"bass": "drone", "pad": 0.45, "arp": "none", "arp_rate": 2, "lead": "steam",
		"drums": "c.......k..c....", "swing": 0.0, "seed": 51},
	"act5": {"bpm": 120, "root": 45, "scale": MINOR, "prog": [0, 5, 2, 6, 0, 5, 3, 4],
		"bass": "drive", "pad": 0.35, "arp": "pluck", "arp_rate": 4, "lead": "brass",
		"drums": "k.h.s.h.k.k.s.hh", "swing": 0.0, "seed": 61},
	"boss": {"bpm": 140, "root": 38, "scale": HARM_MINOR, "prog": [0, 0, 5, 4, 0, 0, 1, 4],
		"bass": "drive", "pad": 0.2, "arp": "harpsichord", "arp_rate": 4, "lead": "brass",
		"drums": "k.hsk.hsk.hsk.ss", "swing": 0.0, "seed": 71},
	"ending": {"bpm": 76, "root": 41, "scale": MAJOR, "prog": [0, 4, 5, 3, 0, 4, 3, 4],
		"bass": "pedal", "pad": 0.45, "arp": "musicbox", "arp_rate": 4, "lead": "glass",
		"drums": "", "swing": 0.0, "seed": 81},
}

# ---------------------------------------------------------------- síntese

static func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


static func _degree(spec: Dictionary, deg: int, octave: int = 0) -> int:
	var sc: Array = spec["scale"]
	var o := octave + floori(float(deg) / sc.size())
	var d := posmod(deg, sc.size())
	return int(spec["root"]) + int(sc[d]) + 12 * o


## Gera a faixa inteira (a progressão duas vezes: 16 compassos 4/4, a segunda
## metade com arpejo invertido, frases novas e virada de caixa) em PCM 16 bits.
static func render(spec: Dictionary) -> PackedByteArray:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(spec["seed"])
	var bpm := float(spec["bpm"])
	var beat := 60.0 / bpm
	var step := beat / 4.0
	var prog: Array = spec["prog"]
	var plen := prog.size()
	var bars := plen * 2
	var total := int(bars * 4 * beat * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var swing := float(spec.get("swing", 0.0))

	for bar in bars:
		var chord_deg: int = prog[bar % plen]
		var second := bar >= plen
		var bar_t := bar * 4.0 * beat
		var tri := [_degree(spec, chord_deg), _degree(spec, chord_deg + 2), _degree(spec, chord_deg + 4)]
		# Pad: acorde sustentado no compasso inteiro
		var pad_amp := float(spec.get("pad", 0.3))
		if pad_amp > 0.0:
			for n in tri:
				_note(buf, bar_t, 4.0 * beat, _hz(n + 12), pad_amp * 0.11, "pad")
		# Baixo
		_bass(buf, spec, bar_t, beat, tri[0] - 12, rng)
		# Arpejo
		var arp := String(spec.get("arp", "none"))
		if arp != "none":
			var rate := int(spec.get("arp_rate", 2))
			var count := 4 * rate
			var notes := [tri[0] + 12, tri[1] + 12, tri[2] + 12, tri[1] + 12, tri[0] + 24, tri[2] + 12]
			if second:
				notes.reverse()
			for i in count:
				var t := bar_t + i * beat / rate
				if i % 2 == 1:
					t += swing * beat / rate
				_note(buf, t, beat / rate * 1.6, _hz(notes[i % notes.size()]), 0.12, arp)
		# Percussão
		var pat := String(spec.get("drums", ""))
		if pat != "":
			for i in 16:
				var ch := pat[i % pat.length()]
				# Virada no último compasso de cada metade
				if (bar % plen) == plen - 1 and i >= 12 and pat.contains("s"):
					ch = "s"
				var t2 := bar_t + i * step + (swing * step if i % 2 == 1 else 0.0)
				match ch:
					"k": _kick(buf, t2)
					"s": _snare(buf, t2, rng)
					"h": _hat(buf, t2, rng, 0.05)
					"c": _clank(buf, t2, rng)
					"t": _hat(buf, t2, rng, 0.035, 0.012)
	# Melodia: frases de 2 compassos, forma AABA (A repete com variação mínima)
	var lead := String(spec.get("lead", "none"))
	if lead != "none":
		var phrase_a := _phrase(spec, rng, prog, 0)
		var phrase_b := _phrase(spec, rng, prog, 4)
		var phrase_c := _phrase(spec, rng, prog, 8)
		var order := [phrase_a, phrase_a, phrase_b, phrase_a, phrase_c, phrase_c, phrase_b, phrase_a]
		for ph in order.size():
			var ph_notes: Array = order[ph]
			for e in ph_notes:
				var bar2: int = ph * 2 + int(e[0])
				if bar2 >= bars:
					continue
				var deg_here: int = prog[bar2 % plen]
				var midi := _degree(spec, deg_here + int(e[2]), 1)
				_note(buf, bar2 * 4.0 * beat + float(e[1]) * beat, float(e[3]) * beat, _hz(midi), 0.16, lead)

	# Normaliza, suaviza a emenda do loop e converte
	var peak := 0.001
	for v in buf:
		peak = maxf(peak, absf(v))
	var gain := 0.85 / peak
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	var edge := int(0.02 * RATE)
	for i in total:
		var v: float = buf[i] * gain
		if i < edge:
			v *= float(i) / edge
		elif i > total - edge:
			v *= float(total - i) / edge
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	return bytes


## Uma frase de 2 compassos: [compasso, tempo (beats), grau relativo ao acorde, duração]
static func _phrase(_spec: Dictionary, rng: RandomNumberGenerator, _prog: Array, _offset: int) -> Array:
	var out: Array = []
	var rhythms := [[1.0, 1.0, 2.0], [0.5, 0.5, 1.0, 2.0], [1.5, 0.5, 1.0, 1.0], [2.0, 1.0, 1.0], [1.0, 0.5, 0.5, 2.0]]
	var deg := rng.randi_range(0, 4)
	for b in 2:
		var r: Array = rhythms[rng.randi() % rhythms.size()]
		var t := 0.0
		for d in r:
			if rng.randf() < 0.15 and t > 0.0:
				t += float(d)
				continue
			deg = clampi(deg + [-2, -1, -1, 0, 1, 1, 2][rng.randi() % 7], -1, 7)
			var target := deg
			# Tempo forte cai em nota do acorde
			if t == 0.0:
				target = [0, 2, 4][rng.randi() % 3]
				deg = target
			out.append([b, t, target, float(d) * 0.95])
			t += float(d)
	return out


static func _bass(buf: PackedFloat32Array, spec: Dictionary, bar_t: float, beat: float, root: int, rng: RandomNumberGenerator) -> void:
	match String(spec.get("bass", "pedal")):
		"pedal":
			_note(buf, bar_t, 4.0 * beat, _hz(root), 0.22, "bass_soft")
		"drone":
			_note(buf, bar_t, 4.0 * beat, _hz(root - 12), 0.28, "drone")
			_note(buf, bar_t, 4.0 * beat, _hz(root - 5), 0.12, "drone")
		"ostinato":
			for i in 8:
				var n := root if i % 4 != 3 else root + 7
				_note(buf, bar_t + i * beat / 2.0, beat / 2.0 * 0.9, _hz(n), 0.24, "bass")
		"walk":
			var steps := [0, 3, 5, 7]
			for i in 4:
				_note(buf, bar_t + i * beat, beat * 0.9, _hz(root + steps[i]), 0.26, "bass")
		_:
			for i in 8:
				var n2 := root if rng.randf() < 0.8 else root + 12
				_note(buf, bar_t + i * beat / 2.0, beat / 2.0 * 0.8, _hz(n2), 0.24, "bass")


## Escreve uma nota no buffer, somando.
static func _note(buf: PackedFloat32Array, t0: float, dur: float, hz: float, amp: float, kind: String) -> void:
	var start := int(t0 * RATE)
	var tail := 0.15
	match kind:
		"pluck", "bouzouki", "harpsichord", "musicbox":
			tail = 0.6
		"pad", "drone":
			tail = 0.4
	var n := int((dur + tail) * RATE)
	var total := buf.size()
	var ph := 0.0
	var ph2 := 0.0
	var inc := hz / RATE
	var lp := 0.0
	for i in n:
		var idx := (start + i) % total
		var t := float(i) / RATE
		var v := 0.0
		var env := 1.0
		match kind:
			"bass", "bass_soft":
				var saw := 2.0 * fposmod(ph, 1.0) - 1.0
				lp += (saw - lp) * (0.08 if kind == "bass" else 0.04)
				v = lp + 0.4 * sin(TAU * ph)
				env = minf(t / 0.01, 1.0) * (1.0 if t < dur else exp(-(t - dur) * 30.0))
			"drone":
				var saw2 := 2.0 * fposmod(ph, 1.0) - 1.0
				lp += (saw2 - lp) * 0.02
				v = lp + 0.3 * sin(TAU * ph2)
				env = minf(t / 0.8, 1.0) * (1.0 if t < dur else exp(-(t - dur) * 6.0))
			"pad":
				v = (absf(fposmod(ph, 1.0) * 4.0 - 2.0) - 1.0) * 0.6 + (absf(fposmod(ph2, 1.0) * 4.0 - 2.0) - 1.0) * 0.6
				env = minf(t / 0.5, 1.0) * (1.0 if t < dur else exp(-(t - dur) * 5.0))
			"pluck":
				v = (2.0 * fposmod(ph, 1.0) - 1.0)
				lp += (v - lp) * clampf(0.5 * exp(-t * 6.0), 0.03, 0.5)
				v = lp
				env = exp(-t * 7.0)
			"bouzouki":
				v = (2.0 * fposmod(ph, 1.0) - 1.0) * 0.6 + (2.0 * fposmod(ph2, 1.0) - 1.0) * 0.6
				env = exp(-t * 9.0)
			"harpsichord":
				v = (1.0 if fposmod(ph, 1.0) < 0.3 else -1.0) * 0.7 + sin(TAU * ph * 2.0) * 0.3
				env = exp(-t * 10.0)
			"musicbox":
				v = sin(TAU * ph) + 0.3 * sin(TAU * ph * 4.0) * exp(-t * 20.0)
				env = exp(-t * 4.0)
			"steam":
				v = sin(TAU * ph + 0.4 * sin(TAU * t * 5.0)) * 0.8 + 0.2 * sin(TAU * ph * 2.0)
				env = minf(t / 0.06, 1.0) * (1.0 if t < dur else exp(-(t - dur) * 12.0))
			"reed":
				var sq := 1.0 if fposmod(ph, 1.0) < 0.5 else -1.0
				lp += (sq - lp) * 0.12
				v = lp * (1.0 + 0.1 * sin(TAU * t * 6.0))
				env = minf(t / 0.04, 1.0) * (1.0 if t < dur else exp(-(t - dur) * 14.0))
			"glass":
				v = sin(TAU * ph) * 0.7 + sin(TAU * ph * 3.0) * 0.2 * exp(-t * 3.0)
				env = minf(t / 0.02, 1.0) * exp(-t * 1.5) * (1.0 if t < dur else exp(-(t - dur) * 8.0))
			"brass":
				var saw3 := 2.0 * fposmod(ph, 1.0) - 1.0
				lp += (saw3 - lp) * clampf(0.04 + t * 0.6, 0.04, 0.25)
				v = lp
				env = minf(t / 0.05, 1.0) * (1.0 if t < dur else exp(-(t - dur) * 10.0))
		buf[idx] += v * env * amp
		ph += inc
		ph2 += inc * 1.006


static func _kick(buf: PackedFloat32Array, t0: float) -> void:
	var start := int(t0 * RATE)
	var n := int(0.25 * RATE)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += (45.0 + 110.0 * exp(-t * 30.0)) / RATE
		buf[(start + i) % buf.size()] += sin(TAU * ph) * exp(-t * 14.0) * 0.55


static func _snare(buf: PackedFloat32Array, t0: float, rng: RandomNumberGenerator) -> void:
	var start := int(t0 * RATE)
	var n := int(0.18 * RATE)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var nz := rng.randf_range(-1.0, 1.0)
		lp += (nz - lp) * 0.5
		buf[(start + i) % buf.size()] += (lp * 0.5 + sin(TAU * 190.0 * t) * 0.3) * exp(-t * 22.0) * 0.4


static func _hat(buf: PackedFloat32Array, t0: float, rng: RandomNumberGenerator, amp: float, length: float = 0.04) -> void:
	var start := int(t0 * RATE)
	var n := int(length * RATE)
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		var nz := rng.randf_range(-1.0, 1.0)
		var hp := nz - prev
		prev = nz
		buf[(start + i) % buf.size()] += hp * exp(-t * 80.0) * amp * 4.0


## Batida metálica (bigorna / cano): parciais inarmônicas.
static func _clank(buf: PackedFloat32Array, t0: float, rng: RandomNumberGenerator) -> void:
	var start := int(t0 * RATE)
	var n := int(0.5 * RATE)
	var base := rng.randf_range(300.0, 420.0)
	var parts := [1.0, 2.76, 5.4, 8.93]
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for k in parts.size():
			v += sin(TAU * base * float(parts[k]) * t) * exp(-t * (8.0 + k * 6.0)) / (k + 1.0)
		buf[(start + i) % buf.size()] += v * 0.22
