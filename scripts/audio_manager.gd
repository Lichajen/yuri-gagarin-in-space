extends Node

signal radio_changed(active: bool)

const POOL_SIZE := 8

const OPTION_SELECT := preload("res://assets/audio/sfx_option_select.wav")
const OPTION_HOVER := preload("res://assets/audio/sfx_option_hover.wav")
const RADIO_START := preload("res://assets/audio/sfx_radio_start.ogg")
const RADIO_LOOP := preload("res://assets/audio/sfx_radio_loop.ogg")
const RADIO_END := preload("res://assets/audio/sfx_radio_end.ogg")
const MUSIC := preload("res://assets/audio/music_landscape.mp3")
const INTRO_MUSIC := preload("res://scenes/intro scene/moskau_PLACEHOLDER.ogg")

const RADIO_START_DB := 0.0
const RADIO_LOOP_DB := -10.0
const RADIO_END_DB := 0.0
const MUSIC_DB := -8.0

var _pool: Array[AudioStreamPlayer] = []
var _next_player := 0
var _radio_start_player: AudioStreamPlayer
var _radio_loop_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var intro_music_player: AudioStreamPlayer

func _ready() -> void:
	var music_stream: AudioStreamMP3 = MUSIC.duplicate()
	music_stream.loop = true
	music_player = _make_player(music_stream, MUSIC_DB)
	intro_music_player = _make_player(INTRO_MUSIC.duplicate(), MUSIC_DB)

	for i in POOL_SIZE:
		_pool.append(_make_player(null, 0.0))

	_radio_start_player = _make_player(RADIO_START, RADIO_START_DB)

	var loop_stream: AudioStreamOggVorbis = RADIO_LOOP.duplicate()
	loop_stream.loop = true
	_radio_loop_player = _make_player(loop_stream, RADIO_LOOP_DB)

func _make_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player

func play(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var player := _pool[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

# Start and loop play while a line is typing; radio_end() stops both and plays the end sound.
func radio_begin() -> void:
	_radio_start_player.play()
	_radio_loop_player.play()
	radio_changed.emit(true)

func radio_end() -> void:
	_radio_start_player.stop()
	_radio_loop_player.stop()
	play(RADIO_END, RADIO_END_DB)
	radio_changed.emit(false)

func play_music():
	intro_music_player.stop()
	music_player.play()

func play_intro():
	music_player.stop()
	intro_music_player.play()

func stop_all_music():
	music_player.stop()
	intro_music_player.stop()
