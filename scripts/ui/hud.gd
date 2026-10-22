extends CanvasLayer
## HUD del juego (escena scenes/ui/hud.tscn, la usan los 3 niveles): reloj y vidas,
## panel del pedido con su barra de paciencia, proveedor, tienda, tablero de pedidos,
## dinero, mensajes grandes y la pantalla de inicio / fin de nivel con estrellas.
## Solo MUESTRA el estado del juego y avisa de los clics; las reglas están en
## warehouse.gd (`game`). Se actualiza cada frame en _process().
## El HUD sigue funcionando con el juego en PAUSA (process_mode = Always en hud.tscn).

const COLOR_OK := Color(0.35, 0.9, 0.4)
const COLOR_WARN := Color(1.0, 0.8, 0.2)
const COLOR_DANGER := Color(1.0, 0.3, 0.3)

## Se cerró el menú "¿Guardar partida?" de fin de nivel (guardó o no): warehouse.gd sigue.
signal save_menu_closed

@onready var game: Node = get_parent()

# Arriba
@onready var timer_label: Label = $TopCenter/Row/TimerLabel
@onready var hearts: Array[TextureRect] = [$TopCenter/Row/Heart1, $TopCenter/Row/Heart2, $TopCenter/Row/Heart3]
@onready var money_label: Label = $MoneyLabel
@onready var level_label: Label = $LevelLabel
@onready var language_button: Button = $LanguageButton
# Columna izquierda: pedido del jugador y proveedor
@onready var order_tab: HoverTab = $LeftColumn/OrderTab
@onready var order_time_bar: ProgressBar = $LeftColumn/OrderTimeBar
@onready var urgent_label: Label = $LeftColumn/OrderPanel/Content/UrgentLabel
@onready var order_label: Label = $LeftColumn/OrderPanel/Content/OrderLabel
@onready var status_label: Label = $LeftColumn/OrderPanel/Content/StatusLabel
@onready var steps_label: Label = $LeftColumn/OrderPanel/Content/StepsLabel
@onready var supplier_tab: Button = $LeftColumn/SupplierTab
@onready var supplier_title: Label = $LeftColumn/SupplierPanel/Content/Title
@onready var supplier_rows: VBoxContainer = $LeftColumn/SupplierPanel/Content/Rows
@onready var supplier_info: Label = $LeftColumn/SupplierPanel/Content/Info
@onready var supplier_button: Button = $LeftColumn/SupplierPanel/Content/OrderButton
# Columna derecha (Niveles 2 y 3): tienda y tablero de pedidos
@onready var right_column: Control = $RightColumn
@onready var shop_tab: Button = $RightColumn/ShopTab
@onready var shop_title: Label = $RightColumn/ShopPanel/Content/Title
@onready var buy_robot_button: Button = $RightColumn/ShopPanel/Content/BuyRobotButton
@onready var shop_robot_info: Label = $RightColumn/ShopPanel/Content/RobotInfo
@onready var shop_fast_robot: Button = $RightColumn/ShopPanel/Content/FastRobotButton
@onready var shop_conveyor: Button = $RightColumn/ShopPanel/Content/ConveyorButton
@onready var shop_ai_note: Label = $RightColumn/ShopPanel/Content/AINote
@onready var board_tab: Button = $RightColumn/BoardTab
@onready var board_title: Label = $RightColumn/OrderBoard/Content/Title
@onready var promo_label: Label = $RightColumn/OrderBoard/Content/PromoLabel
@onready var board_rows: VBoxContainer = $RightColumn/OrderBoard/Content/Rows
# Abajo y centro
@onready var carry_label: Label = $BottomCenter/CarryLabel
@onready var hint_label: Label = $BottomCenter/HintLabel
@onready var message_label: Label = $MessageLabel
@onready var event_label: Label = $EventLabel
@onready var combo_label: Label = $ComboLabel
@onready var weather_overlay: ColorRect = $WeatherOverlay
@onready var queue_label: Label = $LeftColumn/QueueLabel
# Pantalla de inicio / fin de nivel
@onready var overlay: Control = $Overlay
@onready var overlay_title: Label = $Overlay/Center/Content/Title
@onready var overlay_stars: Control = $Overlay/Center/Content/Stars
@onready var stars: Array[TextureRect] = [$Overlay/Center/Content/Stars/Star1,
		$Overlay/Center/Content/Stars/Star2, $Overlay/Center/Content/Stars/Star3]
