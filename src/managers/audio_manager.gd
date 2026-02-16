## Module: audio_manager.gd
## Global audio playback service with safe fallbacks for missing assets.

extends Node

const BGM_FADE_SECONDS := 0.5

const MUSIC_TRACKS := {
	"menu_theme": "res://assets/audio/music/menu_theme.wav",
	"garage_theme": "res://assets/audio/music/garage_theme.wav",
	"ege_theme": "res://assets/audio/music/ege_theme.wav",
	"travel_theme": "res://assets/audio/music/travel_theme.wav",
}

const SFX_TRACKS := {
	"train_whistle": "res://assets/audio/sfx/train_whistle.wav",
	"station_arrival": "res://assets/audio/sfx/station_arrival.wav",
	"conductor_hm": "res://assets/audio/sfx/conductor_hm.wav",
	"conductor_aha": "res://assets/audio/sfx/conductor_aha.wav",
	"conductor_oh": "res://assets/audio/sfx/conductor_oh.wav",
	"money_earn": "res://assets/audio/sfx/money_earn.wav",
	"money_spend": "res://assets/audio/sfx/money_spend.wav",
	"passenger_board": "res://assets/audio/sfx/passenger_board.wav",
	"passenger_lost": "res://assets/audio/sfx/passenger_lost.wav",
	"button_click": "res://assets/audio/sfx/button_click.wav",
	"success": "res://assets/audio/sfx/success.wav",
	"error": "res://assets/audio/sfx/error.wav",
	"fuel_refill": "res://assets/audio/sfx/fuel_refill.wav",
	"timer_warning": "res://assets/audio/sfx/timer_warning.wav",
	"event_alert": "res://assets/audio/sfx/event_alert.wav",
	"cargo_deliver": "res://assets/audio/sfx/cargo_deliver.wav",
	"upgrade_done": "res://assets/audio/sfx/upgrade_done.wav",
	"quest_complete": "res://assets/audio/sfx/quest_complete.wav",
}

var _bgm_player_a: AudioStreamPlayer
var _bgm_player_b: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _active_bgm_player: AudioStreamPlayer
var _inactive_bgm_player: AudioStreamPlayer
var _current_bgm_track: String = ""
var _bgm_volume: int = 80
var _sfx_volume: int = 80
var _is_bgm_muted: bool = false
var _is_sfx_muted: bool = false
var _last_warning: String = ""
var _warned_messages: Dictionary = {}
var _event_bus: Node
var _silent_stream: AudioStreamWAV

func _ready() -> void:
	_build_players()
	_event_bus = get_node_or_null("/root/EventBus")
	_apply_settings()
	_bind_event_bus()
	_bind_scene_signal()

func _build_players() -> void:
	_bgm_player_a = AudioStreamPlayer.new()
	_bgm_player_b = AudioStreamPlayer.new()
	_sfx_player = AudioStreamPlayer.new()
	add_child(_bgm_player_a)
	add_child(_bgm_player_b)
	add_child(_sfx_player)
	_active_bgm_player = _bgm_player_a
	_inactive_bgm_player = _bgm_player_b
	_apply_player_volumes()

func _apply_settings() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null or gm.settings_system == null:
		return
	set_bgm_volume(gm.settings_system.get_music_volume())
	set_sfx_volume(gm.settings_system.get_sfx_volume())

