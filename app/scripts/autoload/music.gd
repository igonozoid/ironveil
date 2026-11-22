extends Node
## Trilha sonora procedural (autoload "Music"). Cada faixa é composta por
## regras (progressão de acordes, baixo, pad, arpejo, melodia em frases AABA e
## percussão) e sintetizada nota a nota numa thread, sem nenhum arquivo de
## áudio. As faixas ficam em cache e trocam com crossfade.
##
## Faixas: menu, act1..act5 (um clima por ato), boss, ending.

const RATE := 22050
const FADE := 1.6

const Synth := preload("res://scripts/music_synth.gd")
const TRACKS := Synth.TRACKS

var players: Array[AudioStreamPlayer] = []
var active := 0
var current := ""
var wanted := ""
var cache: Dictionary = {}
var pending: Dictionary = {}   # id -> task id
var results: Dictionary = {}   # id -> PackedByteArray (preenchido pela thread)
var mutex := Mutex.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		players.append(p)
	apply_volumes()


func _setup_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


## Volumes das configurações (0..1).
func apply_volumes() -> void:
	var mv := float(Game.settings.get("music", 0.7))
	var sv := float(Game.settings.get("sfx", 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(mv, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), mv <= 0.01)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sv, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), sv <= 0.01)


## Toca a faixa (com crossfade). Se ainda não foi sintetizada, gera em segundo
## plano e entra quando ficar pronta.
func play(id: String) -> void:
	if not TRACKS.has(id):
		return
	wanted = id
	if id == current:
		return
	if cache.has(id):
		_switch(id)
	else:
		_request(id)


func stop() -> void:
	wanted = ""
	current = ""
	for p in players:
		_fade(p, -80.0, true)


## Gera as faixas que ainda faltam, em segundo plano (chamado no menu).
func preload_all() -> void:
	for id in TRACKS.keys():
		if not cache.has(id):
			_request(id)


func is_ready(id: String) -> bool:
	return cache.has(id)


func _request(id: String) -> void:
	if pending.has(id) or cache.has(id):
		return
	var spec: Dictionary = TRACKS[id]
	pending[id] = WorkerThreadPool.add_task(func(): _render_task(id, spec))


func _render_task(id: String, spec: Dictionary) -> void:
	var data: PackedByteArray = Synth.render(spec)
	mutex.lock()
	results[id] = data
	mutex.unlock()


func _exit_tree() -> void:
	for id in pending.keys():
		WorkerThreadPool.wait_for_task_completion(pending[id])
	pending.clear()


func _process(_delta: float) -> void:
	if pending.is_empty():
		return
	mutex.lock()
	var done := results.keys()
	mutex.unlock()
	for id in done:
		mutex.lock()
		var bytes: PackedByteArray = results[id]
		results.erase(id)
		mutex.unlock()
		WorkerThreadPool.wait_for_task_completion(pending[id])
		pending.erase(id)
		var s := AudioStreamWAV.new()
		s.format = AudioStreamWAV.FORMAT_16_BITS
		s.mix_rate = RATE
		s.stereo = false
		s.data = bytes
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = bytes.size() / 2
		cache[id] = s
		if wanted == id:
			_switch(id)


func _switch(id: String) -> void:
	current = id
	var old := players[active]
	active = 1 - active
	var nw := players[active]
	nw.stream = cache[id]
	nw.volume_db = -40.0
	nw.play()
	_fade(nw, 0.0, false)
	_fade(old, -80.0, true)


func _fade(p: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(p, "volume_db", to_db, FADE)
	if stop_after:
		tw.tween_callback(p.stop)
