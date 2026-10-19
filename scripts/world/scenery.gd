extends Node2D
## Decoración del nivel: exterior, suelo, paredes con puertas de carga, carriles de
## montacargas, hielo, derrames y objetos (palés, barriles, plantas...).
## Cada nivel elige un estilo con `style`:
##   "bodega" (Nivel 1, de día, madera y ladrillo)
##   "noche"  (Nivel 2, centro de distribución de noche, ver también lighting.gd)
##   "nieve"  (Nivel 3, invierno con hielo)
## Los colores de cada estilo están en STYLES y la decoración de cada uno en LAYOUTS.
## Los objetos marcados como sólidos tienen colisión (el jugador choca y los robots los esquivan).
## Las imágenes vienen de Art (scripts/data/art.gd).
##
## Lo que no se mueve se dibuja una sola vez (_draw); lo animado (cinta, luces, nieve,
## derrames, camión del proveedor) se redibuja cada frame en un nodo aparte (_fx).
## Va como primer hijo del nivel para quedar debajo de todo lo demás.

const WALL := 40.0
const FINI_RED := Color(0.85, 0.12, 0.2)

## Colores de cada estilo.
## ground/spots: césped, tierra o nieve de afuera · floor: suelo del almacén
## planks: true = tablones de madera, false = baldosas · wall/brick: paredes
## light: luz de las lámparas · lane: color del pasillo de montacargas · tree: árboles
const STYLES := {
	"bodega": {
		"ground": Color(0.34, 0.56, 0.3), "spots": [Color(0.4, 0.64, 0.34), Color(0.28, 0.48, 0.26)],
		"sidewalk": Color(0.72, 0.7, 0.66), "road": Color(0.24, 0.24, 0.26),
		"floor": Color(0.62, 0.44, 0.28), "planks": true, "tile": 64,
		"wall": Color(0.55, 0.25, 0.2), "brick": true,
		"light": Color(1, 0.92, 0.75, 0.04), "tree": Art.TREE, "snow": false, "night": false,
	},
	"noche": {
		"ground": Color(0.07, 0.09, 0.11), "spots": [Color(0.1, 0.12, 0.14), Color(0.05, 0.06, 0.08)],
		"sidewalk": Color(0.2, 0.21, 0.24), "road": Color(0.1, 0.1, 0.12),
		"floor": Color(0.26, 0.29, 0.35), "planks": false, "tile": 160,
		"wall": Color(0.16, 0.18, 0.24), "brick": false,
		"light": Color(0.7, 0.85, 1.0, 0.0), "tree": Art.TREE, "snow": false, "night": true,
	},
	"nieve": {
		"ground": Color(0.92, 0.95, 0.99), "spots": [Color(1, 1, 1), Color(0.82, 0.88, 0.96)],
		"sidewalk": Color(0.8, 0.84, 0.9), "road": Color(0.3, 0.32, 0.36),
		"floor": Color(0.66, 0.71, 0.78), "planks": false, "tile": 80,
		"wall": Color(0.4, 0.45, 0.55), "brick": false,
		"light": Color(0.9, 0.97, 1.0, 0.045), "tree": Art.TREE_SNOW, "snow": true, "night": false,
	},
}

