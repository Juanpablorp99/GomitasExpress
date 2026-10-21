extends Node2D
## Reglas del juego. Es el nodo raíz de cada escena de nivel (scenes/levels/level_N.tscn).
## La configuración de cada nivel (gomitas, tiempo, metas, robots...) está en levels.gd.
##
## Ciclo: PEDIDO -> RECOGER -> PREPARAR -> DESPACHAR -> DINERO.
## Cada pedido tiene un tiempo de espera: si se acaba, se pierde una vida y hay multa.
## Entregar rápido da propina y sube el COMBO; los pedidos URGENTES pagan el doble con menos tiempo.
## Preparar un pedido y reparar un robot se hacen MANTENIENDO E.
## PAUSA: ESC / P o el botón del HUD (ver hud.gd).
## Peligros: montacargas que te chocan, hielo y derrames resbaladizos, eventos sorpresa
## (hora pico, derrame, apagón, tormenta de nieve; cada nivel usa los suyos, ver levels.gd).
## El nivel dura un tiempo fijo; al final se gana con 1-3 estrellas según el dinero.
##
## Las reglas de interacción reciben un "worker" (jugador o robot: cualquier nodo con
## las variables `order`, `carrying` e `items`), así los dos usan las mismas funciones.
##
## Lo que se ve en pantalla está en otros scripts:
##   HUD (paneles, tablero, mensajes) -> scripts/ui/hud.gd
##   Suelo, paredes y decoración      -> scripts/world/scenery.gd
##   Luces del nivel de noche         -> scripts/world/lighting.gd
##   IA de los robots (Nivel 3)       -> scripts/game/task_ai.gd
##   Caminos de los robots (A*)       -> scripts/game/path_grid.gd

const WALL_THICKNESS := 40.0
const NEXT_ORDER_DELAY := 3.0
const PROMO_INTERVAL := 45.0     # cada cuánto cambia el producto en promoción
const PROMO_CHANCE := 0.7        # probabilidad de que un pedido incluya el producto en promo
const PROMO_EXTRA := 2           # unidades extra del producto en promo
const FREIGHT := 5               # costo fijo de cada envío del proveedor
const SHIPPING_TIME := 15.0      # segundos que tarda el camión del proveedor
const RECEIVING_CAPACITY := 6    # cajas que caben en recepción
const ROBOT_COST := 35
const MAX_ROBOTS := 3
const STUN_TIME := 1.2           # segundos aturdido si te choca un montacargas
const REPAIR_DISTANCE := 85.0    # qué tan cerca hay que estar de un robot para repararlo
const STORM_SPEED := 0.7         # en la tormenta de nieve el jugador va más lento

## Qué nivel es esta escena (1, 2 o 3).
@export var level_number := 1

## Fases: "intro" (pantalla de inicio), "playing", "won", "lost", "game_complete".
var phase := "intro"
## Por qué se perdió: "time", "hearts" o "bankrupt".
var lose_reason := ""
var config: Dictionary
var hearts := Levels.HEARTS
var time_left := 0.0
var stars := 0
var orders_completed := 0
var money := 0
var order_number := 0
## Pedidos pendientes: { "number", "items": { "osos": 2 }, "reward", "owner": worker o null,
##                       "time_left", "time_total", "urgent" }
var orders: Array[Dictionary] = []
var robots: Array[Robot] = []
var current_station: Station = null
## Producto en promoción (aparece más en los pedidos).
var promo := ""
## Envío del proveedor en camino: { "items": { "osos": 2 (cajas) }, "time_left": float } o {}.
var shipment := {}
## Cajas esperando en recepción: [{ "product": String, "qty": int }]
var reception_boxes: Array[Dictionary] = []
## Pedido que muestra el panel del HUD: el del jugador o el último que entregó.
var hud_order := {}
## Cajas elegidas en el panel del proveedor para el próximo envío.
var supplier_lots := {}
## Lo que se pagó por el último pedido entregado (recompensa + propina).
var last_payment := 0

## Tamaño del almacén (de levels.gd).
var room_size := Vector2.ZERO
## Entregas rápidas seguidas del jugador (multiplican el pago).
var combo := 0
## Evento sorpresa activo ("" si no hay) y segundos que le quedan.
var event := ""
var event_left := 0.0
## Derrames resbaladizos activos: [{ "rect": Rect2 }]
var spills: Array[Dictionary] = []