func _bind_event_bus() -> void:
	if _event_bus == null:
		return
	if not _event_bus.money_earned.is_connected(_on_money_earned):
		_event_bus.money_earned.connect(_on_money_earned)
	if not _event_bus.money_spent.is_connected(_on_money_spent):
		_event_bus.money_spent.connect(_on_money_spent)
	if not _event_bus.passenger_boarded.is_connected(_on_passenger_boarded):
		_event_bus.passenger_boarded.connect(_on_passenger_boarded)
	if not _event_bus.passenger_lost.is_connected(_on_passenger_lost):
		_event_bus.passenger_lost.connect(_on_passenger_lost)
	if not _event_bus.quest_completed.is_connected(_on_quest_completed):
		_event_bus.quest_completed.connect(_on_quest_completed)
	if not _event_bus.achievement_unlocked.is_connected(_on_achievement_unlocked):
		_event_bus.achievement_unlocked.connect(_on_achievement_unlocked)
	if not _event_bus.random_event_triggered.is_connected(_on_random_event_triggered):
		_event_bus.random_event_triggered.connect(_on_random_event_triggered)
	if not _event_bus.cargo_delivered.is_connected(_on_cargo_delivered):
		_event_bus.cargo_delivered.connect(_on_cargo_delivered)
	if not _event_bus.trip_started.is_connected(_on_trip_started):
		_event_bus.trip_started.connect(_on_trip_started)
	if not _event_bus.station_arrived.is_connected(_on_station_arrived):
		_event_bus.station_arrived.connect(_on_station_arrived)
	if not _event_bus.fuel_low.is_connected(_on_fuel_low):
		_event_bus.fuel_low.connect(_on_fuel_low)
	if not _event_bus.fuel_empty.is_connected(_on_fuel_empty):
		_event_bus.fuel_empty.connect(_on_fuel_empty)
	if not _event_bus.shop_opened.is_connected(_on_shop_opened):
		_event_bus.shop_opened.connect(_on_shop_opened)
	if not _event_bus.shop_upgraded.is_connected(_on_shop_upgraded):
		_event_bus.shop_upgraded.connect(_on_shop_upgraded)
	if not _event_bus.locomotive_upgraded.is_connected(_on_locomotive_upgraded):
		_event_bus.locomotive_upgraded.connect(_on_locomotive_upgraded)
	if not _event_bus.wagon_upgraded.is_connected(_on_wagon_upgraded):
		_event_bus.wagon_upgraded.connect(_on_wagon_upgraded)

func _on_scene_changed(scene: Node) -> void:
	if scene == null:
		return
	var path: String = scene.scene_file_path
	if path.contains("main_menu"):
		play_bgm("menu_theme")
	elif path.contains("garage_scene") or path.contains("summary_scene"):
		play_bgm("garage_theme")
	elif path.contains("travel_scene"):
		play_bgm("travel_theme")
	elif path.contains("station_scene") or path.contains("map_scene"):
		play_bgm("ege_theme")

func _on_scene_changed_no_args() -> void:
	_on_scene_changed(get_tree().current_scene)

func _bind_scene_signal() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if tree.has_signal("current_scene_changed"):
		var cb := Callable(self, "_on_scene_changed")
		if not tree.is_connected("current_scene_changed", cb):
			tree.connect("current_scene_changed", cb)
		return
	if tree.has_signal("scene_changed"):
		var cb2 := Callable(self, "_on_scene_changed_no_args")
		if not tree.is_connected("scene_changed", cb2):
			tree.connect("scene_changed", cb2)

func play_bgm(track_name: String) -> void:
	if track_name == _current_bgm_track:
		return
	var path: String = str(MUSIC_TRACKS.get(track_name, ""))
	if path.is_empty():
		_emit_warning("AudioManager: unknown BGM track '%s'" % track_name)
		return
	var stream: AudioStream = _load_audio(path)
	if stream == null:
		return
	_current_bgm_track = track_name

	_inactive_bgm_player.stream = stream
	_inactive_bgm_player.volume_db = _muted_db(true)
	_inactive_bgm_player.play()
	_crossfade_players()

func stop_bgm() -> void:
	_current_bgm_track = ""
	_active_bgm_player.stop()
	_inactive_bgm_player.stop()

func play_sfx(sfx_name: String) -> void:
	if _is_sfx_muted:
		return
	var path: String = str(SFX_TRACKS.get(sfx_name, ""))
	if path.is_empty():
		_emit_warning("AudioManager: unknown SFX '%s'" % sfx_name)
		return
	var stream: AudioStream = _load_audio(path)
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()

func set_bgm_volume(value: int) -> void:
	_bgm_volume = clampi(value, 0, 100)
	_apply_player_volumes()

func get_bgm_volume() -> int:
	return _bgm_volume

func set_sfx_volume(value: int) -> void:
	_sfx_volume = clampi(value, 0, 100)
	_apply_player_volumes()

func get_sfx_volume() -> int:
	return _sfx_volume

func set_bgm_muted(value: bool) -> void:
	_is_bgm_muted = value
	_apply_player_volumes()

func is_bgm_muted() -> bool:
	return _is_bgm_muted

func set_sfx_muted(value: bool) -> void:
	_is_sfx_muted = value
	_apply_player_volumes()

func is_sfx_muted() -> bool:
	return _is_sfx_muted

func get_last_warning() -> String:
	return _last_warning

