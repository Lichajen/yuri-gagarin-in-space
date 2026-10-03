extends Node

@onready var intro_scene : PackedScene = preload("res://scenes/intro scene/intro.tscn")
@onready var lose_scene : PackedScene = preload("res://scenes/main.tscn")
@onready var win_scene : PackedScene = preload("res://scenes/win scene/win_screen.tscn")
@onready var fade_to_black_anim := $TransitionLayer/Control/FadeToBlackAnim

var game : Node:
	set(new):
		if game: game.queue_free()
		game = new
		add_child(game)

func _ready():
	start_intro()

func start_intro():
	game = intro_scene.instantiate()
	game.connect("game_lost", _on_intro_lost)
	game.connect("game_won", _on_intro_won)

func start_lose_game():
	game = lose_scene.instantiate()
	game.connect("game_over", _on_game_over)

func start_win_screen():
	game = win_scene.instantiate()
	game.connect("game_over", _on_game_over)

func _on_intro_lost():
	fade_to_black_anim.play("fade_to_black")
	await fade_to_black_anim.animation_finished
	Audio.play_music()
	start_lose_game()
	fade_to_black_anim.play_backwards("fade_to_black")

func _on_intro_won():
	fade_to_black_anim.play("fade_to_black")
	await fade_to_black_anim.animation_finished
	Audio.play_music()
	start_win_screen()
	fade_to_black_anim.play_backwards("fade_to_black")

func _on_game_over():
	fade_to_black_anim.play("fade_to_black")
	await fade_to_black_anim.animation_finished
	await get_tree().create_timer(5.0).timeout
	fade_to_black_anim.play_backwards("fade_to_black")
	start_intro()