@onready var overlay_label: Label = $Overlay/Center/Content/Label
# Pausa
@onready var pause_button: Button = $PauseButton
@onready var pause_menu: Control = $PauseMenu
@onready var pause_title: Label = $PauseMenu/Center/Panel/Content/Title
@onready var resume_button: Button = $PauseMenu/Center/Panel/Content/ResumeButton
@onready var restart_button: Button = $PauseMenu/Center/Panel/Content/RestartButton
@onready var menu_button: Button = $PauseMenu/Center/Panel/Content/MenuButton
@onready var levels_button: Button = $PauseMenu/Center/Panel/Content/LevelsButton

var _message_tween: Tween
var _board_rows: Array[Dictionary] = []   # [{ "order", "label", "bar", "buttons": [{ "worker", "button" }] }]
var _board_signature := ""
var _supplier_rows := {}   # { id: { "label", "minus", "qty", "plus" } }
var _bar_fills := {}       # ProgressBar -> StyleBoxFlat de su relleno (para cambiarle el color)


func _ready() -> void:
	buy_robot_button.pressed.connect(game.buy_robot)
	supplier_button.pressed.connect(game.order_supplies)
	language_button.pressed.connect(game.toggle_language)
	pause_button.pressed.connect(toggle_pause)
	resume_button.pressed.connect(toggle_pause)
	restart_button.pressed.connect(_restart_level)
	menu_button.pressed.connect(_go_to_menu)
	levels_button.pressed.connect(_open_level_select)
	message_label.modulate.a = 0.0
	_style_time_bar(order_time_bar)


## Lo llama warehouse.gd en su _ready(), cuando ya cargó la configuración del nivel.
func setup() -> void:
	var config: Dictionary = game.config
	var has_board: bool = config["board"]
	right_column.visible = has_board
	shop_tab.visible = config["robots"]
	supplier_tab.visible = config["supplier"]
	if config["supplier"]:
		_build_supplier()


func _process(_delta: float) -> void:
	if game.config.is_empty():
		return
	_update()


# --- Lo que llama warehouse.gd ------------------------------------------------

func show_message(text: String, color := Color.WHITE, duration := 1.6) -> void:
	message_label.text = text
	message_label.modulate = color
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.6)


## Pantalla oscura de inicio o fin de nivel (el texto lo pone _update_overlay()).
func show_overlay() -> void:
	overlay.visible = true


func hide_overlay() -> void:
	overlay.visible = false


func is_overlay_visible() -> bool:
	return overlay.visible


# --- Pausa --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif pause_menu.visible and event.is_action_pressed("toggle_language"):
		game.toggle_language()   # con el juego en pausa el nivel no recibe teclas


## ESC / P o el botón: congela el nivel (jugador, robots, relojes) y muestra el menú.
func toggle_pause() -> void:
	if game.phase != "playing" and not pause_menu.visible:
		return
	var paused := not pause_menu.visible
	pause_menu.visible = paused
	get_tree().paused = paused
	AudioManager.set_paused(paused)


func _restart_level() -> void:
	get_tree().paused = false
	AudioManager.set_paused(false)
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().paused = false
	AudioManager.set_paused(false)
	get_tree().change_scene_to_file(Levels.TITLE_SCENE)


## Desde la pausa: volver a cualquier nivel ya desbloqueado.
func _open_level_select() -> void:
	var select := LevelSelect.new()
	select.level_chosen.connect(_change_level)
	add_child(select)


func _change_level(level_number: int) -> void:
	get_tree().paused = false
	AudioManager.set_paused(false)
	get_tree().change_scene_to_file(Levels.SCENES[level_number - 1])


# --- Guardar al ganar un nivel ------------------------------------------------

func open_save_menu() -> void:
	hide_overlay()
	var menu := SlotMenu.new(SlotMenu.Mode.SAVE)
	menu.closed.connect(save_menu_closed.emit)
	add_child(menu)


# --- Actualización de textos ---------------------------------------------------

