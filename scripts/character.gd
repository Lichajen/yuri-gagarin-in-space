extends Resource
class_name Character

@export var display_name: String = ""
@export var portrait: Texture2D
@export var is_player: bool = false
# Plays radio static around this character's lines.
@export var uses_radio: bool = false
# Inner voices are drawn in red instead of amber.
@export var is_voice: bool = false