var _promo_time := 0.0
var _warned_time := false
var _event_time := 0.0
var _hold_target: Object = null   # estación o robot en el que se está manteniendo E
var _hold_time := 0.0
var _paths := PathGrid.new()

@onready var player: Player = $Player
@onready var reception: Station = get_node_or_null("Stations/Reception")
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	config = Levels.get_config(level_number)
	room_size = config["room"]
	time_left = config["duration"]
	money = config["start_money"]
	for id: String in config["products"]:
		supplier_lots[id] = 0
		var shelf := get_shelf(id)
		shelf.show_stock = config["supplier"]
		shelf.stock = config["initial_stock"]
	_build_walls()
	_paths.build(room_size, _solid_rects())
	_setup_camera()
	_event_time = randf_range(Levels.EVENT_INTERVAL[0], Levels.EVENT_INTERVAL[1])
	player.interact_requested.connect(_on_player_interact)
	hud.setup()
	hud.save_menu_closed.connect(_go_to_next_level)
	_set_player_enabled(false)
	hud.show_overlay()   # pantalla de inicio del nivel


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_language"):
		toggle_language()
	elif hud.is_overlay_visible() and event.is_action_pressed("ui_accept"):
		_on_overlay_accept()


## ENTER en la pantalla oscura: empezar, siguiente nivel, reintentar o volver a empezar.
func _on_overlay_accept() -> void:
	match phase:
		"intro":
			_start_level()
		"won":
			hud.open_save_menu()   # "¿Guardar partida?" y después _go_to_next_level()
		"game_complete":
			get_tree().change_scene_to_file(Levels.TITLE_SCENE)
		"lost":
			get_tree().reload_current_scene()


## Después del menú de guardado: siguiente nivel, o la pantalla de juego completado.
func _go_to_next_level() -> void:
	if level_number < Levels.count():
		get_tree().change_scene_to_file(Levels.SCENES[level_number])
	else:
		phase = "game_complete"
		hud.show_overlay()


## Cambia entre español e inglés y redibuja los textos del almacén.
func toggle_language() -> void:
	Lang.toggle()
	for station: Station in get_tree().get_nodes_in_group("stations"):
		station.queue_redraw()


func _process(delta: float) -> void:
	_update_current_station()
	if phase == "playing":
		_update_timers(delta)
		_update_hazards()
		_update_hold(delta)


## Reloj del nivel, paciencia de los clientes, proveedor, promo y bancarrota.
func _update_timers(delta: float) -> void:
	time_left -= delta
	if time_left <= 30.0 and not _warned_time:
		_warned_time = true
		hud.show_message(Lang.t("MSG_TIME_ALMOST_UP"), Color(1.0, 0.6, 0.3))
	if time_left <= 0.0:
		time_left = 0.0
		_finish_level()
		return

	var expired := []
	for order in orders:
		order["time_left"] -= delta
		if order["time_left"] <= 0.0:
			expired.append(order)
	for order: Dictionary in expired:
		_expire_order(order)
	if phase != "playing":
		return

	if not shipment.is_empty():
		shipment["time_left"] -= delta
		reception.info_text = Lang.t("SUPPLIER_ETA") % ceili(shipment["time_left"])
		if shipment["time_left"] <= 0.0:
			_receive_shipment()

	if config["promo"]:
		_promo_time -= delta
		if _promo_time <= 0.0:
			_new_promo()

	# eventos sorpresa
	if event != "":
		event_left -= delta
		if event_left <= 0.0:
			_end_event()
	else:
		_event_time -= delta
		if _event_time <= 0.0 and not config["events"].is_empty():
			_start_event(config["events"].pick_random())

	if config["supplier"] and _is_bankrupt():
		_lose("bankrupt")


# --- Eventos sorpresa ----------------------------------------------------------

func _start_event(name: String) -> void:
	event = name
	event_left = Levels.EVENT_DURATION[name]
	match name:
		"rush":
			hud.show_message(Lang.t("MSG_EVENT_RUSH"), Color(1.0, 0.55, 0.2), 2.2)
			_refill_orders()
		"spill":
			var spot: Vector2 = config["spill_spots"].pick_random()
			spills.append({"rect": Rect2(spot - Vector2(110, 50), Vector2(220, 100))})
			hud.show_message(Lang.t("MSG_EVENT_SPILL"), Color(0.5, 0.8, 1.0), 2.2)
		"blackout":
			hud.show_message(Lang.t("MSG_EVENT_BLACKOUT"), Color(0.7, 0.7, 1.0), 2.2)
		"storm":
			hud.show_message(Lang.t("MSG_EVENT_STORM"), Color(0.85, 0.95, 1.0), 2.2)


