class_name Station
extends Node2D
## Punto del almacén con el que un trabajador (el jugador, y más adelante los robots)
## puede interactuar: estantería, zona de preparación, zona de despacho o recepción.
## Se dibuja con formas simples para no depender de sprites todavía.

enum Type { SHELF, PREP, DISPATCH, DECOR, RECEIVING }

## Por debajo de esta cantidad el stock de la estantería se muestra en rojo.
const LOW_STOCK := 8

@export var type: Type = Type.SHELF
## Solo para estanterías: id del producto que guarda ("osos", "raton", "gusanos").
@export var product := ""
## Clave de texto en lang.gd. En estanterías se usa el nombre del producto.
@export var title := ""
@export var size := Vector2(240, 80)
@export var color := Color(0.45, 0.3, 0.2)
## Si es true, el jugador choca contra la estación (estanterías, mesas).
@export var solid := true
## Distancia extra alrededor del rectángulo desde la que se puede interactuar.
@export var interact_margin := 45.0
## Solo para estanterías: cuántas unidades caben como máximo.
@export var capacity := 30

## Solo para estanterías: si se muestra el stock "12/30" (solo en niveles con proveedor).
var show_stock := false:
	set(value):
		show_stock = value
		queue_redraw()

## Solo para estanterías: unidades que quedan. Lo cambia warehouse.gd.
var stock := 0:
	set(value):
		if stock != value:
			stock = value
			queue_redraw()

## Solo para recepción: cajas en el suelo ([{ "product": String, "qty": int }])
## y el aviso del camión del proveedor. Los asigna warehouse.gd.
var boxes: Array = []:
	set(value):
		boxes = value
		queue_redraw()
var info_text := "":
	set(value):
		if info_text != value:
			info_text = value
			queue_redraw()

## Se ilumina cuando el jugador está lo bastante cerca para usarla.
var highlighted := false:
	set(value):
		if highlighted != value:
			highlighted = value
			queue_redraw()

## Muestra una flecha encima: es el siguiente lugar al que debe ir el jugador.
var is_target := false:
	set(value):
		if is_target != value:
			is_target = value
			queue_redraw()


func _ready() -> void:
	add_to_group("stations")
	if product != "":
		color = Products.INFO[product]["shelf"]   # cada gomita tiene el color de su estantería
	if solid:
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = size
		var collision := CollisionShape2D.new()
		collision.shape = rect_shape
		var body := StaticBody2D.new()
		body.add_child(collision)
		add_child(body)


func _process(_delta: float) -> void:
	if is_target:
		queue_redraw()  # anima la flecha


func is_interactive() -> bool:
	return type != Type.DECOR


func is_in_range(point: Vector2) -> bool:
	return Rect2(global_position - size / 2, size).grow(interact_margin).has_point(point)


func _draw() -> void:
	var rect := Rect2(-size / 2, size)
	if solid:
		draw_rect(Rect2(rect.position + Vector2(7, 9), rect.size), Color(0, 0, 0, 0.28))   # sombra
	else:
		_draw_floor_stripes(rect, color)
	match type:
		Type.SHELF, Type.DECOR:
			_draw_shelf(rect)
		Type.PREP:
			draw_rect(rect, color)
			draw_rect(rect.grow(-8), color.lightened(0.35))
			# cajas sobre la mesa de preparación
			Art.draw_centered(self, Art.BOX, Vector2(-45, -4), Vector2(54, 54))
			Art.draw_centered(self, Art.BOX, Vector2(30, 2), Vector2(46, 46))
		Type.DISPATCH:
			draw_rect(rect, Color(color, 0.25))
			draw_rect(rect, color, false, 6)
			_draw_truck(Vector2(0, -12))
			draw_string(ThemeDB.fallback_font, Vector2(-size.x / 2, size.y / 2 - 20), Lang.t("DELIVER_HERE"),
					HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color(color, 0.8))
		Type.RECEIVING:
			_draw_receiving(rect)

	if highlighted:
		draw_rect(rect.grow(6), Color(1, 0.95, 0.3), false, 4)

	var font := ThemeDB.fallback_font
	var text := Products.display_name(product) if product != "" else Lang.t(title)
	var label_pos := Vector2(-size.x / 2, -size.y / 2 - 12)
	draw_string_outline(font, label_pos, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, 6, Color.BLACK)
	draw_string(font, label_pos, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color.WHITE)

	# stock debajo de la estantería: "12/15", en rojo si queda poco
	if type == Type.SHELF and product != "" and show_stock:
		var stock_text := "%d/%d" % [stock, capacity] if stock > 0 else Lang.t("OUT_OF_STOCK")
		var stock_color := Color(1, 0.4, 0.35) if stock < LOW_STOCK else Color(0.75, 1, 0.75)
		var stock_pos := Vector2(-size.x / 2, size.y / 2 + 20)
		draw_string_outline(font, stock_pos, stock_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, 6, Color.BLACK)
		draw_string(font, stock_pos, stock_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, stock_color)

	if is_target:
		var bob := sin(Time.get_ticks_msec() / 150.0) * 6.0
		var tip := Vector2(0, -size.y / 2 - 40 + bob)
		draw_colored_polygon(PackedVector2Array([
			tip, tip + Vector2(-14, -22), tip + Vector2(14, -22)
		]), Color(1, 0.9, 0.2))