## Decoración de cada estilo (va con la distribución de su escena de nivel).
## logo: centro del logo FINI del suelo · conveyor: cinta transportadora (sólida)
## pallets: [centro, cajas encima] (sólidos)
## props: [imagen, centro, tamaño, sólido, color] (el color tiñe; blanco = sin teñir)
const LAYOUTS := {
	"bodega": {
		"logo": Vector2(878, 739),
		"conveyor": Rect2(1353, 378, 44, 236),
		"pallets": [[Vector2(1345, 119), 3], [Vector2(111, 511), 4]],
		"props": [
			[Art.FORKLIFT, Vector2(95, 637), Vector2(120, 60), true, Color.WHITE],
			[Art.PLANT, Vector2(72, 75), Vector2(56, 56), true, Color.WHITE],
			[Art.PLANT, Vector2(902, 75), Vector2(56, 56), true, Color.WHITE],
			[Art.PLANT, Vector2(72, 889), Vector2(56, 56), true, Color.WHITE],
			[Art.BARREL, Vector2(950, 873), Vector2(50, 50), true, Color.WHITE],
			[Art.BARREL, Vector2(989, 881), Vector2(50, 50), true, Color.WHITE],
			[Art.SHELF, Vector2(720, 881), Vector2(84, 84), true, Color.WHITE],
		],
	},
	"noche": {
		"logo": Vector2(1040, 1074),
		"conveyor": Rect2(1556, 419, 44, 379),
		"pallets": [[Vector2(1984, 119), 3], [Vector2(1984, 222), 4], [Vector2(127, 522), 3], [Vector2(1437, 522), 0]],
		"props": [
			[Art.FORKLIFT, Vector2(1500, 1190), Vector2(120, 60), true, Color.WHITE],
			[Art.PLANT, Vector2(72, 76), Vector2(56, 56), true, Color.WHITE],
			[Art.BARREL, Vector2(707, 1074), Vector2(50, 50), true, Color.WHITE],
			[Art.BARREL, Vector2(746, 1082), Vector2(50, 50), true, Color.WHITE],
			[Art.BARREL, Vector2(727, 1118), Vector2(50, 50), true, Color.WHITE],
			[Art.CONE, Vector2(1556, 916), Vector2(40, 40), true, Color.WHITE],
			[Art.CONE, Vector2(1592, 916), Vector2(40, 40), true, Color.WHITE],
			[Art.TRASH, Vector2(1977, 1193), Vector2(52, 52), true, Color.WHITE],
			[Art.SHELF, Vector2(484, 1177), Vector2(84, 84), true, Color.WHITE],
		],
	},
	"nieve": {
		"logo": Vector2(1357, 1074),
		"conveyor": Rect2(1715, 419, 44, 379),
		"pallets": [[Vector2(1984, 119), 3], [Vector2(127, 522), 3], [Vector2(1437, 522), 0]],
		"props": [
			[Art.FORKLIFT, Vector2(1500, 1190), Vector2(120, 60), true, Color.WHITE],
			[Art.BARREL, Vector2(564, 1114), Vector2(50, 50), true, Color.WHITE],
			[Art.BARREL, Vector2(603, 1122), Vector2(50, 50), true, Color.WHITE],
			[Art.CONE, Vector2(1556, 987), Vector2(40, 40), true, Color.WHITE],
			[Art.CONE, Vector2(1592, 987), Vector2(40, 40), true, Color.WHITE],
			[Art.TRASH, Vector2(1977, 1193), Vector2(52, 52), true, Color.WHITE],
			[Art.SHELF, Vector2(453, 1185), Vector2(84, 84), true, Color.WHITE],
			[Art.SNOWMAN, Vector2(-103, 1035), Vector2(80, 80), false, Color.WHITE],
			[Art.SNOWMAN, Vector2(2230, 245), Vector2(80, 80), false, Color.WHITE],
			[Art.SNOWMAN, Vector2(564, -118), Vector2(80, 80), false, Color.WHITE],
		],
	},
}

const CAR_COLORS := [Color(0.9, 0.2, 0.25), Color(0.25, 0.5, 0.95), Color(0.95, 0.95, 0.95),
		Color(0.2, 0.2, 0.22), Color(1.0, 0.8, 0.2), Color(0.3, 0.75, 0.4)]

@export_enum("bodega", "noche", "nieve") var style := "bodega"

## Rectángulos de la decoración sólida (los usa la búsqueda de caminos de los robots).
var solid_rects: Array[Rect2] = []

var _config: Dictionary
var _room: Rect2
var _outside: Rect2
var _door_right: Rect2       # puerta de carga junto a DESPACHO
var _door_bottom: Rect2      # puerta de carga junto a RECEPCIÓN (o al centro)
var _time := 0.0
var _tile_tints: Array[float] = []
var _ground_spots: Array[Dictionary] = []
var _trees: Array[Vector2] = []
var _snowflakes: Array[Vector3] = []   # x, y, velocidad
var _fx: Node2D

@onready var warehouse: Node = get_parent()


func _ready() -> void:
	_config = Levels.get_config(warehouse.level_number)
	_room = Rect2(Vector2.ZERO, _config["room"])
	_outside = _room.grow(700)
	_place_doors()
	_build_solids()
	_generate_random_details()
	# capa animada: se dibuja encima del suelo y debajo de estanterías y personajes
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)


