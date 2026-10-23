class_name Tutorial
extends Node
## TUTORIAL Y CONSEJOS. Muestra un cartel abajo en el centro con lo que hay que hacer.
## Solo aparece si el jugador nunca ganó ese nivel en la partida actual.
##
## Nivel 1 — modo GUIADO: los pasos van en orden y cada uno espera a que el jugador lo
##   haga (moverse, recoger, preparar, entregar). Mientras tanto el reloj del nivel, la
##   paciencia de los clientes y los eventos están congelados (ver warehouse._update_timers).
## Niveles 2 y 3 — modo CONSEJOS: no frenan nada. Cada consejo aparece una sola vez,
##   la primera vez que pasa algo nuevo (un robot atascado, poco stock, hielo...).
## TAB: en el Nivel 1 salta el tutorial; en los otros cierra el consejo actual.
##
## No cambia las reglas: solo MIRA el estado del juego (warehouse.gd) cada cuadro.
## Cada paso es { "text": clave de lang.gd, "show": cuándo aparece, "done": cuándo
## se va (una condición o segundos) }.

var game: Node   # el nivel (warehouse.gd)
var _steps: Array[Dictionary] = []
var _guided := false
var _current := -1          # paso que se está mostrando (-1 = ninguno)
var _shown := {}            # pasos que ya se mostraron
var _time_shown := 0.0
var _start_pos := Vector2.ZERO
var _panel: PanelContainer
var _title: Label
var _text: Label
var _footer: Label


func setup(warehouse: Node) -> void:
	game = warehouse
	var level: int = game.level_number
	if SaveManager.get_stars(level) > 0:
		return   # nivel ya ganado: sin tutorial
	_guided = level == 1
	_steps = _steps_for_level(level)
	_build_panel()


## True mientras el tutorial guiado del Nivel 1 está en curso (congela el reloj).
func is_guiding() -> bool:
	return _guided and not _steps.is_empty()


func _process(delta: float) -> void:
	if _steps.is_empty():
		return
	if game.phase != "playing":
		_panel.visible = false
		return
	if _start_pos == Vector2.ZERO:
		_start_pos = game.player.global_position
	if _current >= 0:
		_time_shown += delta
		if _is_done(_steps[_current]):
			_hide_current()
	if _current < 0:
		_pick_next()
	_panel.visible = _current >= 0
	if _panel.visible:
		_title.text = Lang.t("TUT_TITLE" if _guided else "TIP_TITLE")
		_text.text = Lang.t(_steps[_current]["text"])
		_footer.text = Lang.t("TUT_SKIP" if _guided else "TIP_CLOSE")


func _unhandled_input(event: InputEvent) -> void:
	if _current < 0 or not event.is_action_pressed("skip_tutorial"):
		return
	get_viewport().set_input_as_handled()
	if _guided:
		_steps.clear()   # salta todo el tutorial: el nivel empieza a correr
		_panel.visible = false
	else:
		_hide_current()


## Guiado: el siguiente paso en orden. Consejos: el primero no mostrado cuya condición se cumple.
func _pick_next() -> void:
	for i in _steps.size():
		if _shown.has(i):
			continue
		if _guided or _steps[i]["show"].call():
			_current = i
			_shown[i] = true
			_time_shown = 0.0
			AudioManager.play("click")
			return
		if _guided:
			return
	if _guided:
		_steps.clear()   # terminó el tutorial guiado
		_panel.visible = false


func _hide_current() -> void:
	_current = -1


func _is_done(step: Dictionary) -> bool:
	var done = step["done"]
	return _time_shown >= done if done is float else done.call()


# --- Pasos de cada nivel --------------------------------------------------------

func _steps_for_level(level: int) -> Array[Dictionary]:
	var player: Player = game.player
	var always := func() -> bool: return true
	var steps: Array[Dictionary] = []
	match level:
		1:
			steps = [
				{"text": "TUT_MOVE", "show": always,
					"done": func() -> bool: return player.global_position.distance_to(_start_pos) > 60.0},
				{"text": "TUT_PICK", "show": always,
					"done": func() -> bool: return player.carrying != ""},
				{"text": "TUT_PACK", "show": always,
					"done": func() -> bool: return player.carrying == "pedido"},
				{"text": "TUT_DELIVER", "show": always,
					"done": func() -> bool: return game.orders_completed > 0},
				{"text": "TUT_DONE", "show": always, "done": 7.0},
			]
		2:
			steps = [
				{"text": "TIP_BOARD", "show": always,
					"done": func() -> bool: return not player.order.is_empty()},
				{"text": "TIP_SHOP",
					"show": func() -> bool: return game.robots.is_empty() and game.money >= game.ROBOT_COST,
					"done": func() -> bool: return not game.robots.is_empty()},
				{"text": "TIP_REPAIR", "show": _any_robot_broken,
					"done": func() -> bool: return not _any_robot_broken.call()},
				{"text": "TIP_BLACKOUT", "show": func() -> bool: return game.event == "blackout", "done": 5.0},
			]
		3:
			steps = [
				{"text": "TIP_ICE", "show": func() -> bool: return player.slippery, "done": 5.0},
				{"text": "TIP_STOCK", "show": _stock_running_low,
					"done": func() -> bool: return not game.shipment.is_empty() or not game.reception_boxes.is_empty()},
				{"text": "TIP_BOXES", "show": func() -> bool: return not game.reception_boxes.is_empty(),
					"done": func() -> bool: return player.carrying == "caja"},
				{"text": "TIP_RESTOCK", "show": func() -> bool: return player.carrying == "caja",
					"done": func() -> bool: return player.carrying != "caja"},
				{"text": "TIP_AI", "show": func() -> bool: return not game.robots.is_empty(), "done": 6.0},
				{"text": "TIP_STORM", "show": func() -> bool: return game.event == "storm", "done": 5.0},
			]
	return steps


func _any_robot_broken() -> bool:
	for robot in game.robots:
		if robot.broken:
			return true
	return false


func _stock_running_low() -> bool:
	for id: String in game.config["products"]:
		if game.get_shelf(id).stock < Station.LOW_STOCK:
			return true
	return false


# --- Cartel ---------------------------------------------------------------------

## Cartel abajo en el centro (encima del texto de la tecla E), por debajo de la
## pantalla de inicio/fin y del menú de pausa.
func _build_panel() -> void:
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.08, 0.15, 0.92)
	box.border_color = Color(1, 0.82, 0.25)
	box.set_border_width_all(3)
	box.set_corner_radius_all(12)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", box)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -330
	_panel.offset_right = 330
	_panel.offset_top = -112
	_panel.offset_bottom = -112
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	_panel.add_child(content)
	_title = _label(15, Color(1, 0.82, 0.25))
	_text = _label(19, Color.WHITE)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer = _label(13, Color(0.7, 0.7, 0.8))
	content.add_child(_title)
	content.add_child(_text)
	content.add_child(_footer)

	var hud: CanvasLayer = game.hud
	hud.add_child(_panel)
	hud.move_child(_panel, hud.get_node("Overlay").get_index())


static func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	return label