func _end_event() -> void:
	event = ""
	spills.clear()
	_event_time = randf_range(Levels.EVENT_INTERVAL[0], Levels.EVENT_INTERVAL[1])


# --- Peligros: montacargas, hielo y derrames ---------------------------------

func _update_hazards() -> void:
	var pos := player.global_position
	var slippery := false
	for rect: Rect2 in config["ice"]:
		slippery = slippery or rect.has_point(pos)
	for spill in spills:
		slippery = slippery or spill["rect"].has_point(pos)
	player.slippery = slippery
	player.speed_mult = STORM_SPEED if event == "storm" else 1.0

	for forklift: Forklift in get_tree().get_nodes_in_group("forklifts"):
		if not player.is_stunned() and forklift.hits(pos):
			_hit_by_forklift(forklift)


## Un montacargas chocó al jugador: queda aturdido y se le caen las gomitas sueltas.
func _hit_by_forklift(forklift: Forklift) -> void:
	forklift.cooldown = Forklift.HIT_COOLDOWN
	var push := (player.global_position - forklift.position).normalized() * 420.0 + forklift.direction() * 200.0
	player.stun(STUN_TIME, push)
	_reset_hold()
	if player.carrying == "productos":
		player.items = {}
		player.carrying = ""
		hud.show_message(Lang.t("MSG_FORKLIFT_DROP"), Color(1.0, 0.5, 0.3), 2.0)
	else:
		hud.show_message(Lang.t("MSG_FORKLIFT_HIT"), Color(1.0, 0.5, 0.3), 1.6)


# --- Mantener E: preparar pedido y reparar robots -----------------------------

## Qué se puede hacer manteniendo E ahora: un robot atascado cercano o la mesa de preparación.
func _hold_candidate() -> Object:
	for robot in robots:
		if robot.broken and robot.position.distance_to(player.global_position) < REPAIR_DISTANCE:
			return robot
	if current_station != null and current_station.type == Station.Type.PREP \
			and get_blocked_reason(player, current_station) == "":
		return current_station
	return null


func _update_hold(delta: float) -> void:
	var candidate = _hold_candidate()
	if candidate == null or player.is_stunned() or not Input.is_action_pressed("interact"):
		_reset_hold()
		return
	if candidate != _hold_target:
		_reset_hold()
		_hold_target = candidate
	_hold_time += delta
	var needed: float = Levels.REPAIR_TIME if candidate is Robot else Levels.PACK_TIME
	var ratio := minf(_hold_time / needed, 1.0)
	if candidate is Robot:
		candidate.repair_ratio = ratio
	else:
		player.hold_ratio = ratio
	if ratio >= 1.0:
		if candidate is Robot:
			candidate.repair()
			hud.show_message(Lang.t("MSG_ROBOT_REPAIRED") % candidate.robot_name, Color(0.4, 1.0, 0.5))
		else:
			use_station(player, candidate)
		_reset_hold()


func _reset_hold() -> void:
	if _hold_target is Robot and is_instance_valid(_hold_target):
		(_hold_target as Robot).repair_ratio = 0.0
	_hold_target = null
	_hold_time = 0.0
	player.hold_ratio = 0.0


## Lo llama robot.gd cuando se atasca.
func on_robot_broken(robot: Robot) -> void:
	hud.show_message(Lang.t("MSG_ROBOT_BROKEN") % robot.robot_name, Color(1.0, 0.45, 0.4), 2.2)


## Texto de ayuda de abajo: qué hace E (o por qué no se puede) donde está el jugador.
func get_hint() -> String:
	var candidate = _hold_candidate()
	if candidate is Robot:
		return Lang.t("HOLD_E") % (Lang.t("ACTION_REPAIR") % candidate.robot_name)
	if current_station == null:
		return ""
	var reason := get_blocked_reason(player, current_station)
	if reason != "":
		return reason
	if current_station.type == Station.Type.PREP:
		return Lang.t("HOLD_E") % get_action_name(player, current_station)
	return "[E] " + get_action_name(player, current_station)


# --- Inicio y fin del nivel ----------------------------------------------------

func _start_level() -> void:
	phase = "playing"
	hud.hide_overlay()
	_set_player_enabled(true)
	_promo_time = PROMO_INTERVAL
	_refill_orders()


