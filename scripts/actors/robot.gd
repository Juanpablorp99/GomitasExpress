class_name Robot
extends Node2D
## Robot (Niveles 2 y 3): toma un pedido libre del tablero (o el que le asigne el jugador)
## y lo completa solo: estantería(s) -> preparación -> camión -> +$.
## Usa las mismas reglas que el jugador: warehouse.get_blocked_reason() / use_station().
## Qué pedido toma lo decide warehouse.take_free_order(): en el Nivel 3 con la IA de
## task_ai.gd (urgencia, tiempo de espera, distancia, valor y otros robots).
## Para moverse usa búsqueda de caminos A* (path_grid.gd) y así esquiva los obstáculos.
## A veces se ATASCA y el jugador tiene que ir a repararlo (mantener E).

const WORK_TIME := 0.8     # segundos que tarda en cada estantería y en el camión
const PACK_TIME := 2.2     # segundos que tarda en preparar (más que el jugador)
const REST_TIME := 1.5     # segundos de descanso en la base entre pedidos
const BREAKDOWN_EVERY := [25.0, 45.0]   # cada cuántos segundos de trabajo se atasca

@export var speed := 130.0

var warehouse: Node   # el nivel (warehouse.gd), lo asigna quien crea el robot
var robot_name := "ROBOT"
## Mismo contrato que Player: pedido asignado, lo que lleva y los productos sueltos.
var order := {}
var carrying := ""
var items := {}
## Qué está haciendo: clave de lang.gd (ROBOT_...) y el producto si lo hay.
var status_key := "ROBOT_WAITING"
var status_product := ""
## Última decisión de la IA: { "number": pedido elegido, "score": puntaje } (Nivel 3).
var ai_choice := {}
## Atascado: no se mueve hasta que el jugador lo repare.
var broken := false
## Progreso de reparación (0..1) para dibujarlo. Lo pone warehouse.gd.
var repair_ratio := 0.0

var _home := Vector2.ZERO
var _steps: Array = []   # [{ "pos": Vector2, "station": Station (null = base), "product": String, "status": String }]
var _path := PackedVector2Array()   # puntos del camino A* hacia el paso actual
var _path_goal := Vector2.INF
var _wait := 0.0
var _until_breakdown := 0.0
var _float_text := ""
var _float_time := 0.0
var _facing := "front"   # "front", "side" o "back"
var _moving := false
var _sprite: AnimatedSprite2D

## Animaciones: nombre -> [poses (assets/characters/robot/), cuadros por segundo].
## De lado mira a la derecha y se voltea para la izquierda.
const ANIMATIONS := {
	"roll_front": [["front_0", "front_1"], 6.0],
	"roll_side": [["side_0", "side_1"], 6.0],
	"roll_back": [["back_0", "back_1"], 6.0],
	"carry": [["carry"], 1.0],
	"broken": [["broken"], 1.0],
}
const ITEMS_LIFT := -30.0   # lo que lleva se dibuja más arriba (el robot es alto)


func _ready() -> void:
	add_to_group("robots")
	_home = position
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation: String in ANIMATIONS:
		frames.add_animation(animation)
		frames.set_animation_speed(animation, ANIMATIONS[animation][1])
		for pose: String in ANIMATIONS[animation][0]:
			frames.add_frame(animation, Art.robot_pose(pose))
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2(0.75, 0.75)
	_sprite.position = Vector2(0, -36)   # las ruedas quedan en el centro del robot
	_sprite.show_behind_parent = true      # lo que lleva se dibuja encima
	add_child(_sprite)
	_sprite.play("roll_front")
	_wait = 0.5
	_until_breakdown = randf_range(BREAKDOWN_EVERY[0], BREAKDOWN_EVERY[1])


func _process(delta: float) -> void:
	_float_time = maxf(_float_time - delta, 0.0)
	queue_redraw()
	_update_animation()
	_moving = false   # _follow_path() lo vuelve a poner en true si avanza este frame
	if broken:
		status_key = "ROBOT_BROKEN"
		return
	if not order.is_empty() and warehouse.config["breakdowns"]:
		_until_breakdown -= delta
		if _until_breakdown <= 0.0:
			_break_down()
			return
	if _wait > 0.0:
		_wait -= delta
		return
	if _steps.is_empty():
		# si consigue un pedido, on_order_changed() arma la ruta
		if order.is_empty() and not warehouse.take_free_order(self):
			status_key = "ROBOT_NO_STOCK" if warehouse.has_free_orders() else "ROBOT_WAITING"
		return

	var step: Dictionary = _steps[0]
	status_key = step["status"]
	status_product = step["product"]
	_follow_path(step["pos"], delta)
	if position == step["pos"]:
		_steps.pop_front()   # antes de _arrive(): al entregar se rehace la ruta
		_arrive(step)


## Avanza por el camino A* hacia `goal` (lo recalcula si cambió el destino).
func _follow_path(goal: Vector2, delta: float) -> void:
	if goal != _path_goal:
		_path_goal = goal
		_path = warehouse.find_path(position, goal)
		if _path.is_empty():
			_path.append(goal)
	var target: Vector2 = _path[0]
	_face(target - position)
	position = position.move_toward(target, speed * delta)
	_moving = true
	if position == target and _path.size() > 1:
		_path.remove_at(0)
	elif position == target and target != goal:
		_path[0] = goal   # último tramo: termina justo en el destino


