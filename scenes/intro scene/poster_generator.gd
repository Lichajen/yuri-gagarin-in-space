extends Node2D

@export var prewar_posters : Array[Texture2D]
@export var ww2_posters : Array[Texture2D]
@export var postwar_posters : Array[Texture2D]

var scheduled_posters : Array[Texture2D]

const poster_anim_time : float = 6.0

func _ready():
	assemble_schedule()

func assemble_schedule():
	for posters in [prewar_posters, ww2_posters, postwar_posters]:
		var i = randi_range(0, len(posters) - 1)
		posters.remove_at(i)
		scheduled_posters.append_array(posters)

func next_poster():
	if scheduled_posters.is_empty():return
	var poster : Texture2D = scheduled_posters[0]
	scheduled_posters.remove_at(0)
	var sprite := Sprite2D.new()
	add_child(sprite)
	sprite.position.x = randf_range(200, 1080)
	sprite.modulate.a = 0.0
	sprite.texture = poster
	sprite.scale *= 1.2
	var mv_t := create_tween()
	mv_t.tween_property(sprite, "position", sprite.position + Vector2(0, 720), poster_anim_time)
	var alp_t := create_tween()
	alp_t.set_trans(Tween.TRANS_CUBIC)
	alp_t.set_ease(Tween.EASE_IN_OUT)
	alp_t.tween_property(sprite, "modulate", Color(1,1,1,0.5), poster_anim_time / 2)
	alp_t.tween_property(sprite, "modulate", Color(1,1,1,0), poster_anim_time / 2)
	await mv_t.finished
	sprite.queue_free()
