class_name Products
## Productos Fini: precios, colores e iconos (las imágenes están en Art.PRODUCTS).
## Los nombres y unidades están en lang.gd (PRODUCT_<id> y UNIT_<id>).

## Unidades que trae cada caja del proveedor.
const LOT_SIZE := 10

## Las 8 gomitas Fini del juego (cada nivel usa algunas, ver levels.gd).
## color: mensajes · shelf: color de su estantería · price: lo que paga el cliente por
## unidad · lot_cost: lo que cobra el proveedor por una caja de LOT_SIZE unidades.
const INFO := {
	"osos": {"color": Color(0.95, 0.3, 0.3), "shelf": Color(0.6, 0.3, 0.3), "price": 2, "lot_cost": 10},
	"raton": {"color": Color(1.0, 0.6, 0.75), "shelf": Color(0.6, 0.4, 0.5), "price": 3, "lot_cost": 15},
	"gusanos": {"color": Color(0.35, 0.85, 0.3), "shelf": Color(0.3, 0.5, 0.3), "price": 4, "lot_cost": 20},
	"dentaduras": {"color": Color(1.0, 0.4, 0.55), "shelf": Color(0.62, 0.28, 0.38), "price": 4, "lot_cost": 20},
	"huevos": {"color": Color(1.0, 0.8, 0.3), "shelf": Color(0.6, 0.52, 0.28), "price": 3, "lot_cost": 15},
	"platanos": {"color": Color(1.0, 0.88, 0.25), "shelf": Color(0.58, 0.55, 0.2), "price": 3, "lot_cost": 15},
	"fresas": {"color": Color(1.0, 0.3, 0.4), "shelf": Color(0.65, 0.22, 0.3), "price": 5, "lot_cost": 25},
	"colas": {"color": Color(0.8, 0.5, 0.3), "shelf": Color(0.45, 0.3, 0.2), "price": 4, "lot_cost": 20},
}


static func display_name(id: String) -> String:
	return Lang.t("PRODUCT_" + id)


## Ejemplo: "5 CAJAS DE OSOS" / "5 BOXES OF BEARS"
static func describe(id: String, quantity: int) -> String:
	return Lang.t("DESCRIBE") % [quantity, Lang.t("UNIT_" + id), display_name(id)]


## Ejemplo: "2 OSOS, 4 RATÓN" (versión corta para el tablero de pedidos).
static func summary(items: Dictionary) -> String:
	var parts := []
	for id: String in items:
		parts.append("%d %s" % [items[id], display_name(id)])
	return ", ".join(parts)


## Recompensa de un pedido: suma de cantidad × precio de cada producto.
static func order_value(items: Dictionary) -> int:
	var total := 0
	for id: String in items:
		total += int(items[id]) * int(INFO[id]["price"])
	return total


## Dibuja sobre la cabeza lo que lleva un trabajador (jugador o robot).
## `lift` sube el dibujo (el jugador es más alto que el robot) y `show_box` = false
## si el personaje ya tiene la caja dibujada en los brazos (pose de cargar).
static func draw_carried(canvas: CanvasItem, carrying: String, items: Dictionary, lift := 0.0, show_box := true) -> void:
	var up := Vector2(0, lift)
	match carrying:
		"productos":
			# un icono por producto con su cantidad debajo
			var x := -(items.size() - 1) * 21.0
			for id: String in items:
				draw_icon(canvas, id, Vector2(x, -48) + up, 1.0)
				_draw_count(canvas, Vector2(x, -24) + up, items[id])
				x += 42.0
		"pedido":
			if show_box:
				Art.draw_centered(canvas, Art.BOX, Vector2(0, -42) + up, Vector2(40, 40))
		"caja":
			# caja del proveedor: el producto que trae y las unidades que quedan
			if show_box:
				Art.draw_centered(canvas, Art.BOX, Vector2(0, -46) + up, Vector2(50, 50))
			for id: String in items:
				draw_icon(canvas, id, Vector2(0, -48) + up, 0.8)
				_draw_count(canvas, Vector2(0, -16) + up, items[id])


## Dibuja el icono (imagen) del producto. Debe llamarse desde el _draw() de `canvas`.
## `s` es la escala (1.0 = 34 px).
static func draw_icon(canvas: CanvasItem, id: String, center: Vector2, s := 1.0) -> void:
	Art.draw_centered(canvas, Art.PRODUCTS[id], center, Vector2(34, 34) * s)


## Texto "x5" con borde negro, centrado en `pos`.
static func _draw_count(canvas: CanvasItem, pos: Vector2, amount: int) -> void:
	var font := ThemeDB.fallback_font
	var text := "x%d" % amount
	canvas.draw_string_outline(font, pos - Vector2(20, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, 4, Color.BLACK)
	canvas.draw_string(font, pos - Vector2(20, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color.WHITE)
