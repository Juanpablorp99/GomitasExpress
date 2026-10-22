class_name Effects
extends Node2D
## EFECTOS VISUALES del nivel: partículas, explosiones, monedas, textos que flotan y
## temblor de cámara. warehouse.gd crea un solo nodo Effects y llama a sus funciones:
##   effects.pickup(estantería, worker, "osos")   gomitas que vuelan a las manos
##   effects.poof(pos)                            nube de humo
##   effects.explosion(pos)                       explosión con fuego, humo y chispas
##   effects.coins(pos, 12)                       lluvia de monedas + "+$12"
## Todo se dibuja en _draw() con formas simples (no hace falta ninguna imagen nueva).
## Además, solo: humo de los robots atascados, polvo al correr y estrellitas al marearse.

const SHAKE_DECAY := 30.0   # qué tan rápido se calma el temblor de cámara

## Partículas vivas: { "kind", "pos", "vel", "life", "max_life", "size", "end_size",
##   "color", "gravity", "drag", "rot", "spin", "texture", "text", "from", "target", "arc" }
var _particles: Array[Dictionary] = []
var _shake := 0.0
var _time := 0.0
var _smoke_time := 0.0
var _dust_time := 0.0
var _camera: Camera2D
var _player: Player
var _warehouse: Node


func setup(warehouse: Node, player: Player) -> void:
	_warehouse = warehouse
	_player = player
	_camera = player.get_node("Camera2D")
	z_index = 100   # encima de todo el almacén


func _process(delta: float) -> void:
	_time += delta
	_update_particles(delta)
	_update_ambient(delta)
	_update_shake(delta)
	queue_redraw()


# --- Efectos (los llama warehouse.gd) ------------------------------------------

## Recoger de la estantería: unas gomitas saltan y vuelan a las manos del worker.
func pickup(from: Vector2, worker: Node2D, product: String) -> void:
	for i in 5:
		_add({"kind": "texture", "texture": Art.PRODUCTS[product], "from": from + Vector2(randf_range(-60, 60), 0),
				"target": worker, "arc": randf_range(60, 120), "life": 0.45 + i * 0.06,
				"size": 30.0, "end_size": 18.0, "spin": randf_range(-6, 6)})
	sparkle(from, Products.INFO[product]["color"].lightened(0.4), 8)


## Estrellitas que salen hacia afuera.
func sparkle(pos: Vector2, color := Color(1, 0.95, 0.5), count := 10) -> void:
	for i in count:
		var dir := Vector2.from_angle(randf() * TAU)
		_add({"kind": "star", "pos": pos, "vel": dir * randf_range(80, 220), "drag": 3.0,
				"life": randf_range(0.4, 0.7), "size": randf_range(6, 11), "end_size": 0.0,
				"color": color, "spin": randf_range(-8, 8)})


## Nube de humo (al preparar, al aparecer un robot, al reponer...).
func poof(pos: Vector2, color := Color(0.92, 0.92, 0.95), count := 10, spread := 40.0) -> void:
	for i in count:
		var dir := Vector2.from_angle(randf() * TAU)
		_add({"kind": "circle", "pos": pos + dir * randf() * spread * 0.4, "vel": dir * randf_range(30, 110) + Vector2(0, -20),
				"drag": 2.5, "life": randf_range(0.5, 0.9), "size": randf_range(14, 24), "end_size": randf_range(30, 46),
				"color": color})


## Explosión: destello, onda, bolas de fuego, humo, chispas y temblor de cámara.
func explosion(pos: Vector2, power := 1.0) -> void:
	_add({"kind": "circle", "pos": pos, "life": 0.15, "size": 70.0 * power, "end_size": 90.0 * power,
			"color": Color(1, 1, 0.85)})
	_add({"kind": "ring", "pos": pos, "life": 0.4, "size": 20.0, "end_size": 140.0 * power,
			"color": Color(1, 0.85, 0.5)})
	for i in int(14 * power):
		var dir := Vector2.from_angle(randf() * TAU)
		var fire := [Color(1, 0.85, 0.2), Color(1, 0.5, 0.1), Color(0.95, 0.25, 0.1)].pick_random() as Color
		_add({"kind": "circle", "pos": pos, "vel": dir * randf_range(80, 260) * power, "drag": 4.0,
				"life": randf_range(0.3, 0.55), "size": randf_range(16, 28) * power, "end_size": 4.0, "color": fire})
	for i in int(10 * power):
		var dir := Vector2.from_angle(randf() * TAU)
		_add({"kind": "circle", "pos": pos, "vel": dir * randf_range(40, 140) + Vector2(0, -40), "drag": 2.0,
				"life": randf_range(0.8, 1.3), "size": 18.0 * power, "end_size": 50.0 * power,
				"color": Color(0.3, 0.3, 0.32, 0.8)})
	for i in int(16 * power):
		var dir := Vector2.from_angle(randf() * TAU)
		_add({"kind": "spark", "pos": pos, "vel": dir * randf_range(250, 520), "gravity": 600.0, "drag": 1.0,
				"life": randf_range(0.4, 0.8), "size": 3.0, "color": Color(1, 0.9, 0.4)})
	shake(14.0 * power)