func _process(delta: float) -> void:
	_time += delta
	_fx.queue_redraw()


## Las puertas de carga se alinean con DESPACHO y RECEPCIÓN de la escena.
func _place_doors() -> void:
	var stations := warehouse.get_node("Stations")
	var dispatch: Node2D = stations.get_node("Dispatch")
	_door_right = Rect2(_room.end.x - WALL, dispatch.position.y - 80, WALL, 160)
	var reception: Node2D = stations.get_node_or_null("Reception")
	var door_x: float = reception.position.x if reception != null else _room.size.x / 2
	_door_bottom = Rect2(door_x - 80, _room.end.y - WALL, 160, WALL)


## Colisiones de la decoración (palés, objetos sólidos y cinta transportadora).
func _build_solids() -> void:
	var layout: Dictionary = LAYOUTS[style]
	for pallet: Array in layout["pallets"]:
		_add_solid(Rect2(pallet[0] - Vector2(46, 40), Vector2(92, 80)))
	for prop: Array in layout["props"]:
		if prop[3]:
			var size: Vector2 = prop[2] * 0.85
			_add_solid(Rect2(prop[1] - size / 2, size))
	_add_solid(layout["conveyor"])


func _add_solid(rect: Rect2) -> void:
	solid_rects.append(rect)
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)


## Datos "aleatorios" fijos (misma semilla = el escenario siempre se ve igual).
func _generate_random_details() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 600:
		_tile_tints.append(rng.randf_range(-0.03, 0.03))
	var building := _room.grow(150)
	while _ground_spots.size() < 220:
		var pos := Vector2(rng.randf_range(_outside.position.x, _outside.end.x), rng.randf_range(_outside.position.y, _room.end.y + 60))
		if not building.has_point(pos):
			_ground_spots.append({"pos": pos, "r": rng.randf_range(18, 60), "light": rng.randf() < 0.5})
	for x in range(int(_outside.position.x) + 120, int(_room.end.x) + 300, 190):
		_trees.append(Vector2(x + rng.randf_range(-30, 30), -230 + rng.randf_range(-60, 40)))
	if style != "noche":   # de noche a la izquierda hay un estacionamiento
		for y in range(80, int(_room.end.y) - 100, 210):
			_trees.append(Vector2(-260 + rng.randf_range(-50, 40), y + rng.randf_range(-30, 30)))
	if STYLES[style]["snow"]:
		for i in 320:
			_snowflakes.append(Vector3(rng.randf_range(_outside.position.x, _outside.end.x),
					rng.randf_range(_outside.position.y, _outside.end.y), rng.randf_range(30, 70)))


# === Parte fija ================================================================

func _draw() -> void:
	var colors: Dictionary = STYLES[style]
	var layout: Dictionary = LAYOUTS[style]
	_draw_outside(colors)
	_draw_floor(colors, layout)
	_draw_forklift_lanes()
	_draw_ice()
	_draw_markings()
	_draw_decor(layout)
	_draw_walls(colors)


# --- Exterior ----------------------------------------------------------------