## Lo llama warehouse.gd al asignarle o quitarle un pedido: rehace la ruta
## con lo que le falta (sin pedido, vuelve a la base).
func on_order_changed() -> void:
	_steps.clear()
	_path_goal = Vector2.INF
	if order.is_empty():
		ai_choice = {}
		_add_step(_home, null, "ROBOT_RETURNING")
		return
	if carrying != "pedido":
		for id: String in order["items"]:
			if items.has(id):
				continue
			var shelf: Station = warehouse.get_shelf(id)
			_add_step(_front_of(shelf, randf_range(-50, 50)), shelf, "ROBOT_PICKING", id)
		var prep: Station = warehouse.get_station_of_type(Station.Type.PREP)
		_add_step(_front_of(prep, randf_range(-60, 60)), prep, "ROBOT_PACKING")
	var dispatch: Station = warehouse.get_station_of_type(Station.Type.DISPATCH)
	_add_step(dispatch.global_position + Vector2(randf_range(-80, 80), 30), dispatch, "ROBOT_DELIVERING")


## Punto justo debajo de una estación (por donde se le acerca).
func _front_of(station: Station, x_offset: float) -> Vector2:
	return station.global_position + Vector2(x_offset, station.size.y / 2 + 34)


func _add_step(pos: Vector2, station: Station, status: String, product := "") -> void:
	_steps.append({"pos": pos, "station": station, "status": status, "product": product})


func _arrive(step: Dictionary) -> void:
	var station: Station = step["station"]
	if station == null:   # llegó a la base
		status_key = "ROBOT_RESTING"
		_wait = REST_TIME
		return
	if warehouse.is_out_of_stock(self, station):
		status_key = "ROBOT_NO_STOCK"
		_steps.push_front(step)   # espera junto a la estantería y vuelve a intentar
		_wait = 1.0
		return
	_wait = PACK_TIME if station.type == Station.Type.PREP else WORK_TIME
	if warehouse.get_blocked_reason(self, station) != "":
		on_order_changed()   # el pedido cambió por el camino: rehace la ruta
		return
	warehouse.use_station(self, station)
	if station.type == Station.Type.DISPATCH:
		_float_text = "+$%d" % warehouse.last_payment
		_float_time = 1.5


func _break_down() -> void:
	broken = true
	warehouse.on_robot_broken(self)


## Lo llama warehouse.gd cuando el jugador termina de repararlo.
func repair() -> void:
	broken = false
	repair_ratio = 0.0
	_until_breakdown = randf_range(BREAKDOWN_EVERY[0], BREAKDOWN_EVERY[1])


## Mira hacia donde avanza: de lado (volteando para la izquierda), de frente o de espaldas.
func _face(direction: Vector2) -> void:
	if direction.length() < 0.5:
		return
	if absf(direction.x) > absf(direction.y):
		_facing = "side"
		_sprite.flip_h = direction.x < 0.0
	else:
		_facing = "back" if direction.y < 0.0 else "front"
		_sprite.flip_h = false


## Descompuesto, cargando el pedido, o rodando hacia donde mira (quieto = sin animar).
func _update_animation() -> void:
	var animation := "roll_" + _facing
	if broken:
		animation = "broken"
	elif carrying == "pedido":
		animation = "carry"
	if _sprite.animation != animation:
		_sprite.play(animation)
	if _moving or broken:
		_sprite.play()
	else:
		_sprite.pause()


func _draw() -> void:
	Products.draw_carried(self, carrying, items, ITEMS_LIFT, false)
	var font := ThemeDB.fallback_font
	var who := robot_name if order.is_empty() else "%s #%03d" % [robot_name, order["number"]]
	var label := "%s: %s" % [who, get_status_text()]
	var label_color := Color(1, 0.45, 0.4) if broken else Color(0.75, 0.95, 1.0)
	draw_string_outline(font, Vector2(-150, 44), label, HORIZONTAL_ALIGNMENT_CENTER, 300, 13, 4, Color.BLACK)
	draw_string(font, Vector2(-150, 44), label, HORIZONTAL_ALIGNMENT_CENTER, 300, 13, label_color)
	if not ai_choice.is_empty() and not broken:
		var ai_text := Lang.t("ROBOT_AI_CHOICE") % [ai_choice["number"], ai_choice["score"]]
		draw_string_outline(font, Vector2(-150, 60), ai_text, HORIZONTAL_ALIGNMENT_CENTER, 300, 12, 4, Color.BLACK)
		draw_string(font, Vector2(-150, 60), ai_text, HORIZONTAL_ALIGNMENT_CENTER, 300, 12, Color(1, 0.85, 0.35))
	if broken:
		# alerta encima (la imagen del robot descompuesto ya tiene chispas y humo)
		var bob := sin(Time.get_ticks_msec() / 150.0) * 4.0
		Art.draw_centered(self, Art.ALERT, Vector2(0, -96 + bob), Vector2(36, 36))
		if repair_ratio > 0.0:
			draw_arc(Vector2(0, -24), 46, -PI / 2, -PI / 2 + TAU * repair_ratio, 32, Color(0.4, 1, 0.5), 6)
	if _float_time > 0.0:
		var y := -70.0 - (1.5 - _float_time) * 20.0
		draw_string_outline(font, Vector2(-50, y), _float_text, HORIZONTAL_ALIGNMENT_CENTER, 100, 24, 6, Color.BLACK)
		draw_string(font, Vector2(-50, y), _float_text, HORIZONTAL_ALIGNMENT_CENTER, 100, 24, Color(0.4, 1, 0.45))


## Texto de estado en el idioma actual, por ejemplo "Recogiendo OSOS" / "Picking BEARS".
func get_status_text() -> String:
	if status_key == "ROBOT_PICKING":
		return Lang.t(status_key) % Products.display_name(status_product)
	return Lang.t(status_key)
