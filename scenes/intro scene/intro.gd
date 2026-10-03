extends Node
signal anim_part_finished
signal game_won
signal game_lost

@export var whole_note_length : float = 3.692

@onready var anim := $CanvasLayer/Control/AnimationPlayer
@onready var rocket := $CanvasLayer/Control/GameScene/VostokPivot
@onready var sky_texture := $BackgroundLayer/GameBackground/Sky
@onready var hud_layer := $HudLayer
@onready var progress_bar := $HudLayer/Hud/ProgressBar

var progress : float = 0.0:
	set(new):
		if new >= 1.0: 
			game_won.emit()
			is_playing_game = false
		progress = clamp(new, 0, 1.0)
		push_strength = push_max_strength * progress + push_min_strength * (1 - progress)
		drift_effect = drift_max_effect * progress + drift_min_effect * (1 - progress)
		sky_texture.modulate = Color(1,1,1) * (1 - progress)
		progress_bar.value = progress
		print(progress)
const speed : float = 0.01
const push_min_strength : float = 10.0
const push_max_strength : float = 250.0
var push_strength : float = push_min_strength
var force_on_rocket : float = -1.0:
	set(new):
		if new == 0: new = -0.01
		force_on_rocket = new
const drift_min_effect : float = 10.0
const drift_max_effect : float = 130.0
var drift_effect : float = drift_min_effect

var rocket_position : float = 0.0:
	set(new):
		rocket_position = new
		if abs(new) > 300: 
			game_lost.emit()
			is_playing_game = false
		rocket.global_position.x = (1280/2) + (1280/2) * rocket_position / 300
		rocket.rotation = (rocket_position / 300) * (PI / 2)

var has_played_intro : bool = false
var is_playing_game : bool = false

func _input(event):
	if has_played_intro:return
	if event is InputEventKey:
		has_played_intro = true
		animate_intro()

func _ready():
	pass

func animate_intro():
	Audio.play_intro()
	$CanvasLayer/Control/GameScene/AnimationPlayer.play("gagarin_anim")
	$CanvasLayer/Control/GameScene/AnimationPlayer.seek(1.0)
	$BackgroundLayer/ExpositionLayer/YellowStar/AnimationPlayer.play("rotate_star")
	_play_anim_part("fade_in", 2 * whole_note_length, whole_note_length)
	await self.anim_part_finished
	_play_anim_part("setting", 0.5 * whole_note_length, whole_note_length)
	await self.anim_part_finished
	_play_anim_part("setting", 0.5 * whole_note_length, 0, true)
	await self.anim_part_finished
	_play_anim_part("enter_gagarin", whole_note_length, 0.5 * whole_note_length)
	await self.anim_part_finished
	_play_anim_part("mission", 4 * whole_note_length, 0)
	await self.anim_part_finished
	_play_anim_part("enter_vostok", 2 * whole_note_length, 0)
	await self.anim_part_finished
	_play_anim_part("prepare_for_launch", 2 * whole_note_length, 0)
	await self.anim_part_finished
	_play_anim_part("speach", 2 * whole_note_length, 0)
	await self.anim_part_finished
	_play_anim_part("exit_nikita", whole_note_length, 0)
	await self.anim_part_finished
	_play_anim_part("liftoff", 2.75 * whole_note_length, 0)
	await self.anim_part_finished
	is_playing_game = true
	hud_layer.show()

func _play_anim_part(part:String, time:float, hold_time:float, backwards : bool = false):
	anim.speed_scale = 1/time
	if !backwards:
		anim.play(part)
	else:
		anim.play_backwards(part)
	await anim.animation_finished
	await get_tree().create_timer(hold_time).timeout
	anim_part_finished.emit()


func _process(delta):
	if ! is_playing_game:return
	progress += speed * delta
	if Input.is_action_just_pressed("ui_left"):
		force_on_rocket -= push_strength
	elif Input.is_action_just_pressed("ui_right"):
		force_on_rocket += push_strength
	force_on_rocket += drift_effect * delta * sign(force_on_rocket)
	rocket_position += force_on_rocket * delta