## Se acabó el reloj: se gana si se llegó a la primera meta de dinero.
func _finish_level() -> void:
	stars = 0
	for goal: int in config["stars"]:
		if money >= goal:
			stars += 1
	if stars == 0:
		_lose("time")
		return
	SaveManager.record_win(level_number, stars, money)   # desbloquea el siguiente y autoguarda
	phase = "won"
	_stop_everything()


func _lose(reason: String) -> void:
	lose_reason = reason
	phase = "lost"
	_stop_everything()


func _stop_everything() -> void:
	_set_player_enabled(false)
	for robot in robots:
		robot.set_process(false)
	hud.show_overlay()


func _set_player_enabled(enabled: bool) -> void:
	player.set_physics_process(enabled)
	player.set_process_unhandled_input(enabled)


## Niveles con tablero: el jugador elige sus pedidos. Sin tablero se le asignan en orden.
func _has_board() -> bool:
	return config["board"]


## Pedidos a la vez; en la hora pico llegan más.
func _board_size() -> int:
	var extra := (2 if _has_board() else 1) if event == "rush" else 0
	return config["board_size"] + extra


func _setup_camera() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.zoom = Vector2.ONE * config["zoom"]
	camera.limit_left = -450
	camera.limit_top = -350
	camera.limit_right = int(room_size.x) + 450
	camera.limit_bottom = int(room_size.y) + 320


## Rectángulos donde no se puede pasar: paredes, estaciones sólidas y decoración.
func _solid_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = _wall_rects()
	for station: Station in get_tree().get_nodes_in_group("stations"):
		if station.solid:
			rects.append(Rect2(station.global_position - station.size / 2, station.size))
	rects.append_array($Scenery.solid_rects)
	return rects


## Camino A* para un robot (ver path_grid.gd).
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return _paths.find_path(from, to)


func path_length(from: Vector2, to: Vector2) -> float:
	return _paths.path_length(from, to)


# --- Pedidos -----------------------------------------------------------------

## Crea un pedido (el primero puede ser fijo de tutorial) y lo deja pendiente (sin dueño).
func _new_order() -> Dictionary:
	var items: Dictionary
	var first: Dictionary = config["first_order"]
	var is_first := order_number == 0 and not first.is_empty()
	items = first if is_first else _random_items()
	order_number += 1
	var urgent: bool = not is_first and randf() < config["urgent_chance"]
	var patience: float = config["patience_base"] + config["patience_per_product"] * items.size()
	var reward := Products.order_value(items)
	if urgent:
		patience *= Levels.URGENT_TIME_MULT
		reward *= Levels.URGENT_REWARD_MULT
	var order := {"number": order_number, "items": items, "reward": reward, "owner": null,
			"time_left": patience, "time_total": patience, "urgent": urgent}
	orders.append(order)
	if urgent:
		hud.show_message(Lang.t("MSG_NEW_URGENT") % order_number, Color(1.0, 0.55, 0.2))
	else:
		hud.show_message(Lang.t("MSG_NEW_ORDER") % order_number, Color(0.6, 0.85, 1.0))
	return order


## 1 a `max_products` gomitas del nivel con 2-5 unidades cada una; el producto en
## promo sale más seguido y en mayor cantidad.
func _random_items() -> Dictionary:
	var ids: Array = config["products"].duplicate()
	ids.shuffle()
	var roll := randf()
	var count := 1
	if roll > 0.75:
		count = 3
	elif roll > 0.35:
		count = 2
	count = mini(count, config["max_products"])
	var picked := ids.slice(0, count)
	if promo != "" and not promo in picked and randf() < PROMO_CHANCE:
		picked[0] = promo
	var items := {}
	for id: String in picked:
		items[id] = randi_range(Levels.MIN_ITEM_QTY, Levels.MAX_ITEM_QTY) + (PROMO_EXTRA if id == promo else 0)
	return items


## Rellena el tablero (o la cola) hasta tener los pedidos que tocan. Sin tablero,
## si el jugador está libre se le asigna el pedido más antiguo.
func _refill_orders() -> void:
	while orders.size() < _board_size():
		_new_order()
	if not _has_board() and player.order.is_empty():
		for order in orders:
			if order["owner"] == null:
				assign_order(order, player)
				break


## Después de entregar o perder un pedido llega el siguiente.
func _next_order_later() -> void:
	await get_tree().create_timer(NEXT_ORDER_DELAY, false).timeout   # false: se detiene en pausa
	if phase == "playing":
		_refill_orders()