func _update() -> void:
	var config: Dictionary = game.config
	money_label.text = Lang.t("MONEY") % game.money
	language_button.text = Lang.t("LANG_BUTTON")
	pause_button.text = Lang.t("PAUSE_BUTTON")
	pause_button.visible = game.phase == "playing"
	if pause_menu.visible:
		pause_title.text = Lang.t("PAUSE_TITLE")
		resume_button.text = Lang.t("PAUSE_RESUME")
		restart_button.text = Lang.t("PAUSE_RESTART")
		menu_button.text = Lang.t("PAUSE_MENU")
		levels_button.text = Lang.t("PAUSE_LEVELS")
	var goals: Array = config["stars"]
	level_label.text = Lang.t(config["name"]) + "\n" + Lang.t("LEVEL_GOAL") % [goals[0], goals[1], goals[2]]

	# reloj del nivel (rojo en los últimos 30 s) y vidas
	var seconds := ceili(game.time_left)
	timer_label.text = "%d:%02d" % [floori(seconds / 60.0), seconds % 60]
	timer_label.add_theme_color_override("font_color", COLOR_DANGER if game.time_left <= 30.0 else Color.WHITE)
	for i in hearts.size():
		hearts[i].texture = Art.HEART if i < game.hearts else Art.HEART_EMPTY

	if right_column.visible:
		_update_shop()
		_update_board()
		_update_tabs()
	if supplier_tab.visible:
		_update_supplier()
	if overlay.visible:
		_update_overlay()

	_update_order_panel()
	_update_queue()
	_update_carry_and_hint()
	_update_event_and_combo()


## Evento sorpresa activo con su tiempo, combo actual y efecto de tormenta.
func _update_event_and_combo() -> void:
	if game.event != "":
		event_label.text = Lang.t("EVENT_" + game.event) % ceili(game.event_left)
		event_label.modulate.a = 0.6 + 0.4 * absf(sin(Time.get_ticks_msec() / 250.0))
	else:
		event_label.text = ""
	var multiplier: float = game.combo_multiplier()
	if multiplier > 1.0:
		combo_label.text = Lang.t("COMBO") % game.combo_text(multiplier)
		var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() / 120.0)
		combo_label.scale = Vector2(pulse, pulse)
	else:
		combo_label.text = ""
	var storm_alpha := 0.35 if game.event == "storm" else 0.0
	weather_overlay.color.a = lerpf(weather_overlay.color.a, storm_alpha, 0.05)


## Nivel 1 (sin tablero): pedidos que esperan su turno, con su tiempo.
func _update_queue() -> void:
	if right_column.visible:
		queue_label.visible = false
		return
	var waiting := []
	for order in game.orders:
		if order["owner"] == null:
			var text := "#%03d (%ds)" % [order["number"], ceili(order["time_left"])]
			if order["urgent"]:
				text += " " + Lang.t("URGENT")
			waiting.append(text)
	queue_label.visible = not waiting.is_empty()
	queue_label.text = Lang.t("QUEUE") % ", ".join(waiting)


## Pantalla de inicio (intro), nivel ganado (estrellas), perdido o juego completado.
func _update_overlay() -> void:
	var config: Dictionary = game.config
	overlay_title.text = Lang.t(config["name"])
	overlay_stars.visible = game.phase == "won"
	for i in stars.size():
		stars[i].texture = Art.STAR if i < game.stars else Art.STAR_EMPTY
	match game.phase:
		"intro":
			overlay_label.text = Lang.t(config["intro"]) + "\n\n" + Lang.t("CONTROLS") + "\n\n" + Lang.t("PRESS_ENTER_START")
		"won":
			overlay_label.text = Lang.t("LEVEL_WON") % [game.orders_completed, game.money]
		"lost":
			match game.lose_reason:
				"hearts":
					overlay_label.text = Lang.t("LEVEL_FAILED_HEARTS")
				"bankrupt":
					overlay_label.text = Lang.t("GAME_OVER") % game.orders_completed
				_:
					overlay_label.text = Lang.t("LEVEL_FAILED_TIME") % [config["stars"][0], game.money]
		"game_complete":
			overlay_title.text = "GOMITAS EXPRESS"
			overlay_label.text = Lang.t("GAME_COMPLETE") % [SaveManager.get_stars(1),
					SaveManager.get_stars(2), SaveManager.get_stars(3)]