func _draw_shelf(rect: Rect2) -> void:
	draw_rect(rect, color)
	var inner := rect.grow(-6)
	draw_rect(inner, color.darkened(0.4))
	var columns := maxi(1, int(inner.size.x / 48))
	var cell_w := inner.size.x / columns
	# con stock visible se dibujan tantos huecos llenos como stock quede; si no, llena
	var filled := columns
	if show_stock:
		filled = ceili(float(stock) / capacity * columns) if capacity > 0 else 0
	for i in columns:
		var center := inner.position + Vector2(cell_w * (i + 0.5), inner.size.y / 2)
		if type == Type.SHELF and product != "":
			if i < filled:
				Products.draw_icon(self, product, center, 1.3)
		else:
			# cajas de cartón
			draw_rect(Rect2(center - Vector2(16, 16), Vector2(32, 32)), Color(0.7, 0.55, 0.35))
			draw_rect(Rect2(center - Vector2(16, 16), Vector2(32, 32)), Color(0.4, 0.3, 0.15), false, 2)
		if i > 0:
			var x := inner.position.x + cell_w * i
			draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), color, 4)
	# marco y postes metálicos de la estantería
	draw_rect(rect, color.darkened(0.55), false, 3)
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		draw_rect(Rect2(corner - Vector2(5, 5), Vector2(10, 10)), Color(0.35, 0.37, 0.4))
		draw_rect(Rect2(corner - Vector2(5, 5), Vector2(10, 10)), Color(0.15, 0.15, 0.17), false, 1.5)


## Rayas diagonales suaves del color de la zona (despacho, recepción).
func _draw_floor_stripes(rect: Rect2, stripe_color: Color) -> void:
	var area := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var x := rect.position.x - rect.size.y
	while x < rect.end.x:
		var band := PackedVector2Array([
			Vector2(x, rect.end.y), Vector2(x + 14, rect.end.y),
			Vector2(x + 14 + rect.size.y, rect.position.y), Vector2(x + rect.size.y, rect.position.y)])
		for piece in Geometry2D.intersect_polygons(area, band):
			draw_colored_polygon(piece, Color(stripe_color, 0.12))
		x += 34


## Zona de recepción: cajas del proveedor en el suelo (2 filas de 3) y aviso del camión.
func _draw_receiving(rect: Rect2) -> void:
	draw_rect(rect, Color(color, 0.2))
	draw_rect(rect, color, false, 4)
	for i in boxes.size():
		var center := Vector2(-90 + (i % 3) * 90, -35 + floori(i / 3.0) * 60)
		Art.draw_centered(self, Art.BOX, center, Vector2(58, 58))
		Products.draw_icon(self, boxes[i]["product"], center, 0.85)
	if info_text != "":
		var font := ThemeDB.fallback_font
		var pos := Vector2(-size.x / 2, size.y / 2 - 12)
		draw_string_outline(font, pos, info_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, 6, Color.BLACK)
		draw_string(font, pos, info_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(0.7, 0.9, 1.0))


## Camión de reparto (imagen) con el logo FINI encima del remolque.
func _draw_truck(center: Vector2) -> void:
	var width := minf(size.x - 60, 220.0)
	var truck_size := Vector2(width, width * Art.TRUCK_FINI.get_height() / Art.TRUCK_FINI.get_width())
	Art.draw_centered(self, Art.TRUCK_FINI, center, truck_size)
	# el logo va en el panel blanco de la caja del camión
	var panel := Rect2(center - truck_size / 2 + truck_size * Vector2(0.02, 0.03), truck_size * Vector2(0.62, 0.39))
	draw_string(ThemeDB.fallback_font, Vector2(panel.position.x, panel.get_center().y + 11), "FINI",
			HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 32, Color(0.85, 0.1, 0.2))
