class_name TaskAI
## IA DE ASIGNACIÓN DE TAREAS de los robots (Nivel 3).
##
## Cuando un robot queda libre, revisa TODOS los pedidos libres del tablero, le da un
## PUNTAJE a cada uno y toma el de mayor puntaje (decisión dinámica, no una ruta fija):
##
##   puntaje = BASE
##           + W_URGENCY  * urgencia     (0..1: cuánto del tiempo de espera ya se gastó)
##           + W_URGENT   * urgente      (1 si el pedido es URGENTE)
##           + W_VALUE    * valor        (recompensa, normalizada 0..1)
##           - W_DISTANCE * distancia    (del robot a la primera estantería, normalizada 0..1)
##           - W_SIZE     * tamaño       (cuántas gomitas distintas hay que recoger)
##           - W_OTHER_ROBOT             (si otro robot libre está más cerca de ese pedido)
##
## Además descarta los pedidos que:
##   - no tienen stock suficiente en las estanterías, o
##   - el robot NO alcanzaría a entregar antes de que se acabe la paciencia del cliente
##     (calculado con el camino real A* que esquiva obstáculos, ver path_grid.gd).
##
## Así cumple los criterios del proyecto: pedidos pendientes, tiempo de espera,
## distancia, disponibilidad de robots y prioridad de cada pedido.

const BASE := 1.5   # solo para que los puntajes salgan positivos (no cambia la decisión)
const W_URGENCY := 1.5
const W_URGENT := 0.8
const W_VALUE := 0.5
const W_DISTANCE := 1.0
const W_SIZE := 0.15
const W_OTHER_ROBOT := 0.6

const MAX_DISTANCE := 2600.0   # para normalizar la distancia (ancho del almacén grande)
const MAX_REWARD := 60.0       # para normalizar el valor del pedido


## El mejor pedido para `robot`: { "order": Dictionary, "score": float }, o {} si no conviene ninguno.
static func choose_order(game: Node, robot: Node) -> Dictionary:
	var best := {}
	var best_score := -INF
	for order: Dictionary in game.orders:
		if order["owner"] != null or not game.can_fulfill(order):
			continue
		if estimate_time(game, robot, order) > order["time_left"]:
			continue   # no llegaría a tiempo: mejor dejarlo para otro
		var s := score(game, robot, order)
		if s > best_score:
			best_score = s
			best = {"order": order, "score": s}
	return best


## Puntaje de `order` para `robot` (más alto = más conveniente).
static func score(game: Node, robot: Node, order: Dictionary) -> float:
	var urgency: float = 1.0 - order["time_left"] / order["time_total"]
	var value: float = minf(order["reward"] / MAX_REWARD, 1.0)
	var first_stop := _first_stop(game, order)
	var distance: float = robot.position.distance_to(first_stop) / MAX_DISTANCE
	var size: float = order["items"].size()

	var s := BASE + W_URGENCY * urgency + W_VALUE * value - W_DISTANCE * distance - W_SIZE * size
	if order["urgent"]:
		s += W_URGENT
	# disponibilidad: si otro robot libre está más cerca, que lo tome ese
	for other: Node in game.robots:
		if other != robot and other.order.is_empty() and other.carrying == "" and not other.broken:
			if other.position.distance_to(first_stop) / MAX_DISTANCE < distance:
				s -= W_OTHER_ROBOT
				break
	return s


## Mejor puntaje que le daría algún robot a `order` (para mostrarlo en el tablero).
static func best_score(game: Node, order: Dictionary) -> float:
	var best := -INF
	for robot: Node in game.robots:
		best = maxf(best, score(game, robot, order))
	return best


## Segundos estimados para completar el pedido: largo del camino A* / velocidad
## + el tiempo de trabajo en cada parada.
static func estimate_time(game: Node, robot: Node, order: Dictionary) -> float:
	var stops: Array[Vector2] = []
	for id: String in order["items"]:
		stops.append(game.get_shelf(id).global_position)
	stops.append(game.get_station_of_type(Station.Type.PREP).global_position)
	stops.append(game.get_station_of_type(Station.Type.DISPATCH).global_position)
	var total := 0.0
	var pos: Vector2 = robot.position
	for stop in stops:
		total += game.path_length(pos, stop)
		pos = stop
	return total / robot.speed + (stops.size() - 1) * robot.WORK_TIME + robot.PACK_TIME


static func _first_stop(game: Node, order: Dictionary) -> Vector2:
	var first_product: String = order["items"].keys()[0]
	return game.get_shelf(first_product).global_position
