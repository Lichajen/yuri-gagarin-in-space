extends Node

signal game_over

var is_done : bool = false

func _input(event):
	if is_done : return
	if event is InputEventKey:
		game_over.emit()
		is_done = true