func _draw_outside(colors: Dictionary) -> void:
	draw_rect(_outside, colors["ground"])
	for spot in _ground_spots:
		draw_circle(spot["pos"], spot["r"], colors["spots"][0] if spot["light"] else colors["spots"][1])
	draw_rect(_room.grow(45), colors["sidewalk"])

	# carretera de abajo con línea amarilla discontinua (con bordes de nieve en invierno)
	var road := Rect2(_outside.position.x, _room.end.y + 90, _outside.size.x, 170)
	draw_rect(road, colors["road"])
	var edge := Color(0.95, 0.97, 1.0) if colors["snow"] else Color(0.85, 0.85, 0.85)
	var edge_width := 14.0 if colors["snow"] else 6.0
	draw_rect(Rect2(road.position.x, road.position.y, road.size.x, edge_width), edge)
	draw_rect(Rect2(road.position.x, road.end.y - edge_width, road.size.x, edge_width), edge)
	for x in range(int(road.position.x), int(road.end.x), 90):
		draw_rect(Rect2(x, road.get_center().y - 3, 50, 6), Color(1, 0.8, 0.2))

	# patio de carga a la derecha (camión de despacho) y entrada a la puerta de abajo
	var yard := Rect2(_room.end.x + 45, _door_right.get_center().y - 260, 480, 0)
	yard.end.y = road.position.y
	draw_rect(yard, colors["road"].lightened(0.05))
	for y in range(int(yard.position.y) + 40, int(yard.end.y), 120):
		draw_line(Vector2(yard.position.x + 20, y), Vector2(yard.end.x, y), Color(0.9, 0.9, 0.9, 0.7), 4)
	draw_rect(Rect2(_door_bottom.position.x - 20, _room.end.y + 45, 200, 50), colors["road"].lightened(0.05))

	if colors["night"]:
		_draw_parking()

	# camión Fini en el andén de despacho (la parte trasera toca la puerta)
	var truck_size := Vector2(380, 380.0 * Art.TRUCK_FINI.get_height() / Art.TRUCK_FINI.get_width())
	var fini_truck := Rect2(Vector2(_room.end.x + 50, _door_right.get_center().y - truck_size.y / 2), truck_size)
	draw_texture_rect(Art.TRUCK_FINI, fini_truck, false)
	# el logo va en el panel blanco de la caja del camión
	_draw_label(Rect2(fini_truck.position + truck_size * Vector2(0.02, 0.03), truck_size * Vector2(0.62, 0.39)), "FINI", 56, FINI_RED)

	for tree in _trees:
		Art.draw_centered(self, colors["tree"], tree, Vector2(128, 128), Color(0.45, 0.5, 0.6) if colors["night"] else Color.WHITE)
	for prop: Array in LAYOUTS[style]["props"]:
		if not _room.has_point(prop[1]):
			Art.draw_centered(self, prop[0], prop[1], prop[2], prop[4])


## Estacionamiento con autos a la izquierda del edificio (nivel de noche).
func _draw_parking() -> void:
	var lot := Rect2(-470, 40, 380, _room.size.y - 80)
	draw_rect(lot, Color(0.12, 0.13, 0.15))
	draw_rect(lot, Color(0.6, 0.6, 0.6), false, 4)
	var rows := int(lot.size.y / 112)
	for i in rows:
		var y := lot.position.y + 30 + i * 112
		draw_line(Vector2(lot.position.x, y), Vector2(lot.position.x + 130, y), Color(1, 1, 1, 0.6), 3)
		draw_line(Vector2(lot.end.x - 130, y), Vector2(lot.end.x, y), Color(1, 1, 1, 0.6), 3)
		if i % 3 != 2:
			Art.draw_centered(self, Art.CAR, Vector2(lot.position.x + 65, y + 56), Vector2(60, 104), CAR_COLORS[i % CAR_COLORS.size()].darkened(0.4))
		if i % 4 != 1:
			Art.draw_centered(self, Art.CAR, Vector2(lot.end.x - 65, y + 56), Vector2(60, 104), CAR_COLORS[(i + 3) % CAR_COLORS.size()].darkened(0.4))


## Texto centrado dentro de `rect` (para los letreros de los camiones).
func _draw_label(rect: Rect2, text: String, font_size: int, color: Color) -> void:
	var y := rect.get_center().y + font_size * 0.35
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, y), text,
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)


# --- Suelo -------------------------------------------------------------------

