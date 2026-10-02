extends VBoxContainer

signal speaker_changed(character: Character)

const SPEAKER_GAP := 8
const LINE_SPACING := 6
const NARRATION_FONT_SIZE := 18
const TEXT_FONT_SIZE := 19
const TAG_FONT_SIZE := 22
const TAG_PADDING := 2.0

const DIM_ALPHA := 0.5
const DIM_TIME := 0.3
const GROW_TIME := 0.3
const HOLD_TIME := 0.6

const TYPE_SPEED := 79.0 # characters per second
const TYPE_SOUND_EVERY := 6 # characters per tick
const TYPE_SOUND_PITCH_VARIATION := 0.08
const TYPE_SOUND_DB := -30.0

var player: Character
var entries: Array[Control] = []

var _scroll: ScrollContainer
var _lock := false
var _last_tick := 0

func _ready() -> void:
	_scroll = get_parent().get_parent() as ScrollContainer
	UITheme.style_scrollbar(_scroll)

# Narration and the spoken line are separate entries. The lock keeps entries
# sequential even when callers don't await.
func add_entry(narration: String, speaker: Character, text: String) -> void:
	await _acquire_lock()
	if narration != "":
		await _commit(_build_entry(narration, null, ""))
	if speaker != null or text != "":
		if speaker != null:
			speaker_changed.emit(speaker)
		await _commit(_build_entry("", speaker, text), speaker)
	_release_lock()

# Echoes the chosen option. Bracketed options are stage directions and are
# shown as narration.
func add_choice(text: String) -> void:
	await _acquire_lock()
	if text.begins_with("[") and text.ends_with("]"):
		await _commit(_build_entry(text.trim_prefix("[").trim_suffix("]"), null, "", true))
	else:
		speaker_changed.emit(player)
		await _commit(_build_entry("", player, text, true), player)
	_release_lock()

func _acquire_lock() -> void:
	while _lock:
		await get_tree().process_frame
	_lock = true

func _release_lock() -> void:
	_lock = false

func _build_entry(narration: String, speaker: Character, text: String, is_choice: bool = false) -> VBoxContainer:
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", SPEAKER_GAP)

	var is_player := is_choice or (speaker != null and speaker.is_player)
	var h_align := HORIZONTAL_ALIGNMENT_RIGHT if is_player else HORIZONTAL_ALIGNMENT_LEFT

	if narration != "":
		entry.add_child(_make_label(narration, NARRATION_FONT_SIZE, UITheme.AMBER_DIM, h_align))

	if speaker != null:
		entry.add_child(_make_name_tag(speaker, is_player))

	if text != "":
		var text_color := UITheme.AMBER
		if is_choice:
			text_color = UITheme.AMBER_PALE
		elif speaker != null and speaker.is_voice:
			text_color = UITheme.RED_LIGHT
		entry.add_child(_make_label(text, TEXT_FONT_SIZE, text_color, h_align))

	return entry

func _make_label(text: String, font_size: int, color: Color, h_align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = h_align
	label.add_theme_constant_override("line_spacing", LINE_SPACING)
	label.add_theme_font_override("font", UITheme.light_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

# Black text on amber, or pale text on red for inner voices.
func _make_name_tag(speaker: Character, align_right: bool) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.size_flags_horizontal = Control.SIZE_SHRINK_END if align_right else Control.SIZE_SHRINK_BEGIN

	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.RED if speaker.is_voice else UITheme.AMBER
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	# All-caps text leaves the font's descent empty below it; pad the top to match.
	style.content_margin_top = TAG_PADDING + UITheme.regular_font().get_descent(TAG_FONT_SIZE)
	style.content_margin_bottom = TAG_PADDING
	tag.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = speaker.display_name.to_upper()
	label.add_theme_font_override("font", UITheme.regular_font())
	label.add_theme_font_size_override("font_size", TAG_FONT_SIZE)
	label.add_theme_color_override("font_color", UITheme.AMBER_PALE if speaker.is_voice else UITheme.BLACK)
	tag.add_child(label)
	return tag

# `speaker` drives the radio static and the voices' typing sound.
func _commit(entry: VBoxContainer, speaker: Character = null) -> void:
	if not entries.is_empty():
		_dim_entry(entries.back())

	var wrapper := Control.new()
	wrapper.clip_contents = true
	wrapper.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(wrapper)
	wrapper.add_child(entry)
	entries.append(wrapper)

	var width: float = await _wait_for_width()
	entry.custom_minimum_size.x = width
	entry.size.x = width

	await get_tree().process_frame

	# Wrapped label height can still change a frame after the width is set.
	var h: float = entry.get_combined_minimum_size().y
	await get_tree().process_frame
	h = maxf(h, entry.get_combined_minimum_size().y)
	entry.size = Vector2(width, h)
	entry.modulate.a = 0.0

	# Shape the full text and only hide glyphs, so wrapping and alignment
	# don't change while typing.
	var typed_labels: Array[Label] = []
	for child in entry.get_children():
		if child is Label:
			child.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
			child.visible_characters = 0
			typed_labels.append(child)

	# Open the entry's slot gradually, keeping the log pinned to the bottom.
	var grow := create_tween().set_parallel()
	grow.tween_method(_set_wrapper_height.bind(wrapper), 0.0, h, GROW_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	grow.tween_property(entry, "modulate:a", 1.0, GROW_TIME)
	await grow.finished

	var radio := speaker != null and speaker.uses_radio
	var typing_sound := speaker != null and speaker.is_voice
	if radio:
		Audio.radio_begin()

	for label in typed_labels:
		_last_tick = 0
		var tween := create_tween()
		tween.tween_method(_reveal.bind(label, typing_sound), 0, label.text.length(), label.text.length() / TYPE_SPEED)
		await tween.finished

	if radio:
		Audio.radio_end()

	await get_tree().create_timer(HOLD_TIME).timeout

func _reveal(count: int, label: Label, typing_sound: bool) -> void:
	label.visible_characters = count
	if typing_sound and count - _last_tick >= TYPE_SOUND_EVERY:
		_last_tick = count
		var pitch := randf_range(1.0 - TYPE_SOUND_PITCH_VARIATION, 1.0 + TYPE_SOUND_PITCH_VARIATION)
		Audio.play(Audio.OPTION_SELECT, TYPE_SOUND_DB, pitch)

# Waits for two matching non-zero widths; the first reading after load
# isn't always final.
func _wait_for_width() -> float:
	var tries := 0
	var last := -1.0
	while tries < 20:
		if size.x > 0.0 and is_equal_approx(size.x, last):
			return size.x
		last = size.x
		await get_tree().process_frame
		tries += 1
	return size.x

func _dim_entry(wrapper: Control) -> void:
	var tween := create_tween()
	tween.tween_property(wrapper, "modulate:a", DIM_ALPHA, DIM_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_wrapper_height(height: float, wrapper: Control) -> void:
	wrapper.custom_minimum_size.y = height
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
