class_name SlotMenu
extends Control
## Menú de las ranuras de guardado (estilo Vice City), armado por código.
##   Mode.LOAD: desde el título, elegir qué partida cargar (las vacías no se pueden elegir).
##   Mode.SAVE: al ganar un nivel, "¿Guardar partida?". Si la ranura ya tiene una
##              partida, pide confirmación antes de sobreescribirla.
## Usa SaveManager para leer y escribir. Se crea con SlotMenu.new(modo) y se
## agrega como hijo de la pantalla; avisa con las señales y se borra solo.

enum Mode { LOAD, SAVE }

## LOAD: se cargó la partida de esa ranura.
signal loaded(slot: int)
## Se cerró sin cargar (LOAD) o se terminó de guardar / se eligió no guardar (SAVE).
signal closed

var mode: Mode
var _hint: Label
var _slots: VBoxContainer
var _confirm: VBoxContainer
var _confirm_label: Label
var _bottom_button: Button
var _pending_slot := 0   # ranura que espera confirmación para sobreescribir


func _init(menu_mode: Mode) -> void:
	mode = menu_mode


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS   # funciona también con el juego en pausa
	add_child(MenuStyle.backdrop())
	var content := MenuStyle.centered_panel(self, 640)
	content.add_child(MenuStyle.title(Lang.t("SLOTS_LOAD_TITLE" if mode == Mode.LOAD else "SLOTS_SAVE_TITLE")))
	_hint = MenuStyle.text("")
	content.add_child(_hint)

	_slots = VBoxContainer.new()
	_slots.add_theme_constant_override("separation", 8)
	content.add_child(_slots)

	# confirmación para sobreescribir (oculta hasta que haga falta)
	_confirm = VBoxContainer.new()
	_confirm.visible = false
	_confirm.add_theme_constant_override("separation", 10)
	_confirm_label = MenuStyle.text("", 22, MenuStyle.TITLE_COLOR)
	_confirm.add_child(_confirm_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var yes := MenuStyle.button(Lang.t("SLOTS_YES"), true)
	var no := MenuStyle.button(Lang.t("SLOTS_NO"))
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(_confirm_overwrite)
	no.pressed.connect(_cancel_overwrite)
	row.add_child(yes)
	row.add_child(no)
	_confirm.add_child(row)
	content.add_child(_confirm)

	_bottom_button = MenuStyle.button("")
	_bottom_button.pressed.connect(_close)
	content.add_child(_bottom_button)

	if mode == Mode.LOAD:
		_hint.text = Lang.t("SLOTS_LOAD_HINT")
		_bottom_button.text = Lang.t("SLOTS_BACK")
	else:
		_hint.text = Lang.t("SLOTS_AUTOSAVED") % SaveManager.current_slot if SaveManager.current_slot > 0 \
				else Lang.t("SLOTS_SAVE_HINT")
		_bottom_button.text = Lang.t("SLOTS_SKIP")
	_rebuild_slots()


## ESC: cancela la confirmación, o cierra el menú.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _confirm.visible:
			_cancel_overwrite()
		else:
			_close()
		get_viewport().set_input_as_handled()


func _rebuild_slots() -> void:
	for child in _slots.get_children():
		child.queue_free()
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		var data := SaveManager.read_slot(slot)
		var button := MenuStyle.button(_slot_text(slot, data), false, 18)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = mode == Mode.LOAD and data.is_empty()
		button.pressed.connect(_on_slot_pressed.bind(slot, data.is_empty()))
		_slots.add_child(button)


## "RANURA 2 · NIVEL 3 · 5/9 ESTRELLAS · 21/10/2026 18:45" o "RANURA 2 — VACÍA"
func _slot_text(slot: int, data: Dictionary) -> String:
	if data.is_empty():
		return Lang.t("SLOT_EMPTY") % slot
	var stars := 0
	for value: int in data["stars"]:
		stars += value
	var text: String = Lang.t("SLOT_INFO") % [slot, data["unlocked"], stars, Levels.count() * 3, _format_date(data["saved_at"])]
	if slot == SaveManager.current_slot:
		text += "  " + Lang.t("SLOT_IN_USE")
	return text


## Fecha y hora local del guardado: "21/10/2026 18:45".
static func _format_date(unix_time: int) -> String:
	if unix_time <= 0:
		return "--"
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)   # minutos respecto de UTC
	var d := Time.get_datetime_dict_from_unix_time(unix_time + bias * 60)
	return "%02d/%02d/%d %02d:%02d" % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]


func _on_slot_pressed(slot: int, empty: bool) -> void:
	if mode == Mode.LOAD:
		if SaveManager.load_slot(slot):
			loaded.emit(slot)
			queue_free()
		else:
			_hint.text = Lang.t("SLOTS_LOAD_ERROR")
		return
	if empty:
		_save(slot)
	else:
		_pending_slot = slot
		_confirm_label.text = Lang.t("SLOTS_CONFIRM") % slot
		_slots.visible = false
		_bottom_button.visible = false
		_confirm.visible = true


func _confirm_overwrite() -> void:
	_cancel_overwrite()
	_save(_pending_slot)


func _cancel_overwrite() -> void:
	_confirm.visible = false
	_slots.visible = true
	_bottom_button.visible = true


func _save(slot: int) -> void:
	if not SaveManager.save_to_slot(slot):
		_hint.text = Lang.t("SLOTS_SAVE_ERROR")
		return
	_hint.text = Lang.t("SLOTS_SAVED") % slot
	_hint.add_theme_color_override("font_color", Color(0.45, 1.0, 0.5))
	_bottom_button.text = Lang.t("SLOTS_CONTINUE")
	_rebuild_slots()


func _close() -> void:
	closed.emit()
	queue_free()