func _complete_order(worker) -> void:
	var order: Dictionary = worker.order
	var fast: bool = order["time_left"] / order["time_total"] >= Levels.TIP_THRESHOLD
	var tip := ceili(order["reward"] * Levels.TIP_RATE) if fast else 0
	# combo: entregas rápidas seguidas del jugador multiplican el pago (x1, x1.5, x2... x3)
	var multiplier := 1.0
	if worker == player:
		combo = combo + 1 if fast else 0
		multiplier = combo_multiplier()
	var base := roundi(order["reward"] * multiplier)
	last_payment = base + tip
	money += last_payment
	orders.erase(order)
	_set_worker_order(worker, {})
	orders_completed += 1
	if worker == player:
		hud_order = order   # el panel sigue mostrándolo como COMPLETADO
		var text := Lang.t("MSG_ORDER_COMPLETED_TIP") % [base, tip] if tip > 0 \
				else Lang.t("MSG_ORDER_COMPLETED") % base
		if multiplier > 1.0:
			text += "\n" + Lang.t("MSG_COMBO") % combo_text(multiplier)
		hud.show_message(text, Color(0.4, 1.0, 0.45), NEXT_ORDER_DELAY - 0.6)
	_next_order_later()


## Multiplicador actual del combo (para el HUD).
func combo_multiplier() -> float:
	return minf(1.0 + Levels.COMBO_STEP * maxi(combo - 1, 0), Levels.COMBO_MAX) if combo > 0 else 1.0


## "x1.5", "x2", "x3"...
static func combo_text(multiplier: float) -> String:
	return ("x%d" % int(multiplier)) if is_equal_approx(multiplier, roundf(multiplier)) else ("x%.1f" % multiplier)


## El cliente se cansó de esperar: -1 vida, multa, y lo que llevaba su dueño se pierde.
func _expire_order(order: Dictionary) -> void:
	orders.erase(order)
	money = maxi(money - Levels.EXPIRE_PENALTY, 0)
	hearts -= 1
	combo = 0
	var worker = order["owner"]
	if worker != null:
		if worker.carrying != "caja":
			worker.carrying = ""
			worker.items = {}
		_set_worker_order(worker, {})
	hud.show_message(Lang.t("MSG_ORDER_EXPIRED") % [order["number"], Levels.EXPIRE_PENALTY], Color(1.0, 0.4, 0.4), 2.2)
	if hearts <= 0:
		_lose("hearts")
		return
	_next_order_later()


func _new_promo() -> void:
	_promo_time = PROMO_INTERVAL
	var ids: Array = config["products"].duplicate()
	ids.erase(promo)
	promo = ids.pick_random()
	hud.show_message(Lang.t("MSG_PROMO") % Products.display_name(promo), Color(1.0, 0.75, 0.3), 2.0)


## True si las estanterías tienen ahora mismo stock para todo el pedido.
## (Sin proveedor el stock es infinito.)
func can_fulfill(order: Dictionary) -> bool:
	if not config["supplier"]:
		return true
	for id: String in order["items"]:
		if get_shelf(id).stock < order["items"][id]:
			return false
	return true


# --- Asignación de pedidos ---------------------------------------------------

## True si `worker` puede quedarse con `order`. No se cambian pedidos a medias:
## ni el worker ni el dueño actual pueden tener nada en las manos.
func can_assign(order: Dictionary, worker) -> bool:
	if not orders.has(order) or order["owner"] == worker or worker.carrying != "":
		return false
	var current_owner = order["owner"]
	return current_owner == null or current_owner.carrying == ""


## Le da `order` a `worker`. Si el pedido tenía otro dueño, ese se queda sin pedido;
## si el worker ya tenía uno, ese vuelve a quedar libre en el tablero.
func assign_order(order: Dictionary, worker) -> void:
	if not can_assign(order, worker):
		return
	if order["owner"] != null:
		_set_worker_order(order["owner"], {})
	if not worker.order.is_empty():
		worker.order["owner"] = null
	order["owner"] = worker
	_set_worker_order(worker, order)


## Botón del tablero: el jugador le da un pedido a sí mismo o a un robot.
func assign_from_board(order: Dictionary, worker) -> void:
	if phase != "playing" or not can_assign(order, worker):
		return
	assign_order(order, worker)
	hud.show_message(Lang.t("MSG_ORDER_ASSIGNED") % [order["number"], worker_name(worker)], Color(0.6, 0.85, 1.0))


