extends PanelContainer

@onready var portrait_rect: TextureRect = $PortraitRect
@onready var initial_label: Label = $InitialLabel

const FADE_TIME := 0.15

var _current: Character
var _tween: Tween
var _frame: StyleBoxFlat

func _ready() -> void:
	_frame = StyleBoxFlat.new()
	_frame.bg_color = UITheme.BLACK
	_frame.set_border_width_all(3)
	_frame.border_color = UITheme.AMBER
	add_theme_stylebox_override("panel", _frame)

	initial_label.add_theme_font_override("font", UITheme.regular_font())
	initial_label.add_theme_font_size_override("font_size", 66)
	initial_label.add_theme_color_override("font_color", UITheme.AMBER)
	visible = false

func show_character(character: Character) -> void:
	if character == null or character == _current:
		return
	_current = character

	if _tween:
		_tween.kill()
	_tween = create_tween()
	if visible:
		_tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	else:
		modulate.a = 0.0
		visible = true
	_tween.tween_callback(_apply.bind(character))
	_tween.tween_property(self, "modulate:a", 1.0, FADE_TIME)

func _apply(character: Character) -> void:
	_frame.border_color = UITheme.RED if character.is_voice else UITheme.AMBER
	portrait_rect.texture = character.portrait
	initial_label.text = character.display_name.substr(0, 1).to_upper()
	initial_label.visible = character.portrait == null