func _draw_floor(colors: Dictionary, layout: Dictionary) -> void:
	var base: Color = colors["floor"]
	var tile: int = colors["tile"]
	if colors["planks"]:
		# tablones de madera desplazados como un piso de bodega
		var plank := Vector2(tile * 3, tile * 0.5)
		var rows := ceili(_room.size.y / plank.y)
		for row in rows:
			var shift := (row % 3) * plank.x / 3
			var x := -shift
			var i := 0
			while x < _room.size.x:
				var tint := _tile_tints[(row * 31 + i) % _tile_tints.size()] * 2.0
				var board := Rect2(x, row * plank.y, plank.x, plank.y).intersection(_room)
				if board.has_area():
					draw_rect(board, Color(base.r + tint, base.g + tint, base.b + tint))
				if x > 0.0:
					draw_line(Vector2(x, row * plank.y), Vector2(x, minf((row + 1) * plank.y, _room.size.y)), base.darkened(0.35), 2)
				x += plank.x
				i += 1
			draw_line(Vector2(0, row * plank.y), Vector2(_room.size.x, row * plank.y), base.darkened(0.3), 2)
	else:
		var cols := ceili(_room.size.x / tile)
		var rows := ceili(_room.size.y / tile)
		for i in cols * rows:
			var rect := Rect2((i % cols) * tile, floori(float(i) / cols) * tile, tile, tile)
			var tint := _tile_tints[i % _tile_tints.size()]
			draw_rect(rect, Color(base.r + tint, base.g + tint, base.b + tint))
		var grout := base.darkened(0.12)
		for x in range(0, int(_room.size.x), tile):
			draw_line(Vector2(x, 0), Vector2(x, _room.size.y), grout, 2)
		for y in range(0, int(_room.size.y), tile):
			draw_line(Vector2(0, y), Vector2(_room.size.x, y), grout, 2)

	# manchas de luz de las lámparas del techo (de noche las pone lighting.gd)
	if colors["light"].a > 0.0:
		for x in range(350, int(_room.size.x), 500):
			for y in range(300, int(_room.size.y), 450):
				for r in range(230, 40, -38):
					draw_circle(Vector2(x, y), r, colors["light"])

	# en invierno entra nieve por las puertas de carga
	if colors["snow"]:
		for door: Rect2 in [_door_right, _door_bottom]:
			var center := door.get_center()
			for i in 5:
				draw_circle(center + Vector2(sin(i * 2.1) * 40, cos(i * 1.7) * 40), 34 - i * 3, Color(1, 1, 1, 0.35))

	# logo de Fini pintado en el suelo
	var logo: Vector2 = layout["logo"]
	draw_circle(logo, 100, Color(FINI_RED, 0.25))
	draw_arc(logo, 100, 0, TAU, 64, Color(1, 1, 1, 0.35), 6)
	draw_arc(logo, 84, 0, TAU, 64, Color(1, 1, 1, 0.2), 3)
	draw_string(ThemeDB.fallback_font, logo + Vector2(-100, 18), "FINI",
			HORIZONTAL_ALIGNMENT_CENTER, 200, 54, Color(1, 1, 1, 0.4))


## Carril de cada montacargas con franjas de peligro a los lados.
func _draw_forklift_lanes() -> void:
	var forklifts := warehouse.get_node_or_null("Forklifts")
	if forklifts == null:
		return
	for forklift in forklifts.get_children():
		var route: PackedVector2Array = forklift.route
		for i in range(route.size() - 1):
			var a := route[i]
			var b := route[i + 1]
			var lane := Rect2(a, Vector2.ZERO).expand(b).grow(42)
			draw_rect(lane, Color(0.1, 0.1, 0.1, 0.25))
			if absf(a.y - b.y) < absf(a.x - b.x):   # carril horizontal
				_draw_hazard(Rect2(lane.position.x, lane.position.y, lane.size.x, 10))
				_draw_hazard(Rect2(lane.position.x, lane.end.y - 10, lane.size.x, 10))
			else:
				_draw_hazard(Rect2(lane.position.x, lane.position.y, 10, lane.size.y))
				_draw_hazard(Rect2(lane.end.x - 10, lane.position.y, 10, lane.size.y))


## Zonas de hielo resbaladizo (Nivel 3).
func _draw_ice() -> void:
	for rect: Rect2 in _config["ice"]:
		draw_rect(rect, Color(0.75, 0.92, 1.0, 0.75))
		draw_rect(rect, Color(1, 1, 1, 0.9), false, 3)
		for i in 6:
			var start := rect.position + Vector2(20 + i * rect.size.x / 6.0, 15 + (i % 3) * 30)
			draw_line(start, start + Vector2(28, 14), Color(1, 1, 1, 0.8), 3)


## Flechas de preparación a despacho y esquinas amarillas alrededor de las zonas de trabajo.
func _draw_markings() -> void:
	var yellow := Color(1, 0.82, 0.15, 0.85)
	var stations := warehouse.get_node("Stations")
	var prep: Node2D = stations.get_node("PrepTable")
	var dispatch: Node2D = stations.get_node("Dispatch")
	var from_y: float = prep.position.y + 120
	var to_y: float = dispatch.position.y - 150
	var y := from_y
	while y < to_y:
		_draw_chevron(Vector2(prep.position.x, y), Vector2.DOWN, Color(1, 1, 1, 0.45))
		y += 100
	for station in stations.get_children():
		if station.type == Station.Type.PREP:
			_draw_corners(Rect2(station.position - station.size / 2, station.size).grow(22), yellow)
	_draw_hazard(Rect2(_door_right.position.x - 70, _door_right.position.y, 60, _door_right.size.y))