## Un robot libre pide trabajo. En el Nivel 3 decide la IA (task_ai.gd); antes,
## toma el primer pedido libre que se pueda completar. Devuelve true si consiguió uno.
func take_free_order(worker) -> bool:
	if phase != "playing":
		return false
	if config["ai"]:
		var choice := TaskAI.choose_order(self, worker)
		if choice.is_empty():
			return false
		assign_order(choice["order"], worker)
		worker.ai_choice = {"number": choice["order"]["number"], "score": choice["score"]}
		return true
	for order in orders:
		if order["owner"] == null and can_fulfill(order):
			assign_order(order, worker)
			return true
	return false


func has_free_orders() -> bool:
	for order in orders:
		if order["owner"] == null:
			return true
	return false


func _set_worker_order(worker, order: Dictionary) -> void:
	worker.order = order
	if worker == player:
		hud_order = order
	if worker.has_method("on_order_changed"):
		worker.on_order_changed()


func worker_name(worker) -> String:
	return Lang.t("BOARD_ME") if worker == player else worker.robot_name


## Sin dinero para reponer, nada en camino ni en las manos, y las estanterías sin
## suficiente stock para ningún pedido posible: ya no se puede seguir.
func _is_bankrupt() -> bool:
	if money >= _cheapest_restock() or not shipment.is_empty() or not reception_boxes.is_empty():
		return false
	for worker in workers():
		if worker.carrying != "":
			return false
	for id: String in config["products"]:
		if get_shelf(id).stock >= Levels.MIN_ITEM_QTY:
			return false
	return true


# --- Robots ------------------------------------------------------------------

func buy_robot() -> void:
	if phase != "playing" or not config["robots"] or money < ROBOT_COST or robots.size() >= MAX_ROBOTS:
		return
	money -= ROBOT_COST
	var robot := Robot.new()
	robots.append(robot)
	robot.warehouse = self
	robot.robot_name = "ROBOT %d" % robots.size()
	var dock: Rect2 = config["dock"]
	robot.position = dock.get_center() + Vector2((robots.size() - 2) * 90, 10)
	add_child(robot)
	hud.show_message(Lang.t("MSG_ROBOT_BOUGHT") % robot.robot_name, Color(0.55, 0.85, 1.0))


## El jugador y todos los robots.
func workers() -> Array:
	var list: Array = [player]
	list.append_array(robots)
	return list


func get_shelf(product: String) -> Station:
	for station: Station in get_tree().get_nodes_in_group("stations"):
		if station.type == Station.Type.SHELF and station.product == product:
			return station
	return null


func get_station_of_type(type: Station.Type) -> Station:
	for station: Station in get_tree().get_nodes_in_group("stations"):
		if station.type == type:
			return station
	return null


## Productos del pedido del worker que todavía no ha recogido.
func get_missing_products(worker) -> Array:
	var missing := []
	if worker.order.is_empty():
		return missing
	var picked: Dictionary = worker.items if worker.carrying == "productos" else {}
	for id: String in worker.order["items"]:
		if not picked.has(id):
			missing.append(id)
	return missing


## True si el worker viene a recoger de esta estantería pero no queda stock suficiente.
func is_out_of_stock(worker, station: Station) -> bool:
	if not config["supplier"]:
		return false
	if station.type != Station.Type.SHELF or worker.carrying == "caja" or worker.order.is_empty():
		return false
	var quantity: int = worker.order["items"].get(station.product, 0)
	return quantity > 0 and station.stock < quantity


# --- Proveedor y recepción (Nivel 3) -----------------------------------------

## Botones [-] / [+] del panel del proveedor.
func change_supplier_lots(id: String, amount: int) -> void:
	supplier_lots[id] = maxi(supplier_lots[id] + amount, 0)


func selected_lots() -> int:
	var total := 0
	for id: String in supplier_lots:
		total += supplier_lots[id]
	return total


func supplier_cost() -> int:
	var total := FREIGHT
	for id: String in supplier_lots:
		total += supplier_lots[id] * int(Products.INFO[id]["lot_cost"])
	return total


func _cheapest_restock() -> int:
	var cheapest := INF
	for id: String in config["products"]:
		cheapest = minf(cheapest, Products.INFO[id]["lot_cost"])
	return int(cheapest) + FREIGHT


## Huecos libres en recepción (la caja que lleva el jugador también ocupa uno).
func reception_free_slots() -> int:
	var used := reception_boxes.size() + (1 if player.carrying == "caja" else 0)
	return RECEIVING_CAPACITY - used


