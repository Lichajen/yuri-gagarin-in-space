extends Node

signal game_over

const START_ID := "korolev_attitude"
const END_ID := "END"
const FADE_OUT_TIME := 3.0
const COMMS_HOLD_TIME := 0.5

@export var all_exchanges: Array[Exchange] = []
@export var all_beats: Array[Beat] = []
@export var player: Character

@onready var ui: Control = $Ui
@onready var portrait: PanelContainer = %Portrait
@onready var comms_cell: PanelContainer = %CommsCell
@onready var comms_label: Label = %CommsLabel
@onready var history_log: VBoxContainer = %HistoryLog
@onready var choices: VBoxContainer = %Choices
@onready var speach_player: AudioStreamPlayer = %SpeachPlayer ###

var exchange_lookup: Dictionary = {}
var beat_lookup: Dictionary = {}
var _comms_generation := 0

func _ready() -> void:
	Audio.play_music()
	
	for exchange in all_exchanges:
		exchange_lookup[exchange.id] = exchange
	for beat in all_beats:
		beat_lookup[beat.id] = beat

	_set_comms_active(false)
	Audio.radio_changed.connect(_on_radio_changed)

	history_log.player = player
	history_log.speaker_changed.connect(portrait.show_character)
	choices.option_chosen.connect(goto_node)
	choices.option_audio.connect(new_speach)
	choices.option_selected.connect(history_log.add_choice)

	goto_node(START_ID)

func goto_node(id: String) -> void:
	if id == END_ID:
		_end()
		return

	if beat_lookup.has(id):
		var beat: Beat = beat_lookup[id]
		if beat != null: new_speach(beat.audio) ###
		await history_log.add_entry(beat.narration, beat.speaker, beat.line)
		choices.show_beat(beat)
		return

	if exchange_lookup.has(id):
		var exchange: Exchange = exchange_lookup[id]
		await history_log.add_entry(exchange.narration, exchange.speaker, exchange.line)
		choices.show_options(exchange)
		return

	push_error("No beat or exchange found with id: " + id)

func _end() -> void:
	choices.clear()
	var tween := create_tween()
	tween.tween_property(ui, "modulate:a", 0.0, FADE_OUT_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	game_over.emit()
	

# Keeps the cell lit briefly after the static ends; a new transmission
# in that window cancels the switch-off.
func _on_radio_changed(active: bool) -> void:
	_comms_generation += 1
	if active:
		_set_comms_active(true)
		return
	var generation := _comms_generation
	await get_tree().create_timer(COMMS_HOLD_TIME).timeout
	if generation == _comms_generation:
		_set_comms_active(false)

func _set_comms_active(active: bool) -> void:
	var style: StyleBoxFlat = comms_cell.get_theme_stylebox("panel").duplicate()
	if active:
		style.bg_color = UITheme.RED
		style.border_color = UITheme.RED
		comms_label.add_theme_color_override("font_color", UITheme.AMBER_PALE)
	else:
		style.bg_color = UITheme.BLACK
		style.border_color = UITheme.AMBER_DIM
		comms_label.add_theme_color_override("font_color", UITheme.AMBER_DIM)
	comms_cell.add_theme_stylebox_override("panel", style)

func new_speach(audio: AudioStreamOggVorbis): ###
	speach_player.stop()
	speach_player.stream = audio
	speach_player.play()
