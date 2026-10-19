class_name Player
extends CharacterBody2D
## Trabajador controlado por el jugador. Se mueve, corre (Shift), puede resbalar en el
## hielo o en derrames y quedar aturdido si lo choca un montacargas.
## Las reglas del pedido viven en warehouse.gd para poder reutilizarlas con robots.

signal interact_requested

@export var speed := 250.0

const SPRINT_MULT := 1.6          # corriendo va 60% más rápido...
const STAMINA_DRAIN := 0.45       # ...pero gasta energía (por segundo)
const STAMINA_REGEN := 0.25
const STAMINA_RECOVER := 0.35     # si se agota, no puede volver a correr hasta tener esto
const ICE_GRIP := 1.6             # en hielo cuesta frenar y girar (menos = más resbaladizo)

## Pedido que está atendiendo ({} si no tiene). Lo asigna warehouse.gd.
var order := {}

## Lo que lleva en las manos: "" (nada), "productos", "pedido" (caja preparada) o "caja" (del proveedor).
var carrying := "":
	set(value):
		carrying = value
		queue_redraw()

## Productos sueltos que lleva: { "osos": 2, "raton": 4 }
var items := {}:
	set(value):
		items = value
		queue_redraw()

var stamina := 1.0
## Lo pone warehouse.gd cada frame: si está sobre hielo/derrame y si hay tormenta.
var slippery := false
var speed_mult := 1.0
## Progreso de la acción "mantener E" (0..1) para dibujar la barra. Lo pone warehouse.gd.
var hold_ratio := 0.0

## Animaciones del personaje: nombre -> [poses (imágenes de assets/characters/player/), cuadros por segundo].
## Cada una existe hacia el frente ("_front"), de lado ("_side", mira a la derecha y se
## voltea para la izquierda) y de espaldas ("_back").
## (Las imágenes se cortan de las hojas de assets/sources/ con tools/slice_sprites.gd.)
const ANIMATIONS := {
	"idle_front": [["front_stand", "front_stand", "front_stand", "front_stand", "front_stand", "front_blink"], 4.0],
	"idle_side": [["side_walk_1"], 1.0],
	"idle_back": [["back_walk_1"], 1.0],
	"walk_front": [["front_walk_a", "front_stand", "front_walk_b", "front_stand"], 8.0],
	"walk_side": [["side_walk_0", "side_walk_1", "side_walk_2", "side_walk_3"], 8.0],
	"walk_back": [["back_walk_0", "back_walk_1", "back_walk_2", "back_walk_3"], 8.0],
	"carry_front": [["carry_a", "carry_b"], 6.0],
	"carry_side": [["carry_side_0", "carry_side_1", "carry_side_2", "carry_side_3"], 8.0],
	"carry_back": [["carry_back_0", "carry_back_1", "carry_back_2", "carry_back_3"], 8.0],
	"dizzy": [["dizzy"], 1.0],
}
const ITEMS_LIFT := -34.0   # lo que lleva se dibuja más arriba porque el personaje es alto

var _exhausted := false
var _stun_time := 0.0
var _facing := "front"   # "front", "side" o "back": hacia dónde mira

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation: String in ANIMATIONS:
		frames.add_animation(animation)
		frames.set_animation_speed(animation, ANIMATIONS[animation][1])
		for pose: String in ANIMATIONS[animation][0]:
			frames.add_frame(animation, Art.player_pose(pose))
	sprite.sprite_frames = frames
	sprite.play("idle_front")


func _physics_process(delta: float) -> void:
	_stun_time = maxf(_stun_time - delta, 0.0)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if is_stunned():
		direction = Vector2.ZERO

	var sprinting := Input.is_action_pressed("sprint") and direction != Vector2.ZERO and not _exhausted
	if sprinting:
		stamina -= STAMINA_DRAIN * delta
		if stamina <= 0.0:
			_exhausted = true
	else:
		stamina += STAMINA_REGEN * delta
		if _exhausted and stamina >= STAMINA_RECOVER:
			_exhausted = false
	stamina = clampf(stamina, 0.0, 1.0)

	var target := direction * speed * speed_mult * (SPRINT_MULT if sprinting else 1.0)
	if is_stunned():
		velocity = velocity.lerp(Vector2.ZERO, 6.0 * delta)   # sale empujado y frena
	elif slippery:
		velocity = velocity.lerp(target, ICE_GRIP * delta)    # patina
	else:
		velocity = target
	move_and_slide()
	_update_animation(direction, sprinting)
	queue_redraw()


## Elige la animación según lo que hace (quieto, caminando, cargando o mareado)
## y hacia dónde mira (frente, lado o espalda).
func _update_animation(direction: Vector2, sprinting: bool) -> void:
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			_facing = "side"
			sprite.flip_h = direction.x < 0.0   # las poses de lado miran a la derecha
		else:
			_facing = "back" if direction.y < 0.0 else "front"
			sprite.flip_h = false

	var moving := direction != Vector2.ZERO
	var animation := "idle_" + _facing
	if is_stunned():
		animation = "dizzy"
	elif carrying == "pedido" or carrying == "caja":
		animation = "carry_" + _facing
	elif moving:
		animation = "walk_" + _facing

	if sprite.animation != animation:
		sprite.play(animation)
	# cargando y quieto: se queda en una pose; corriendo: la animación va más rápido
	if animation.begins_with("carry") and not moving:
		sprite.pause()
	elif not sprite.is_playing():
		sprite.play(animation)
	sprite.speed_scale = SPRINT_MULT if sprinting else 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_requested.emit()


func is_stunned() -> bool:
	return _stun_time > 0.0


## Lo llama warehouse.gd cuando un montacargas lo choca.
func stun(seconds: float, push: Vector2) -> void:
	_stun_time = seconds
	velocity = push


func _draw() -> void:
	Products.draw_carried(self, carrying, items, ITEMS_LIFT, false)
	# barra de energía debajo (solo si no está llena)
	if stamina < 1.0:
		var bar := Rect2(-22, 26, 44, 6)
		draw_rect(bar, Color(0, 0, 0, 0.6))
		var color := Color(1, 0.35, 0.3) if _exhausted else Color(0.3, 0.85, 1.0)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * stamina, bar.size.y)), color)
	# progreso de "mantener E" (preparar o reparar)
	if hold_ratio > 0.0:
		draw_arc(Vector2(0, -12), 38, -PI / 2, -PI / 2 + TAU * hold_ratio, 32, Color(1, 0.9, 0.3), 6)