func _draw_chevron(center: Vector2, dir: Vector2, color: Color) -> void:
	var side := dir.orthogonal()
	var tip := center + dir * 14
	draw_polyline(PackedVector2Array([tip - dir * 22 + side * 16, tip, tip - dir * 22 - side * 16]), color, 6)


func _draw_corners(rect: Rect2, color: Color) -> void:
	var l := 26.0
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var sx := 1.0 if corner.x == rect.position.x else -1.0
		var sy := 1.0 if corner.y == rect.position.y else -1.0
		draw_line(corner, corner + Vector2(l * sx, 0), color, 5)
		draw_line(corner, corner + Vector2(0, l * sy), color, 5)


## Rayas diagonales amarillas y negras recortadas al rectángulo.
func _draw_hazard(rect: Rect2) -> void:
	draw_rect(rect, Color(0.1, 0.1, 0.1, 0.8))
	var area := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var stripe := 14.0
	var span := maxf(rect.size.x, rect.size.y)
	var x := rect.position.x - span
	while x < rect.end.x + span:
		var band := PackedVector2Array([
			Vector2(x, rect.end.y), Vector2(x + stripe, rect.end.y),
			Vector2(x + stripe + rect.size.y, rect.position.y), Vector2(x + rect.size.y, rect.position.y)])
		for piece in Geometry2D.intersect_polygons(area, band):
			draw_colored_polygon(piece, Color(1, 0.8, 0.1, 0.9))
		x += stripe * 2


# --- Objetos decorativos -----------------------------------------------------

func _draw_decor(layout: Dictionary) -> void:
	for pallet: Array in layout["pallets"]:
		_draw_pallet(pallet[0], pallet[1])
	for prop: Array in layout["props"]:
		if _room.has_point(prop[1]):
			Art.draw_centered(self, prop[0], prop[1], prop[2], prop[4])
	# extintores y botiquín en las paredes
	var right := _room.end.x - 54
	for pos: Vector2 in [Vector2(54, 320), Vector2(right, 320), Vector2(420, _room.end.y - 64)]:
		Art.draw_centered(self, Art.EXTINGUISHER, pos, Vector2(38, 38))
	Art.draw_centered(self, Art.FIRST_AID, Vector2(_room.end.x - 60, 531), Vector2(36, 36))


## Palé de madera: con cajas encima si `boxes` > 0, o vacío.
func _draw_pallet(center: Vector2, boxes: int) -> void:
	Art.draw_centered(self, Art.PALLET_BOXES if boxes > 0 else Art.PALLET, center, Vector2(104, 104))


# --- Paredes -----------------------------------------------------------------

func _draw_walls(colors: Dictionary) -> void:
	var wall_color: Color = colors["wall"]
	var walls := [
		Rect2(0, 0, _room.size.x, WALL), Rect2(0, _room.size.y - WALL, _room.size.x, WALL),
		Rect2(0, 0, WALL, _room.size.y), Rect2(_room.size.x - WALL, 0, WALL, _room.size.y),
	]
	for wall: Rect2 in walls:
		draw_rect(wall, wall_color)
		if colors["brick"]:
			_draw_bricks(wall, wall_color)
		elif wall.size.x > wall.size.y:
			for x in range(int(wall.position.x), int(wall.end.x), 80):
				draw_line(Vector2(x, wall.position.y), Vector2(x, wall.end.y), wall_color.darkened(0.25), 2)
		else:
			for y in range(int(wall.position.y), int(wall.end.y), 80):
				draw_line(Vector2(wall.position.x, y), Vector2(wall.end.x, y), wall_color.darkened(0.25), 2)
	# borde interior iluminado y borde exterior (con nieve en el techo en invierno)
	draw_rect(_room.grow(-WALL), Color(1, 1, 1, 0.18), false, 3)
	draw_rect(_room, Color(0.95, 0.97, 1.0) if colors["snow"] else Color(0.1, 0.09, 0.08), false, 6 if colors["snow"] else 4)

	for door in [_door_right, _door_bottom]:
		_draw_door(door)

	# letrero de la empresa en la pared de arriba
	var sign_rect := Rect2(_room.size.x / 2 - 240, 4, 480, 32)
	draw_rect(sign_rect, FINI_RED)
	draw_rect(sign_rect, Color(1, 1, 1, 0.8), false, 2)
	draw_string(ThemeDB.fallback_font, sign_rect.position + Vector2(0, 24), "GOMITAS EXPRESS  ·  FINI",
			HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x, 22, Color.WHITE)


