class_name Art
## Todas las imágenes del juego en un solo lugar.
## Casi todas se hicieron con Gemini y se cortaron de las hojas de assets/sources/ con
## tools/slice_sprites.gd. Para cambiar un dibujo, reemplaza la imagen en assets/ o cambia la ruta aquí.

# Productos (gomitas)
const PRODUCTS := {
	"osos": preload("res://assets/products/osos.png"),
	"raton": preload("res://assets/products/raton.png"),
	"gusanos": preload("res://assets/products/gusanos.png"),
	"dentaduras": preload("res://assets/products/dentaduras.png"),
	"huevos": preload("res://assets/products/huevos.png"),
	"platanos": preload("res://assets/products/platanos.png"),
	"fresas": preload("res://assets/products/fresas.png"),
	"colas": preload("res://assets/products/colas.png"),
}

# Objetos del almacén (cuadrados, vista 3/4)
const BOX := preload("res://assets/props/box.png")
const PALLET := preload("res://assets/props/pallet.png")
const PALLET_BOXES := preload("res://assets/props/pallet_boxes.png")
const BARREL := preload("res://assets/props/barrel.png")
const CONE := preload("res://assets/props/cone.png")
const PLANT := preload("res://assets/props/plant.png")
const EXTINGUISHER := preload("res://assets/props/extinguisher.png")
const FIRST_AID := preload("res://assets/props/first_aid.png")
const TABLE := preload("res://assets/props/table.png")
const SHELF := preload("res://assets/props/shelf.png")
const WET_FLOOR := preload("res://assets/props/wet_floor.png")
const TRASH := preload("res://assets/props/trash.png")
# Exterior (dibujos propios)
const TREE := preload("res://assets/props/tree.svg")
const TREE_SNOW := preload("res://assets/props/tree_snow.svg")
const SNOWMAN := preload("res://assets/props/snowman.svg")

# Vehículos (de perfil, mirando a la derecha; los autos vistos desde arriba)
const FORKLIFT := preload("res://assets/vehicles/forklift.png")
const TRUCK_FINI := preload("res://assets/vehicles/truck_fini.png")
const TRUCK_SUPPLIER := preload("res://assets/vehicles/truck_supplier.png")
const CAR := preload("res://assets/vehicles/car.png")   # blanco: se tiñe de colores

# Interfaz (HUD)
const HEART := preload("res://assets/ui/heart.png")
const HEART_EMPTY := preload("res://assets/ui/heart_empty.png")
const STAR := preload("res://assets/ui/star.png")
const STAR_EMPTY := preload("res://assets/ui/star_empty.png")
const CLOCK := preload("res://assets/ui/clock.png")
const COIN := preload("res://assets/ui/coin.png")
const BOLT := preload("res://assets/ui/bolt.png")
const ALERT := preload("res://assets/ui/alert.png")
const LOGO := preload("res://assets/ui/logo.png")


## Dibuja `texture` centrada en `center` con el tamaño `size`. Llamar desde un _draw().
static func draw_centered(canvas: CanvasItem, texture: Texture2D, center: Vector2, size: Vector2,
		tint := Color.WHITE) -> void:
	canvas.draw_texture_rect(texture, Rect2(center - size / 2, size), false, tint)


## Pose del trabajador por su nombre (assets/characters/player/<nombre>.png). Ej.: "back_walk_0"
static func player_pose(pose: String) -> Texture2D:
	return load("res://assets/characters/player/%s.png" % pose)


## Pose del robot por su nombre (assets/characters/robot/<nombre>.png). Ej.: "side_1"
static func robot_pose(pose: String) -> Texture2D:
	return load("res://assets/characters/robot/%s.png" % pose)