## Abajo: qué lleva el jugador y qué hace la tecla E en la estación cercana.
func _update_carry_and_hint() -> void:
	var player: Player = game.player
	match player.carrying:
		"productos":
			var carried := []
			for id: String in player.items:
				carried.append(Products.describe(id, player.items[id]))
			carry_label.text = Lang.t("CARRYING") % ", ".join(carried)
		"pedido":
			carry_label.text = Lang.t("CARRYING") % (Lang.t("CARRYING_ORDER") % player.order.get("number", 0))
		"caja":
			var product: String = player.items.keys()[0]
			carry_label.text = Lang.t("CARRYING") % (Lang.t("CARRYING_BOX") % [player.items[product], Products.display_name(product)])
		_:
			carry_label.text = Lang.t("CARRYING") % Lang.t("CARRYING_NOTHING")

	hint_label.text = game.get_hint() if game.phase == "playing" else ""


## Panel de arriba a la izquierda: pedido del jugador, paciencia, estado y lista de pasos.
func _update_order_panel() -> void:
	var hud_order: Dictionary = game.hud_order
	if hud_order.is_empty():
		order_tab.text = Lang.t("TAB_ORDER_NONE") if right_column.visible else Lang.t("NO_ORDER")
		order_label.text = Lang.t("NO_ORDER")
		urgent_label.visible = false
		order_time_bar.visible = false
		status_label.text = ""
		steps_label.text = Lang.t("PICK_FROM_BOARD") if right_column.visible else Lang.t("NEXT_ORDER_COMING")
		return

	var player: Player = game.player
	var order_items: Dictionary = hud_order["items"]
	var order_active := not player.order.is_empty()
	var picked: Dictionary = player.items if player.carrying == "productos" else {}
	urgent_label.text = Lang.t("URGENT")
	urgent_label.visible = hud_order["urgent"]
	order_time_bar.visible = order_active
	if order_active:
		_set_time_bar(order_time_bar, hud_order)

	var order_lines := [Lang.t("ORDER") % hud_order["number"]]
	for id: String in order_items:
		order_lines.append(Products.describe(id, order_items[id]))
	order_lines.append(Lang.t("REWARD") % hud_order["reward"])
	if order_active:
		order_lines[-1] += "  ·  " + Lang.t("TIME_LEFT") % ceili(hud_order["time_left"])
	order_label.text = "\n".join(order_lines)

	# Estado del pedido según lo que lleva el jugador
	var status := "STATUS_COMPLETED"
	var status_color := Color(0.4, 1, 0.45)
	if order_active:
		if player.carrying == "pedido":
			status = "STATUS_PACKED"
			status_color = Color(1, 0.85, 0.4)
		elif picked.is_empty():
			status = "STATUS_PENDING"
			status_color = Color(1, 0.6, 0.4)
		elif game.get_missing_products(player).is_empty():
			status = "STATUS_READY_TO_PACK"
			status_color = Color(1, 0.75, 0.9)
		else:
			status = "STATUS_PICKING"
			status_color = Color(1, 0.75, 0.9)
	status_label.text = Lang.t("STATUS") % Lang.t(status)
	status_label.add_theme_color_override("font_color", status_color)

	# Lista de pasos: [x] hecho, > actual, [ ] pendiente
	var steps := []
	var prepared := not order_active or player.carrying == "pedido"
	for id: String in order_items:
		steps.append([Lang.t("STEP_PICK") % Products.display_name(id), prepared or picked.has(id)])
	steps.append([Lang.t("STEP_PACK"), prepared])
	steps.append([Lang.t("STEP_DELIVER"), not order_active])
	var lines := []
	var current_step := ""
	for step in steps:
		var mark := "[x]"
		if not step[1]:
			mark = "[ ]" if current_step != "" else ">  "
			if current_step == "":
				current_step = step[0]
		lines.append("%s %s" % [mark, step[0]])
	# la pestaña resume el pedido con el paso que toca ahora
	if current_step == "":
		current_step = Lang.t("STATUS_COMPLETED")
	order_tab.text = Lang.t("TAB_ORDER") % [hud_order["number"], current_step]
	if not order_active:
		lines.append(Lang.t("PICK_FROM_BOARD") if right_column.visible else Lang.t("NEXT_ORDER_COMING"))
	steps_label.text = "\n".join(lines)


