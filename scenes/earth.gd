extends TextureRect

@export var spin_rate : float = PI/120

var distance_factor : float = 0.0

func _process(delta):
	rotation += spin_rate * delta
	distance_factor += delta
	scale = (Vector2(1,1) * 2.5) / log(3.0 + pow(distance_factor, 1.5))