## Ladrillos (paredes de la bodega).
func _draw_bricks(wall: Rect2, color: Color) -> void:
	var mortar := color.lightened(0.35)
	var brick := Vector2(36, 13)
	var rows := ceili(wall.size.y / brick.y)
	for row in rows:
		var y := wall.position.y + row * brick.y
		draw_line(Vector2(wall.position.x, y), Vector2(wall.end.x, y), mortar, 1.5)
		var x := wall.position.x + (brick.x / 2 if row % 2 == 1 else 0.0)
		while x < wall.end.x:
			draw_line(Vector2(x, y), Vector2(x, minf(y + brick.y, wall.end.y)), mortar, 1.5)
			x += brick.x


## Puerta enrollable de metal (las luces que parpadean se dibujan en _draw_fx).
func _draw_door(rect: Rect2) -> void:
	draw_rect(rect, Color(0.55, 0.58, 0.62))
	var vertical := rect.size.y > rect.size.x
	var slats := int((rect.size.y if vertical else rect.size.x) / 12)
	for i in slats:
		if vertical:
			draw_line(Vector2(rect.position.x, rect.position.y + i * 12), Vector2(rect.end.x, rect.position.y + i * 12), Color(0.4, 0.42, 0.46), 2)
		else:
			draw_line(Vector2(rect.position.x + i * 12, rect.position.y), Vector2(rect.position.x + i * 12, rect.end.y), Color(0.4, 0.42, 0.46), 2)
	draw_rect(rect, Color(1, 0.8, 0.1), false, 4)


# === Parte animada (se redibuja cada frame) ====================================

func _draw_fx() -> void:
	var colors: Dictionary = STYLES[style]
	_draw_conveyor(LAYOUTS[style]["conveyor"])
	for spill in warehouse.spills:
		_draw_spill(spill["rect"])
	if _config["robots"]:
		_draw_robot_dock()
	# luces naranjas de las puertas
	var blink := 0.35 + 0.65 * absf(sin(_time * 4.0))
	for door in [_door_right, _door_bottom]:
		for p in [door.position, door.end]:
			_fx.draw_circle(p, 16, Color(1, 0.55, 0.1, 0.25 * blink))
			_fx.draw_circle(p, 8, Color(1, 0.6, 0.15, blink))
	# camión del proveedor: aparece mientras hay cajas en recepción
	if not warehouse.reception_boxes.is_empty():
		# estacionado en la entrada de abajo, junto a la puerta de recepción
		var size := Vector2(300, 300.0 * Art.TRUCK_SUPPLIER.get_height() / Art.TRUCK_SUPPLIER.get_width())
		var truck := Rect2(Vector2(_door_bottom.get_center().x - 60, _room.end.y + 55), size)
		_fx.draw_texture_rect(Art.TRUCK_SUPPLIER, truck, false)
		var panel := Rect2(truck.position + size * Vector2(0.02, 0.03), size * Vector2(0.6, 0.43))
		var font_size := 24
		_fx.draw_string(ThemeDB.fallback_font, Vector2(panel.position.x, panel.get_center().y + font_size * 0.35),
				Lang.t("SUPPLIER_TITLE"), HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, font_size, Color(0.18, 0.43, 0.84))
	if colors["night"]:
		_draw_neon()
	if colors["snow"]:
		_draw_snowfall()


