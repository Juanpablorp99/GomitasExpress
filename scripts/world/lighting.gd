extends Node2D
## Iluminación del nivel de noche (Nivel 2): todo oscuro (CanvasModulate) y luces
## (PointLight2D) en el techo, una linterna en el jugador y luces en robots y montacargas.
## En el evento APAGÓN se apagan las luces del techo y solo queda la linterna.
## Va en la escena del nivel, después de los montacargas.

const DARK := Color(0.13, 0.15, 0.27)       # color de la noche (multiplica todo lo que se ve)
const BLACKOUT := Color(0.06, 0.06, 0.12)   # aún más oscuro en el apagón
const CEILING_COLOR := Color(0.85, 0.92, 1.0)

var _darkness: CanvasModulate
var _ceiling: Array[PointLight2D] = []
var _texture: GradientTexture2D

@onready var warehouse: Node = get_parent()


func _ready() -> void:
	_texture = _make_light_texture()
	_darkness = CanvasModulate.new()
	_darkness.color = DARK
	add_child(_darkness)

	var room: Vector2 = Levels.get_config(warehouse.level_number)["room"]
	for x in range(320, int(room.x), 520):
		for y in range(300, int(room.y), 480):
			_ceiling.append(_add_light(self, Vector2(x, y), 3.2, CEILING_COLOR, 1.1))
	# letrero de neón FINI en la pared de arriba
	_add_light(self, Vector2(room.x / 2, 90), 2.0, Color(1, 0.3, 0.55), 1.2)
	# linterna del jugador
	_add_light(warehouse.get_node("Player"), Vector2.ZERO, 2.6, Color(1, 0.95, 0.8), 1.2)
	# luces naranjas de los montacargas
	var forklifts := warehouse.get_node_or_null("Forklifts")
	if forklifts != null:
		for forklift in forklifts.get_children():
			_add_light(forklift, Vector2.ZERO, 1.6, Color(1, 0.6, 0.2), 1.0)


func _process(delta: float) -> void:
	var blackout: bool = warehouse.event == "blackout"
	_darkness.color = _darkness.color.lerp(BLACKOUT if blackout else DARK, 3.0 * delta)
	for light in _ceiling:
		light.energy = lerpf(light.energy, 0.0 if blackout else 1.0, 4.0 * delta)
	# los robots que se compran también llevan luz
	for robot in warehouse.robots:
		if not robot.has_meta("light"):
			robot.set_meta("light", _add_light(robot, Vector2.ZERO, 1.8, Color(0.4, 0.85, 1.0), 1.0))


func _add_light(parent: Node, pos: Vector2, size: float, color: Color, energy: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _texture
	light.texture_scale = size
	light.color = color
	light.energy = energy
	light.position = pos
	parent.add_child(light)
	return light


## Círculo blanco que se desvanece hacia los bordes (la forma de cada luz).
func _make_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture
