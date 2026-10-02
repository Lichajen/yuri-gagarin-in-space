# Yuri (Gagarin) in Space

Short dialogue game in Godot 4.6, about three minutes. You play Yuri Gagarin on
Vostok 1, talking to Korolev on the radio and to the voices in his head.

## Where things are

- `scenes/main.tscn`, `main.gd`: the scene, and the code that steps through the dialogue
- `scenes/history_log.gd`: scrolling log and typewriter effect
- `scenes/choices_container.gd`: option buttons
- `scenes/portrait_box.gd`: portrait box
- `scripts/`: resource classes, the `Audio` autoload, `UITheme`
- `data/`: one `.tres` per dialogue node, named after its id
- `data/characters/`: the speakers

## Dialogue

Nodes refer to each other by id. A Beat is a line followed by Continue. An
Exchange gives the player options, each with its own `next_id`. `END` fades to
black. The first node is `START_ID` in `main.gd`.

Options written as `[like this]` are shown as narration.

To add a node, create the resource in `data/`, add it to `all_beats` or
`all_exchanges` on `Main`, and point another node's `next_id` at it.

## Characters

- `portrait`: shown in the portrait box (the first letter if empty)
- `is_player`: lines are right-aligned; the player is set on `Main`
- `uses_radio`: static plays during their lines
- `is_voice`: red name tag, text and portrait frame