## Golpe (el montacargas te choca): estrellas, onda y texto "¡PUM!".
func impact(pos: Vector2) -> void:
	_add({"kind": "ring", "pos": pos, "life": 0.3, "size": 10.0, "end_size": 90.0, "color": Color.WHITE})
	sparkle(pos, Color(1, 0.9, 0.3), 12)
	float_text(pos + Vector2(0, -60), Lang.t("FX_BONK"), Color(1, 0.6, 0.2), 30)
	shake(12.0)


## Monedas que saltan y caen, más el texto "+$X" (los robots ya muestran el suyo).
func coins(pos: Vector2, amount: int, with_text := true) -> void:
	for i in clampi(roundi(amount / 3.0), 4, 14):
		_add({"kind": "texture", "texture": Art.COIN, "pos": pos,
				"vel": Vector2(randf_range(-160, 160), randf_range(-420, -260)), "gravity": 900.0,
				"life": randf_range(0.7, 1.0), "size": 26.0, "end_size": 20.0, "spin": randf_range(-10, 10)})
	if with_text:
		float_text(pos + Vector2(0, -50), "+$%d" % amount, Color(0.45, 1.0, 0.45), 34)


## Papelitos de colores (combo).
func confetti(pos: Vector2, count := 30) -> void:
	var colors := [Color(1, 0.35, 0.4), Color(1, 0.85, 0.3), Color(0.4, 0.85, 1), Color(0.5, 1, 0.5), Color(1, 0.6, 0.9)]
	for i in count:
		_add({"kind": "rect", "pos": pos, "vel": Vector2(randf_range(-260, 260), randf_range(-520, -220)),
				"gravity": 700.0, "drag": 1.5, "life": randf_range(0.9, 1.4), "size": randf_range(6, 10),
				"color": colors.pick_random(), "rot": randf() * TAU, "spin": randf_range(-12, 12)})


## Pedido perdido: humo rojo, una X grande y la multa.
func fail(pos: Vector2, penalty: int) -> void:
	poof(pos, Color(1, 0.35, 0.3, 0.8), 12)
	_add({"kind": "cross", "pos": pos + Vector2(0, -30), "life": 0.9, "size": 50.0, "end_size": 34.0,
			"color": Color(1, 0.25, 0.25)})
	float_text(pos + Vector2(0, -80), "-$%d" % penalty, Color(1, 0.4, 0.4), 32)
	shake(6.0)


## Texto que sube y se desvanece.
func float_text(pos: Vector2, text: String, color := Color.WHITE, font_size := 26) -> void:
	_add({"kind": "text", "pos": pos, "vel": Vector2(0, -70), "drag": 1.2, "life": 1.3,
			"size": float(font_size), "text": text, "color": color})


## Tiembla la cámara (se va calmando sola).
func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)


## "Aplasta y estira" un sprite (como gelatina) al hacer una acción.
func squash(sprite: Node2D) -> void:
	var base: Vector2 = sprite.get_meta("base_scale", sprite.scale)
	sprite.set_meta("base_scale", base)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", base * Vector2(1.25, 0.8), 0.07)
	tween.tween_property(sprite, "scale", base * Vector2(0.88, 1.15), 0.08)
	tween.tween_property(sprite, "scale", base, 0.12)


# --- Simulación ----------------------------------------------------------------

func _add(particle: Dictionary) -> void:
	var p := {"pos": Vector2.ZERO, "vel": Vector2.ZERO, "gravity": 0.0, "drag": 0.0, "rot": 0.0, "spin": 0.0,
			"color": Color.WHITE, "size": 10.0}
	p.merge(particle, true)
	if not p.has("end_size"):
		p["end_size"] = p["size"]
	if p.has("from"):
		p["pos"] = p["from"]
	p["max_life"] = p["life"]
	_particles.append(p)


func _update_particles(delta: float) -> void:
	for p in _particles:
		p["life"] -= delta
		p["rot"] += p["spin"] * delta
		if p.has("target"):
			# vuela en arco desde "from" hasta el worker (aunque se mueva)
			var target = p["target"]
			var goal: Vector2 = target.global_position + Vector2(0, -50) if is_instance_valid(target) else p["pos"]
			var t: float = 1.0 - p["life"] / p["max_life"]
			p["pos"] = (p["from"] as Vector2).lerp(goal, t * t) + Vector2(0, -p["arc"] * sin(PI * t))
			continue
		p["vel"] += Vector2(0, p["gravity"]) * delta
		p["vel"] *= maxf(1.0 - p["drag"] * delta, 0.0)
		p["pos"] += p["vel"] * delta
	for i in range(_particles.size() - 1, -1, -1):
		if _particles[i]["life"] <= 0.0:
			_particles.remove_at(i)


