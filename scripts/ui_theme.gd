extends RefCounted
class_name UITheme

# Amber-on-black, after Soyuz cockpit displays.
const AMBER := Color("F5A31A")
const AMBER_DIM := Color(0.96, 0.64, 0.1, 0.6)
const AMBER_PALE := Color("FFD9A0")
const BLACK := Color("050403")
const RED := Color("C1272D")
const RED_LIGHT := Color("FF8C82")

const BUTTON_FONT_SIZE := 20
const BUTTON_MIN_HEIGHT := 44.0
const BUTTON_LINE_SPACING := 6

const _FONT_REGULAR_PATH := "res://assets/fonts/Snowstorm.otf"
const _FONT_LIGHT_PATH := "res://assets/fonts/Snowstorm-Light.otf"

static var _regular: Font
static var _light: Font

static func regular_font() -> Font:
	if _regular == null:
		_regular = load(_FONT_REGULAR_PATH)
	return _regular

static func light_font() -> Font:
	if _light == null:
		_light = load(_FONT_LIGHT_PATH)
	return _light

static func box_stylebox(bg_color: Color, border_color: Color = AMBER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_border_width_all(2)
	sb.border_color = border_color
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb

# Outlined box that fills solid amber with black text on hover.
static func style_dialogue_button(btn: Button) -> void:
	btn.custom_minimum_size = Vector2(0, BUTTON_MIN_HEIGHT)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD

	btn.add_theme_font_override("font", light_font())
	btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	btn.add_theme_constant_override("line_spacing", BUTTON_LINE_SPACING)
	btn.add_theme_color_override("font_color", AMBER)
	btn.add_theme_color_override("font_hover_color", BLACK)
	btn.add_theme_color_override("font_pressed_color", BLACK)
	btn.add_theme_color_override("font_focus_color", BLACK)

	btn.add_theme_stylebox_override("normal", box_stylebox(BLACK))
	btn.add_theme_stylebox_override("hover", box_stylebox(AMBER))
	btn.add_theme_stylebox_override("pressed", box_stylebox(AMBER.lightened(0.2), AMBER.lightened(0.2)))
	btn.add_theme_stylebox_override("focus", box_stylebox(AMBER))

static func fade_in(control: Control, duration: float = 0.22) -> void:
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

static func style_scrollbar(scroll: ScrollContainer) -> void:
	var vbar := scroll.get_v_scroll_bar()
	vbar.custom_minimum_size = Vector2(3, 0)

	var grabber := StyleBoxFlat.new()
	grabber.bg_color = AMBER_DIM
	vbar.add_theme_stylebox_override("grabber", grabber)

	var grabber_hi := StyleBoxFlat.new()
	grabber_hi.bg_color = AMBER
	vbar.add_theme_stylebox_override("grabber_highlight", grabber_hi)
	vbar.add_theme_stylebox_override("grabber_pressed", grabber_hi)

	var empty := StyleBoxEmpty.new()
	vbar.add_theme_stylebox_override("scroll", empty)
	vbar.add_theme_stylebox_override("scroll_focus", empty)

	var blank := ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	vbar.add_theme_icon_override("increment", blank)
	vbar.add_theme_icon_override("increment_highlight", blank)
	vbar.add_theme_icon_override("increment_pressed", blank)
	vbar.add_theme_icon_override("decrement", blank)
	vbar.add_theme_icon_override("decrement_highlight", blank)
	vbar.add_theme_icon_override("decrement_pressed", blank)