## Botón PEDIR del panel del proveedor.
func order_supplies() -> void:
	var lots := selected_lots()
	var cost := supplier_cost()
	if phase != "playing" or not shipment.is_empty() or lots == 0 or lots > reception_free_slots() or money < cost:
		return
	money -= cost
	shipment = {"items": supplier_lots.duplicate(), "time_left": SHIPPING_TIME}
	for id: String in supplier_lots:
		supplier_lots[id] = 0
	hud.show_message(Lang.t("MSG_SUPPLY_ORDERED") % cost, Color(0.6, 0.85, 1.0))


func _receive_shipment() -> void:
	for id: String in shipment["items"]:
		for i in shipment["items"][id]:
			reception_boxes.append({"product": id, "qty": Products.LOT_SIZE})
	shipment = {}
	reception.info_text = ""
	_sync_reception()
	hud.show_message(Lang.t("MSG_SUPPLY_ARRIVED"), Color(0.6, 0.85, 1.0), 2.0)


func _sync_reception() -> void:
	reception.boxes = reception_boxes.duplicate()


## La caja que conviene llevar primero: la de la estantería con menos stock.
func _best_box() -> Dictionary:
	var best := {}
	var best_ratio := INF
	for box in reception_boxes:
		var shelf := get_shelf(box["product"])
		var ratio := float(shelf.stock) / shelf.capacity
		if ratio < best_ratio:
			best = box
			best_ratio = ratio
	return best


# --- Reglas de interacción ---------------------------------------------------

## Devuelve "" si el worker puede usar la estación, o el motivo por el que no puede.
func get_blocked_reason(worker, station: Station) -> String:
	match station.type:
		Station.Type.SHELF:
			if worker.carrying == "caja":
				var box_product: String = worker.items.keys()[0]
				if box_product != station.product:
					return Lang.t("BLOCK_WRONG_SHELF") % Products.display_name(box_product)
				if station.stock >= station.capacity:
					return Lang.t("BLOCK_SHELF_FULL")
				return ""
			if worker.order.is_empty():
				return Lang.t("BLOCK_NO_ORDER_ASSIGNED") if _has_board() else Lang.t("BLOCK_NO_ORDERS")
			if worker.carrying == "pedido":
				return Lang.t("BLOCK_HAS_PACKED_ORDER")
			if not worker.order["items"].has(station.product):
				return Lang.t("BLOCK_NOT_IN_ORDER") % Products.display_name(station.product)
			if worker.items.has(station.product):
				return Lang.t("BLOCK_ALREADY_PICKED") % Products.display_name(station.product)
			if is_out_of_stock(worker, station):
				return Lang.t("BLOCK_NO_STOCK") % [station.stock, Products.display_name(station.product)]
		Station.Type.PREP:
			if worker.carrying == "caja":
				return Lang.t("BLOCK_DROP_BOX")
			if worker.carrying == "pedido":
				return Lang.t("BLOCK_ORDER_READY")
			if worker.carrying == "":
				return Lang.t("BLOCK_PICK_FIRST")
			var missing_names := []
			for id: String in get_missing_products(worker):
				missing_names.append(Products.display_name(id))
			if not missing_names.is_empty():
				return Lang.t("BLOCK_MISSING") % ", ".join(missing_names)
		Station.Type.DISPATCH:
			if worker.carrying == "caja":
				return Lang.t("BLOCK_DROP_BOX")
			if worker.carrying == "productos":
				return Lang.t("BLOCK_PACK_FIRST")
			if worker.carrying != "pedido":
				return Lang.t("BLOCK_NEED_PACKED")
		Station.Type.RECEIVING:
			if worker.carrying == "caja":
				return ""   # la devuelve
			if worker.carrying != "":
				return Lang.t("BLOCK_HANDS_FULL")
			if reception_boxes.is_empty():
				return Lang.t("BLOCK_NO_BOXES")
	return ""


func get_action_name(worker, station: Station) -> String:
	match station.type:
		Station.Type.SHELF:
			if worker.carrying == "caja":
				var amount := mini(worker.items[station.product], station.capacity - station.stock)
				return Lang.t("ACTION_RESTOCK") % [Products.display_name(station.product), amount]
			return Lang.t("ACTION_PICK") % Products.describe(station.product, worker.order["items"].get(station.product, 0))
		Station.Type.PREP:
			return Lang.t("ACTION_PACK")
		Station.Type.DISPATCH:
			return Lang.t("ACTION_DELIVER")
		Station.Type.RECEIVING:
			if worker.carrying == "caja":
				return Lang.t("ACTION_RETURN_BOX")
			return Lang.t("ACTION_TAKE_BOX") % Products.display_name(_best_box()["product"])
	return ""


