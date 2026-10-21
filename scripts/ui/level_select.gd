class_name LevelSelect
extends Control
## Selector de niveles, armado por código: una tarjeta por nivel con su nombre, las
## mejores estrellas y el mejor dinero. Los niveles que todavía no se desbloquearon
## aparecen con candado (BLOQUEADO) y no se pueden elegir.
## Se abre desde el título (después de cargar una partida) y desde el menú de pausa.
## Lee el progreso de SaveManager.

signal level_chosen(level_number: int)
signal closed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS   # se abre también con el juego en pausa
	add_child(MenuStyle.backdrop())
	var content := MenuStyle.centered_panel(self, 900)
	content.add_child(MenuStyle.title(Lang.t("LEVELS_TITLE")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for level_number in range(1, Levels.count() + 1):
		row.add_child(_card(level_number))
	content.add_child(row)

	var back := MenuStyle.button(Lang.t("SLOTS_BACK"))
	back.pressed.connect(_close)
	content.add_child(back)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


## Tarjeta de un nivel: es un botón con el contenido encima (que no bloquea los clics).
func _card(level_number: int) -> Button:
	var unlocked := SaveManager.is_unlocked(level_number)
	var card := MenuStyle.button("", unlocked)
	card.custom_minimum_size = Vector2(280, 230)
	card.disabled = not unlocked
	card.pressed.connect(_choose.bind(level_number))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	var config := Levels.get_config(level_number)
	box.add_child(_ignore_mouse(MenuStyle.text(Lang.t(config["name"]), 20, Color.WHITE)))
	if not unlocked:
		box.add_child(_ignore_mouse(MenuStyle.text(Lang.t("LEVEL_LOCKED"), 24, Color(0.75, 0.72, 0.8))))
		return card

	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 3:
		var star := TextureRect.new()
		star.texture = Art.STAR if i < SaveManager.get_stars(level_number) else Art.STAR_EMPTY
		star.custom_minimum_size = Vector2(48, 46)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars.add_child(star)
	box.add_child(stars)
	var best := SaveManager.get_best_money(level_number)
	var best_text := Lang.t("LEVEL_BEST") % best if best > 0 else Lang.t("LEVEL_NOT_PLAYED")
	box.add_child(_ignore_mouse(MenuStyle.text(best_text, 18, Color(0.85, 1.0, 0.85))))
	return card


static func _ignore_mouse(control: Control) -> Control:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control


func _choose(level_number: int) -> void:
	level_chosen.emit(level_number)


func _close() -> void:
	closed.emit()
	queue_free()