## Cinta transportadora: rodillos que se mueven y cajas (imagen) que bajan por ella.
func _draw_conveyor(rect: Rect2) -> void:
	_fx.draw_rect(rect.grow(4), Color(0.2, 0.2, 0.22))
	_fx.draw_rect(rect, Color(0.32, 0.33, 0.36))
	var offset := fmod(_time * 40.0, 16.0)
	var y := rect.position.y + offset
	while y < rect.end.y:
		_fx.draw_line(Vector2(rect.position.x + 4, y), Vector2(rect.end.x - 4, y), Color(0.5, 0.52, 0.56), 3)
		y += 16
	var boxes := int(rect.size.y / 100)
	for i in boxes:
		var box_y := rect.position.y + 18 + fmod(_time * 40.0 + i * rect.size.y / boxes, rect.size.y - 36)
		Art.draw_centered(_fx, Art.BOX, Vector2(rect.get_center().x, box_y), Vector2(rect.size.x, rect.size.x))
	_fx.draw_rect(rect, Color(1, 0.8, 0.1), false, 3)


## Derrame de jarabe de gomita (resbaladizo).
func _draw_spill(rect: Rect2) -> void:
	var center := rect.get_center()
	var wobble := sin(_time * 3.0) * 3.0
	for i in 7:
		var offset := Vector2(cos(i * 0.9) * rect.size.x * 0.32, sin(i * 1.3) * rect.size.y * 0.28)
		_fx.draw_circle(center + offset, 34 + (i % 3) * 8 + wobble, Color(1.0, 0.3, 0.6, 0.55))
	_fx.draw_circle(center + Vector2(-20, -10), 8, Color(1, 1, 1, 0.6))
	# letrero amarillo de "piso mojado" junto al derrame
	Art.draw_centered(_fx, Art.WET_FLOOR, rect.position + Vector2(10, 0), Vector2(60, 60))


## Base de carga de los robots (Niveles 2 y 3).
func _draw_robot_dock() -> void:
	var dock: Rect2 = _config["dock"]
	_fx.draw_rect(dock, Color(0.15, 0.35, 0.6, 0.35))
	_fx.draw_rect(dock, Color(0.3, 0.7, 1.0), false, 5)
	var glow := 0.5 + 0.5 * sin(_time * 3.0)
	for i in 3:
		var pad := dock.get_center() + Vector2((i - 1) * 90, 10)
		_fx.draw_circle(pad, 38, Color(0.3, 0.75, 1.0, 0.12 + 0.18 * glow))
		_fx.draw_arc(pad, 32, 0, TAU, 32, Color(0.4, 0.85, 1.0, 0.8), 3)
		_fx.draw_colored_polygon(PackedVector2Array([
			pad + Vector2(4, -18), pad + Vector2(-10, 3), pad + Vector2(0, 3),
			pad + Vector2(-4, 18), pad + Vector2(10, -3), pad + Vector2(0, -3)]),
			Color(1, 0.9, 0.3, 0.35 + 0.4 * glow))
	_fx.draw_string(ThemeDB.fallback_font, dock.position + Vector2(0, dock.size.y - 10), Lang.t("ROBOT_DOCK"),
			HORIZONTAL_ALIGNMENT_CENTER, dock.size.x, 18, Color(0.6, 0.85, 1.0))


## Letrero de neón FINI que parpadea (nivel de noche).
func _draw_neon() -> void:
	var flicker := 1.0 if fmod(_time, 4.0) > 0.25 else 0.3
	var center := Vector2(_room.size.x / 2, 90)
	for r in [70.0, 50.0, 30.0]:
		_fx.draw_circle(center, r, Color(1, 0.2, 0.45, 0.08 * flicker))
	_fx.draw_string(ThemeDB.fallback_font, center + Vector2(-100, 16), "FINI", HORIZONTAL_ALIGNMENT_CENTER, 200, 48, Color(1, 0.35, 0.6, flicker))


## Copos de nieve cayendo afuera del edificio (más en la tormenta).
func _draw_snowfall() -> void:
	var storm: bool = warehouse.event == "storm"
	var count := _snowflakes.size() if storm else floori(_snowflakes.size() * 0.5)
	for i in count:
		var flake := _snowflakes[i]
		var speed := flake.z * (2.5 if storm else 1.0)
		var y := fposmod(flake.y + _time * speed, _outside.size.y) + _outside.position.y
		var x := flake.x + sin(_time * 1.5 + flake.y) * 12.0 + (_time * 80.0 if storm else 0.0)
		x = fposmod(x - _outside.position.x, _outside.size.x) + _outside.position.x
		var pos := Vector2(x, y)
		if storm or not _room.grow(10).has_point(pos):
			_fx.draw_circle(pos, 2.0 + flake.z / 40.0, Color(1, 1, 1, 0.85))