## Resumen corto en las pestañas (los paneles se abren con el mouse).
func _update_tabs() -> void:
	if not game.shipment.is_empty():
		supplier_tab.text = Lang.t("TAB_SUPPLIER_TRUCK") % ceili(game.shipment["time_left"])
	elif not game.reception_boxes.is_empty():
		supplier_tab.text = Lang.t("TAB_SUPPLIER_BOXES") % game.reception_boxes.size()
	else:
		supplier_tab.text = Lang.t("TAB_SUPPLIER")
	shop_tab.text = Lang.t("TAB_SHOP") % [game.robots.size(), game.MAX_ROBOTS]
	var free := 0
	for order in game.orders:
		if order["owner"] == null:
			free += 1
	board_tab.text = Lang.t("TAB_BOARD") % free


# --- Barras de paciencia -------------------------------------------------------

## Barra con fondo oscuro y relleno de color propio (verde/amarillo/rojo).
func _style_time_bar(bar: ProgressBar) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.55)
	background.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_OK
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	_bar_fills[bar] = fill


## Pone en la barra el tiempo que le queda al cliente: verde > 50 %, amarillo > 25 %, rojo.
func _set_time_bar(bar: ProgressBar, order: Dictionary) -> void:
	var ratio: float = clampf(order["time_left"] / order["time_total"], 0.0, 1.0)
	bar.value = ratio
	var fill: StyleBoxFlat = _bar_fills[bar]
	if ratio > Levels.TIP_THRESHOLD:
		fill.bg_color = COLOR_OK
	elif ratio > 0.25:
		fill.bg_color = COLOR_WARN
	else:
		fill.bg_color = COLOR_DANGER


# --- Tienda ------------------------------------------------------------------

func _update_shop() -> void:
	var full: bool = game.robots.size() >= game.MAX_ROBOTS
	buy_robot_button.disabled = game.phase != "playing" or game.money < game.ROBOT_COST or full
	buy_robot_button.text = Lang.t("SHOP_ROBOT_MAX") if full else Lang.t("SHOP_ROBOT") % game.ROBOT_COST
	shop_title.text = Lang.t("SHOP_TITLE")
	shop_robot_info.text = Lang.t("SHOP_ROBOT_INFO")
	shop_fast_robot.text = Lang.t("SHOP_FAST_ROBOT")
	shop_conveyor.text = Lang.t("SHOP_CONVEYOR")
	shop_ai_note.text = Lang.t("SHOP_AI_ACTIVE") if game.config["ai"] else Lang.t("SHOP_AI_NOTE")


# --- Proveedor (Nivel 3) -------------------------------------------------------

## Filas del panel del proveedor: "OSOS $10/caja  [-] x0 [+]", una por gomita del nivel.
func _build_supplier() -> void:
	for id: String in game.config["products"]:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 14)
		var minus := Button.new()
		minus.text = " - "
		minus.focus_mode = Control.FOCUS_NONE
		minus.pressed.connect(game.change_supplier_lots.bind(id, -1))
		var qty := Label.new()
		qty.custom_minimum_size = Vector2(32, 0)
		qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var plus := Button.new()
		plus.text = " + "
		plus.focus_mode = Control.FOCUS_NONE
		plus.pressed.connect(game.change_supplier_lots.bind(id, 1))
		for node: Control in [label, minus, qty, plus]:
			row.add_child(node)
		supplier_rows.add_child(row)
		_supplier_rows[id] = {"label": label, "minus": minus, "qty": qty, "plus": plus}


