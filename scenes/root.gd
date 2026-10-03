extends Node

@onready var intro_scene : PackedScene = preload("res://scenes/intro scene/intro.tscn")
@onready var lose_scene : PackedScene = preload("res://scenes/main.tscn")

func _ready():
	get_tree().paused = true
