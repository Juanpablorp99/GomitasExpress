class_name PathGrid
extends RefCounted
## BÚSQUEDA DE CAMINOS (A*) para los robots.
## Divide el almacén en una cuadrícula de celdas de CELL píxeles, marca como bloqueadas
## las que tocan paredes, estanterías o decoración sólida, y usa AStarGrid2D de Godot
## para encontrar el camino más corto esquivando obstáculos.

const CELL := 32.0
const ROBOT_RADIUS := 22.0   # los obstáculos se agrandan esto para que el robot no los roce

var _grid := AStarGrid2D.new()


## `room`: tamaño del almacén · `solids`: rectángulos bloqueados (en coordenadas del nivel).
func build(room: Vector2, solids: Array[Rect2]) -> void:
	_grid.region = Rect2i(0, 0, ceili(room.x / CELL), ceili(room.y / CELL))
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.offset = Vector2(CELL / 2, CELL / 2)   # los puntos del camino son el centro de cada celda
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for rect in solids:
		var grown := rect.grow(ROBOT_RADIUS)
		var from := _to_cell(grown.position)
		var to := _to_cell(grown.end)
		for x in range(from.x, to.x + 1):
			for y in range(from.y, to.y + 1):
				var cell := Vector2i(x, y)
				if _grid.is_in_boundsv(cell) and grown.has_point(_grid.get_point_position(cell)):
					_grid.set_point_solid(cell, true)


## Camino de `from` a `to` esquivando obstáculos. Si `to` está bloqueado, va a la celda
## libre más cercana. Devuelve los puntos por los que hay que pasar (sin el inicio).
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := _nearest_free(_to_cell(from))
	var goal := _nearest_free(_to_cell(to))
	var path := _grid.get_point_path(start, goal, true)
	if path.size() > 0:
		path.remove_at(0)
	if not _grid.is_point_solid(_to_cell(to)):
		path.append(to)   # termina justo en el destino si está libre
	return path


## Longitud del camino (para que la IA estime cuánto tardará un robot).
func path_length(from: Vector2, to: Vector2) -> float:
	var total := 0.0
	var previous := from
	for point in find_path(from, to):
		total += previous.distance_to(point)
		previous = point
	return total


func _to_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i(floori(point.x / CELL), floori(point.y / CELL))
	return cell.clamp(_grid.region.position, _grid.region.end - Vector2i.ONE)


## La celda libre más cercana (busca en anillos alrededor).
func _nearest_free(cell: Vector2i) -> Vector2i:
	if not _grid.is_point_solid(cell):
		return cell
	for radius in range(1, 12):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, y)
				if _grid.is_in_boundsv(candidate) and not _grid.is_point_solid(candidate):
					return candidate
	return cell
