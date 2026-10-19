class_name Forklift
extends Node2D
## Montacargas que recorre un pasillo de ida y vuelta (peligro para el jugador).
## Si choca al jugador, warehouse.gd lo aturde y se le caen las gomitas sueltas.
## La ruta se define en la escena con `route` (puntos en coordenadas del nivel).

@export var route: PackedVector2Array = PackedVector2Array()
@export var speed := 140.0
## Segundos que se queda quieto en cada extremo de la ruta.
@export var pause_at_ends := 1.0

const HIT_RADIUS := 52.0     # distancia a la que choca al jugador
const HIT_COOLDOWN := 2.0    # después de chocar, espera antes de poder volver a chocar

var cooldown := 0.0
var _target := 1
var _step := 1
var _wait := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("forklifts")
	_sprite = Sprite2D.new()
	_sprite.texture = Art.FORKLIFT
	_sprite.scale = Vector2.ONE * 130.0 / Art.FORKLIFT.get_width()   # unos 130 px de largo
	_sprite.show_behind_parent = true   # la luz giratoria se dibuja encima
	add_child(_sprite)
	if route.size() > 0:
		position = route[0]


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	queue_redraw()   # luz giratoria
	if route.size() < 2:
		return
	if _wait > 0.0:
		_wait -= delta
		return
	var target := route[_target]
	if position.distance_to(target) > 1.0:
		_sprite.flip_h = target.x < position.x   # la imagen mira a la derecha: horquillas hacia adelante
	position = position.move_toward(target, speed * delta)
	if position == target:
		# siguiente punto; en los extremos da la vuelta
		if _target + _step < 0 or _target + _step >= route.size():
			_step = -_step
			_wait = pause_at_ends
		_target += _step


## True si el jugador está tan cerca que lo choca.
func hits(point: Vector2) -> bool:
	return cooldown <= 0.0 and position.distance_to(point) < HIT_RADIUS


## Dirección hacia la que avanza (para empujar al jugador).
func direction() -> Vector2:
	if route.size() < 2:
		return Vector2.ZERO
	return (route[_target] - position).normalized()


func _draw() -> void:
	# luz naranja giratoria encima de la cabina
	var t := Time.get_ticks_msec() / 1000.0
	var beam := Vector2.RIGHT.rotated(t * 6.0) * 30.0 + Vector2(0, -18)
	draw_line(Vector2(0, -18), beam, Color(1, 0.6, 0.1, 0.35), 10)
	draw_circle(Vector2(0, -18), 7, Color(1, 0.55, 0.1))