## Efectos que salen solos: humo de robots atascados y polvo al correr.
func _update_ambient(delta: float) -> void:
	if _warehouse == null or _warehouse.phase != "playing":
		return
	_smoke_time -= delta
	if _smoke_time <= 0.0:
		_smoke_time = 0.18
		for robot: Robot in _warehouse.robots:
			if robot.broken:
				_add({"kind": "circle", "pos": robot.position + Vector2(randf_range(-10, 10), -60),
						"vel": Vector2(randf_range(-15, 15), -60), "life": 1.0, "size": 10.0, "end_size": 28.0,
						"color": Color(0.35, 0.35, 0.38, 0.7)})
				if randf() < 0.3:
					_add({"kind": "spark", "pos": robot.position + Vector2(0, -50),
							"vel": Vector2(randf_range(-150, 150), randf_range(-250, -100)), "gravity": 600.0,
							"life": 0.4, "size": 2.5, "color": Color(1, 0.9, 0.4)})
	_dust_time -= delta
	if _dust_time <= 0.0 and _player.sprinting:
		_dust_time = 0.09
		var color := Color(0.9, 0.95, 1.0, 0.7) if _player.slippery else Color(0.75, 0.68, 0.6, 0.6)
		_add({"kind": "circle", "pos": _player.global_position + Vector2(randf_range(-8, 8), 8),
				"vel": -_player.velocity * 0.15 + Vector2(0, -15), "drag": 3.0, "life": 0.4,
				"size": 6.0, "end_size": 16.0, "color": color})


func _update_shake(delta: float) -> void:
	_shake = maxf(_shake - SHAKE_DECAY * delta, 0.0)
	_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake


# --- Dibujo --------------------------------------------------------------------

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for p in _particles:
		var k: float = 1.0 - p["life"] / p["max_life"]   # 0 al nacer, 1 al morir
		var size: float = lerpf(p["size"], p["end_size"], k)
		var color: Color = p["color"]
		color.a *= 1.0 - k * k
		var pos: Vector2 = p["pos"]
		match p["kind"]:
			"circle":
				draw_circle(pos, size, color)
			"ring":
				draw_arc(pos, size, 0, TAU, 32, color, maxf(8.0 * (1.0 - k), 1.0))
			"spark":
				draw_line(pos, pos - (p["vel"] as Vector2) * 0.04, color, size)
			"star":
				_draw_star(pos, size, p["rot"], color)
			"rect":
				draw_set_transform(pos, p["rot"], Vector2(1, 0.5 + 0.5 * absf(sin(p["rot"]))))
				draw_rect(Rect2(-size / 2, -size / 2, size, size * 1.6), color)
				draw_set_transform(Vector2.ZERO)
			"texture":
				draw_set_transform(pos, p["rot"])
				Art.draw_centered(self, p["texture"], Vector2.ZERO, Vector2.ONE * size, Color(1, 1, 1, color.a))
				draw_set_transform(Vector2.ZERO)
			"cross":
				var pop := size * (1.0 + 0.4 * sin(minf(k * 8.0, PI)))   # salta al aparecer
				draw_line(pos + Vector2(-pop, -pop) / 2, pos + Vector2(pop, pop) / 2, color, 12)
				draw_line(pos + Vector2(pop, -pop) / 2, pos + Vector2(-pop, pop) / 2, color, 12)
			"text":
				var font_size := int(size * (1.0 + 0.3 * maxf(0.0, 1.0 - k * 6.0)))   # empieza más grande
				var at := pos - Vector2(150, 0)
				draw_string_outline(font, at, p["text"], HORIZONTAL_ALIGNMENT_CENTER, 300, font_size, 6, Color(0, 0, 0, color.a))
				draw_string(font, at, p["text"], HORIZONTAL_ALIGNMENT_CENTER, 300, font_size, color)
	# estrellitas girando sobre la cabeza si está mareado
	if _player != null and _player.is_stunned():
		var head := _player.global_position + Vector2(0, -95)
		for i in 3:
			var angle := _time * 6.0 + i * TAU / 3
			_draw_star(head + Vector2(cos(angle) * 26, sin(angle) * 8), 8, angle, Color(1, 0.9, 0.3))


func _draw_star(center: Vector2, radius: float, rotation_angle: float, color: Color) -> void:
	if radius <= 0.5:
		return
	var points := PackedVector2Array()
	for i in 8:
		var r := radius if i % 2 == 0 else radius * 0.4
		points.append(center + Vector2.from_angle(rotation_angle + i * TAU / 8) * r)
	draw_colored_polygon(points, color)