func _update_supplier() -> void:
	supplier_title.text = Lang.t("SUPPLIER_TITLE")
	var selected: int = game.selected_lots()
	var free: int = game.reception_free_slots()
	var shipping: bool = not game.shipment.is_empty()
	for id: String in _supplier_rows:
		var row: Dictionary = _supplier_rows[id]
		row["label"].text = Lang.t("SUPPLIER_ROW") % [Products.display_name(id), Products.INFO[id]["lot_cost"]]
		row["qty"].text = "x%d" % game.supplier_lots[id]
		row["minus"].disabled = game.supplier_lots[id] == 0
		row["plus"].disabled = shipping or selected >= free
	supplier_info.text = Lang.t("SUPPLIER_INFO") % [Products.LOT_SIZE, game.reception_boxes.size(), game.RECEIVING_CAPACITY]
	if shipping:
		supplier_button.text = Lang.t("SUPPLIER_IN_TRANSIT") % ceili(game.shipment["time_left"])
		supplier_button.disabled = true
	else:
		var cost: int = game.supplier_cost()
		supplier_button.text = Lang.t("SUPPLIER_ORDER") % [cost, game.FREIGHT]
		supplier_button.disabled = game.phase != "playing" or selected == 0 or selected > free or game.money < cost


# --- Tablero de pedidos (Niveles 2 y 3) ----------------------------------------

## Rehace las filas solo cuando cambian los pedidos, los robots o el idioma;
## cada frame actualiza dueño, tiempo, stock, puntaje de la IA y qué botones se pueden usar.
func _update_board() -> void:
	board_title.text = Lang.t("BOARD_TITLE")
	promo_label.text = Lang.t("PROMO") % Products.display_name(game.promo) if game.promo != "" else ""
	var signature := "%s|%d|" % [Lang.current, game.robots.size()]
	for order in game.orders:
		signature += "%d," % order["number"]
	if signature != _board_signature:
		_board_signature = signature
		_rebuild_board()

	var show_ai: bool = game.config["ai"] and not game.robots.is_empty()
	for row: Dictionary in _board_rows:
		var order: Dictionary = row["order"]
		# quién lo tiene se ve en el botón verde; aquí solo LIBRE o EN CURSO
		var current_owner = order["owner"]
		var busy: bool = current_owner != null and current_owner.carrying != ""
		var has_stock: bool = game.can_fulfill(order) or busy
		var text := "#%03d  $%d  %ds" % [order["number"], order["reward"], ceili(order["time_left"])]
		if order["urgent"]:
			text += "  " + Lang.t("URGENT")
		if busy:
			text += "  · " + Lang.t("BOARD_BUSY")
		elif current_owner == null:
			text += "  · " + Lang.t("BOARD_FREE")
		text += "\n" + Products.summary(order["items"])
		if not has_stock:
			text += "  —  " + Lang.t("BOARD_NO_STOCK")
		if show_ai and current_owner == null:
			text += "  ·  " + Lang.t("BOARD_AI_SCORE") % TaskAI.best_score(game, order)
		var label: Label = row["label"]
		label.text = text
		label.modulate = Color(1, 0.6, 0.55) if not has_stock else (Color(1, 0.8, 0.5) if order["urgent"] else Color.WHITE)
		_set_time_bar(row["bar"], order)
		for entry: Dictionary in row["buttons"]:
			var button: Button = entry["button"]
			button.disabled = game.phase != "playing" or not game.can_assign(order, entry["worker"])
			button.modulate = Color(0.5, 1, 0.55) if current_owner == entry["worker"] else Color.WHITE


func _rebuild_board() -> void:
	for child in board_rows.get_children():
		_bar_fills.erase(child.get_child(1) if child.get_child_count() > 1 else null)
		child.queue_free()
	_board_rows.clear()
	var workers: Array = game.workers()
	for order in game.orders:
		var row := VBoxContainer.new()
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 14)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 6)
		bar.max_value = 1.0
		bar.step = 0.001
		bar.show_percentage = false
		_style_time_bar(bar)
		row.add_child(bar)
		var buttons_box := HBoxContainer.new()
		var buttons := []
		for worker in workers:
			var button := Button.new()
			button.text = game.worker_name(worker)
			button.focus_mode = Control.FOCUS_NONE
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 13)
			button.pressed.connect(game.assign_from_board.bind(order, worker))
			buttons_box.add_child(button)
			buttons.append({"worker": worker, "button": button})
		row.add_child(buttons_box)
		board_rows.add_child(row)
		_board_rows.append({"order": order, "label": label, "bar": bar, "buttons": buttons})