## Aplica la acción de la estación. Los mensajes grandes solo salen para el jugador.
func use_station(worker, station: Station) -> void:
	if phase != "playing" or get_blocked_reason(worker, station) != "":
		return
	var is_player: bool = worker == player
	match station.type:
		Station.Type.SHELF:
			if worker.carrying == "caja":
				# reponer: entra lo que quepa, el resto se queda en la caja
				var in_box: int = worker.items[station.product]
				var amount := mini(in_box, station.capacity - station.stock)
				station.stock += amount
				if amount == in_box:
					worker.items = {}
					worker.carrying = ""
				else:
					worker.items = {station.product: in_box - amount}
				return
			var quantity: int = worker.order["items"][station.product]
			if config["supplier"]:
				station.stock -= quantity
			var new_items: Dictionary = worker.items.duplicate()
			new_items[station.product] = quantity
			worker.items = new_items
			worker.carrying = "productos"
			if is_player:
				hud.show_message("+" + Products.describe(station.product, quantity), Products.INFO[station.product]["color"].lightened(0.3))
		Station.Type.PREP:
			worker.items = {}
			worker.carrying = "pedido"
			if is_player:
				hud.show_message(Lang.t("MSG_ORDER_PACKED"), Color(1.0, 0.85, 0.4))
		Station.Type.DISPATCH:
			worker.carrying = ""
			_complete_order(worker)
		Station.Type.RECEIVING:
			if worker.carrying == "caja":
				var product: String = worker.items.keys()[0]
				reception_boxes.append({"product": product, "qty": worker.items[product]})
				worker.items = {}
				worker.carrying = ""
			else:
				var box := _best_box()
				reception_boxes.erase(box)
				worker.items = {box["product"]: box["qty"]}
				worker.carrying = "caja"
			_sync_reception()


func _on_player_interact() -> void:
	_update_current_station()
	if _hold_candidate() != null:
		return   # preparar y reparar se hacen manteniendo E (ver _update_hold)
	if current_station == null:
		return
	var reason := get_blocked_reason(player, current_station)
	if reason != "":
		hud.show_message(reason, Color(1.0, 0.5, 0.4))
	else:
		use_station(player, current_station)


# --- Estación cercana y flecha de objetivo -----------------------------------

func _update_current_station() -> void:
	var nearest: Station = null
	var nearest_distance := INF
	for station: Station in get_tree().get_nodes_in_group("stations"):
		if not station.is_interactive() or not station.is_in_range(player.global_position):
			continue
		var distance := station.global_position.distance_to(player.global_position)
		if distance < nearest_distance:
			nearest = station
			nearest_distance = distance

	current_station = nearest
	for station: Station in get_tree().get_nodes_in_group("stations"):
		station.highlighted = station == current_station
		station.is_target = phase == "playing" and _is_target(station)


## True si es un lugar al que el jugador debe ir ahora (muestra la flecha).
func _is_target(station: Station) -> bool:
	if player.carrying == "caja":
		return station.type == Station.Type.SHELF and player.items.has(station.product)
	if player.order.is_empty():
		return false
	if player.carrying == "pedido":
		return station.type == Station.Type.DISPATCH
	var missing := get_missing_products(player)
	if missing.is_empty():
		return station.type == Station.Type.PREP
	return station.type == Station.Type.SHELF and station.product in missing


# --- Paredes (colisiones) ----------------------------------------------------

func _wall_rects() -> Array[Rect2]:
	var t := WALL_THICKNESS
	return [
		Rect2(0, 0, room_size.x, t),
		Rect2(0, room_size.y - t, room_size.x, t),
		Rect2(0, 0, t, room_size.y),
		Rect2(room_size.x - t, 0, t, room_size.y),
	]


## Crea las colisiones de las 4 paredes. El dibujo de las paredes está en scenery.gd.
func _build_walls() -> void:
	for wall: Rect2 in _wall_rects():
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = wall.size
		var collision := CollisionShape2D.new()
		collision.shape = rect_shape
		var body := StaticBody2D.new()
		body.position = wall.get_center()
		body.add_child(collision)
		add_child(body)
