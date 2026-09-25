extends Node

const MUSIC_LOOP := preload("res://assets/audio/neon_bastion_loop.wav")
const SFX_STREAMS := {
	&"ar_fire": preload("res://assets/audio/ar_fire.wav"),
	&"smg_fire": preload("res://assets/audio/smg_fire.wav"),
	&"rocket_fire": preload("res://assets/audio/rocket_fire.wav"),
	&"enemy_fire": preload("res://assets/audio/enemy_fire.wav"),
	&"impact": preload("res://assets/audio/impact.wav"),
	&"player_hurt": preload("res://assets/audio/player_hurt.wav"),
	&"explosion": preload("res://assets/audio/explosion.wav"),
	&"dodge": preload("res://assets/audio/dodge.wav"),
	&"reload": preload("res://assets/audio/reload.wav"),
	&"ui_click": preload("res://assets/audio/ui_click.wav"),
	&"ui_confirm": preload("res://assets/audio/ui_confirm.wav"),
	&"victory": preload("res://assets/audio/victory.wav"),
	&"defeat": preload("res://assets/audio/defeat.wav"),
}
const CUE_GAIN_DB := {
	&"ar_fire": -1.0,
	&"smg_fire": -2.5,
	&"rocket_fire": 0.0,
	&"enemy_fire": 2.0,
	&"impact": -3.0,
	&"player_hurt": 0.0,
	&"explosion": 0.0,
	&"dodge": -2.0,
	&"reload": 8.0,
	&"ui_click": 10.0,
	&"ui_confirm": 8.0,
	&"victory": 8.0,
	&"defeat": 7.0,
}
const SFX_POOL_SIZE := 20

var music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player := 0
var _music_tween: Tween
var last_cue := &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(&"Music", -2.0)
	_ensure_bus(&"SFX", -1.0)
	_build_music_player()
	_build_sfx_pool()
	set_music_context(&"hanger", true)


func set_music_context(context: StringName, immediate: bool = false) -> void:
	if not music_player:
		return
	var target_volume := -8.0
	match context:
		&"battle":
			target_volume = -4.5
		&"debug":
			target_volume = -11.0
		&"result":
			target_volume = -8.0
	if not music_player.playing:
		music_player.play()
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	if immediate:
		music_player.volume_db = target_volume
		return
	_music_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_music_tween.tween_property(music_player, "volume_db", target_volume, 0.45)


func play_weapon(weapon_id: StringName) -> void:
	match weapon_id:
		&"weapon.smg_01":
			play_sfx(&"smg_fire", 0.0, 0.035)
		&"weapon.rocket_launcher_01":
			play_sfx(&"rocket_fire", 0.0, 0.02)
		_:
			play_sfx(&"ar_fire", 0.0, 0.025)


func play_sfx(cue: StringName, volume_offset_db: float = 0.0, pitch_variation: float = 0.0) -> void:
	var stream := SFX_STREAMS.get(cue) as AudioStream
	if not stream or _sfx_players.is_empty():
		return
	last_cue = cue
	var player := _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stop()
	player.stream = stream
	player.volume_db = float(CUE_GAIN_DB.get(cue, 0.0)) + volume_offset_db
	player.pitch_scale = maxf(0.5, 1.0 + randf_range(-pitch_variation, pitch_variation))
	player.play()


func has_cue(cue: StringName) -> bool:
	return SFX_STREAMS.has(cue)


func stop_all() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	if music_player:
		music_player.stop()
		music_player.stream = null
	for player in _sfx_players:
		player.stop()
		player.stream = null


func shutdown_for_test() -> void:
	stop_all()
	if music_player:
		music_player.free()
		music_player = null
	for player in _sfx_players:
		player.free()
	_sfx_players.clear()


func _exit_tree() -> void:
	stop_all()


func _build_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = &"Music"
	music_player.volume_db = -80.0
	var loop_stream := MUSIC_LOOP.duplicate() as AudioStreamWAV
	loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop_stream.loop_begin = 0
	loop_stream.loop_end = loop_stream.mix_rate * 24
	music_player.stream = loop_stream
	add_child(music_player)
	music_player.play()


func _build_sfx_pool() -> void:
	for index in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFX%02d" % index
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)


func _ensure_bus(bus_name: StringName, volume_db: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_volume_db(bus_index, volume_db)
