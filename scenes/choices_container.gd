extends VBoxContainer

signal option_chosen(next_id: String)
signal option_selected(text: String)

const HOVER_SOUND_COOLDOWN := 0.2
const FADE_OUT_TIME := 0.18

var _last_hover_sound_time := -1000.0

# Guards against double clicks while buttons are still fading out.
var _accepting_input := true

func show_options(exchange: Exchange) -> void:
	await _reset()
	for i in exchange.options.size():
		var option := exchange.options[i]
		_add_button("%d.  %s" % [i + 1, option.text]).pressed.connect(_on_option_pressed.bind(option))

func show_beat(beat: Beat) -> void:
	await _reset()
	_add_button("1.  Continue").pressed.connect(_on_continue_pressed.bind(beat.next_id))

func clear() -> void:
	_accepting_input = false
	_clear_buttons()

func _reset() -> void:
	_clear_buttons()
	await _wait_for_buttons_gone()
	_accepting_input = true

func _add_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	UITheme.style_dialogue_button(btn)
	# Press on mouse-down so the click sound isn't delayed.
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	btn.mouse_entered.connect(_play_hover_sound)
	add_child(btn)
	UITheme.fade_in(btn)
	return btn

func _play_hover_sound() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_hover_sound_time < HOVER_SOUND_COOLDOWN:
		return
	_last_hover_sound_time = now
	Audio.play(Audio.OPTION_HOVER, -28.0)

# Buttons fade out and stay in the layout until gone, so nothing reflows.
func _clear_buttons() -> void:
	for child in get_children():
		if child.has_meta("closing"):
			continue
		child.set_meta("closing", true)
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := child.create_tween()
		tween.tween_property(child, "modulate:a", 0.0, FADE_OUT_TIME)
		tween.tween_callback(child.queue_free)

# Keeps the old and new buttons from showing at the same time.
func _wait_for_buttons_gone() -> void:
	while get_children().any(func(c): return c.has_meta("closing")):
		await get_tree().process_frame

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if not _accepting_input:
		return

	var buttons: Array[Button] = []
	for child in get_children():
		if child is Button and not child.has_meta("closing"):
			buttons.append(child)

	var index: int = event.keycode - KEY_1
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and buttons.size() == 1:
		index = 0

	if index >= 0 and index < buttons.size():
		buttons[index].pressed.emit()
		get_viewport().set_input_as_handled()

func _on_option_pressed(option: DialogueOption) -> void:
	if not _accepting_input:
		return
	_accepting_input = false
	_clear_buttons()

	Audio.play(Audio.OPTION_SELECT, -10.0)
	await _wait_for_buttons_gone()
	option_selected.emit(option.text)
	option_chosen.emit(option.next_id)

func _on_continue_pressed(next_id: String) -> void:
	if not _accepting_input:
		return
	_accepting_input = false
	_clear_buttons()

	Audio.play(Audio.OPTION_SELECT, -14.0)
	await _wait_for_buttons_gone()
	option_chosen.emit(next_id)