func _crossfade_players() -> void:
	var fade_in_db: float = _volume_to_db(_bgm_volume)
	var fade_out_db: float = _muted_db(true)
	var tween: Tween = create_tween()
	tween.tween_property(_active_bgm_player, "volume_db", fade_out_db, BGM_FADE_SECONDS)
	tween.parallel().tween_property(_inactive_bgm_player, "volume_db", fade_in_db, BGM_FADE_SECONDS)
	tween.finished.connect(func() -> void:
		_active_bgm_player.stop()
		var old_active := _active_bgm_player
		_active_bgm_player = _inactive_bgm_player
		_inactive_bgm_player = old_active
	)

func _apply_player_volumes() -> void:
	var bgm_db: float = _muted_db(_is_bgm_muted) if _is_bgm_muted else _volume_to_db(_bgm_volume)
	var sfx_db: float = _muted_db(_is_sfx_muted) if _is_sfx_muted else _volume_to_db(_sfx_volume)
	if _bgm_player_a:
		_bgm_player_a.volume_db = bgm_db
	if _bgm_player_b:
		_bgm_player_b.volume_db = bgm_db
	if _sfx_player:
		_sfx_player.volume_db = sfx_db

func _load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path, "AudioStream"):
		var stream: Resource = ResourceLoader.load(path)
		if stream is AudioStream:
			return stream
	if FileAccess.file_exists(path):
		# Keep runtime resilient when placeholder audio files exist without import artifacts.
		return _get_silent_stream()
	return _get_silent_stream()

func _get_silent_stream() -> AudioStreamWAV:
	if _silent_stream != null:
		return _silent_stream
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 44100
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.data = PackedByteArray([0, 0, 0, 0])
	_silent_stream = stream
	return _silent_stream

func _emit_warning(message: String) -> void:
	_last_warning = message
	if _warned_messages.has(message):
		return
	_warned_messages[message] = true
	push_warning(message)

func _volume_to_db(value: int) -> float:
	if value <= 0:
		return _muted_db(true)
	return linear_to_db(float(value) / 100.0)

func _muted_db(_value: bool) -> float:
	return -80.0

func _on_money_earned(_amount: int, _source: String) -> void:
	play_sfx("money_earn")

func _on_money_spent(_amount: int, _reason: String) -> void:
	play_sfx("money_spend")

func _on_passenger_boarded(_passenger_data: Dictionary, _wagon_id: int) -> void:
	play_sfx("passenger_board")

func _on_passenger_lost(_passenger_data: Dictionary, _station_id: String) -> void:
	play_sfx("passenger_lost")

func _on_quest_completed(_quest_id: String) -> void:
	play_sfx("quest_complete")

func _on_achievement_unlocked(_achievement_data: Dictionary) -> void:
	play_sfx("success")

func _on_random_event_triggered(_event_data: Dictionary) -> void:
	play_sfx("event_alert")
	_play_conductor_reaction("hm")

func _on_cargo_delivered(_cargo_data: Dictionary, _station_id: String) -> void:
	play_sfx("cargo_deliver")

func _on_trip_started(_route_data: Dictionary) -> void:
	play_sfx("train_whistle")

func _on_station_arrived(station_id: String) -> void:
	play_station_announcement(station_id)

func _on_fuel_low(_locomotive_id: String, _percentage: float) -> void:
	play_sfx("timer_warning")

func _on_fuel_empty(_locomotive_id: String) -> void:
	play_sfx("error")

func _on_shop_opened(_station_id: String, _shop_type: int) -> void:
	_play_conductor_reaction("aha")

func _on_shop_upgraded(_station_id: String, _shop_type: int, _level: int) -> void:
	play_sfx("upgrade_done")

func _on_locomotive_upgraded(_loco_id: String, _upgrade_type: int, _level: int) -> void:
	play_sfx("upgrade_done")

func _on_wagon_upgraded(_wagon_id: String, _upgrade_type: int, _level: int) -> void:
	play_sfx("upgrade_done")

func play_station_announcement(_station_id: String) -> void:
	# MVP fallback announcement cue. Station-specific spoken assets can replace this later.
	play_sfx("station_arrival")

func _play_conductor_reaction(tag: String) -> void:
	match tag:
		"aha":
			play_sfx("conductor_aha")
		"oh":
			play_sfx("conductor_oh")
		_:
			play_sfx("conductor_hm")
