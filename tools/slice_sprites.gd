extends SceneTree
## HERRAMIENTA: corta las hojas de imágenes de assets/sources/ en imágenes sueltas.
## Encuentra cada dibujo solo. Si la hoja es JPG (fondo blanco), primero quita el fondo
## "rellenando" el blanco desde los bordes, así no borra los blancos de adentro de los dibujos.
## Si cambias o agregas hojas, vuelve a ejecutarla con:
##   Godot_console.exe --headless --path . -s tools/slice_sprites.gd
##
## Tipos de trabajo (JOBS):
##   "icons": cada dibujo centrado en un cuadrado de `size` px (gomitas, objetos, íconos)
##   "trim":  cada dibujo recortado justo, sin cambiar su forma (vehículos)
##   "poses": cada dibujo con los pies abajo en un cuadro de 128x160 (personajes animados);
##            `height` escala la hoja para que el personaje tenga siempre el mismo tamaño
##   "whole": la imagen entera recortada (logo)
## Opcionales: "merge" = distancia para juntar piezas de un mismo dibujo (por defecto 22);
## "rows": "top" = agrupa las filas por el borde de arriba en vez de por el centro.
## En "names", "" = ese dibujo de la hoja no se usa. Los dibujos van en orden de lectura
## (por filas, de izquierda a derecha).

const JOBS := [
	{"file": "gomitas_sheet.png", "type": "icons", "size": 256, "dir": "products", "merge": 0, "rows": "top",
		"names": ["osos", "raton", "gusanos", "dentaduras", "huevos", "platanos", "fresas", "colas"]},
	{"file": "player_sheet.png", "type": "poses", "height": 0, "dir": "characters/player", "merge": 0, "rows": "top",
		"names": ["front_walk_a", "", "", "front_walk_b", "", "", "", "", "front_stand", "",
				"dizzy", "front_blink", "carry_a", "carry_b"]},
	{"file": "player_walk.png", "type": "poses", "height": 112, "dir": "characters/player", "merge": 0, "rows": "top",
		"names": ["side_walk_0", "side_walk_1", "side_walk_2", "side_walk_3",
				"back_walk_0", "back_walk_1", "back_walk_2", "back_walk_3"]},
	{"file": "player_carry.png", "type": "poses", "height": 112, "dir": "characters/player", "merge": 0, "rows": "top",
		"names": ["carry_side_0", "carry_side_1", "carry_side_2", "carry_side_3",
				"carry_back_0", "carry_back_1", "carry_back_2", "carry_back_3"]},
	{"file": "robot_sheet.jpg", "type": "poses", "height": 112, "dir": "characters/robot",
		"names": ["front_0", "front_1", "side_0", "side_1", "back_0", "back_1", "broken", "carry"]},
	{"file": "props_sheet.jpg", "type": "icons", "size": 256, "dir": "props",
		"names": ["box", "pallet_boxes", "pallet", "barrel", "cone", "plant", "extinguisher",
				"first_aid", "table", "shelf", "wet_floor", "trash"]},
	{"file": "vehicles_sheet.jpg", "type": "trim", "dir": "vehicles",
		"names": ["forklift", "truck_fini", "truck_supplier", "car", "car_b"]},
	{"file": "ui_sheet.jpg", "type": "icons", "size": 128, "dir": "ui",
		"names": ["heart", "heart_empty", "star", "star_empty", "clock", "coin", "bolt", "alert"]},
	{"file": "logo.jpg", "type": "whole", "dir": "ui", "names": ["logo"]},
]
const POSE_FRAME := Vector2i(128, 160)
const FEET_MARGIN := 8
const WHITE := 0.88          # más claro que esto (y tocando el borde) = fondo
const MERGE_GAP := 22        # piezas a menos de esta distancia son el mismo dibujo


func _initialize() -> void:
	for job: Dictionary in JOBS:
		var img := Image.load_from_file("res://assets/sources/" + job["file"])
		img.convert(Image.FORMAT_RGBA8)
		if job["file"].ends_with(".jpg"):
			_remove_white_background(img)
		var rects: Array[Rect2i] = [_content_rect(img)]
		if job["type"] != "whole":
			rects = _find_sprites(img, job.get("merge", MERGE_GAP), job.get("rows", "center"))
		var scale := 1.0
		if job["type"] == "poses" and job["height"] > 0:
			var tallest := 0
			for rect in rects:
				tallest = maxi(tallest, rect.size.y)
			scale = float(job["height"]) / tallest
		var names: Array = job["names"]
		for i in mini(names.size(), rects.size()):
			if names[i] == "":
				continue
			var part := img.get_region(rects[i])
			match job["type"]:
				"icons":
					part = _square(part, job["size"])
				"poses":
					if scale != 1.0:
						part.resize(roundi(part.get_width() * scale), roundi(part.get_height() * scale), Image.INTERPOLATE_LANCZOS)
					part = _feet_aligned(part)
			var path: String = "res://assets/%s/%s.png" % [job["dir"], names[i]]
			DirAccess.make_dir_recursive_absolute(path.get_base_dir())
			part.save_png(path)
			print(job["file"], " -> ", path.get_file(), "  ", rects[i])
		if rects.size() < names.size():
			print("  ¡OJO! ", job["file"], " tiene ", rects.size(), " dibujos y se esperaban ", names.size())
	quit()


# --- Quitar el fondo blanco (JPG) ---------------------------------------------

## Vuelve transparente el blanco que toca los bordes de la imagen (relleno desde afuera)
## y suaviza el borde de los dibujos para que no quede un halo blanco.
func _remove_white_background(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var visited := PackedByteArray()
	visited.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or visited[p.y * w + p.x] == 1:
			continue
		visited[p.y * w + p.x] = 1
		var c := img.get_pixelv(p)
		if minf(c.r, minf(c.g, c.b)) < WHITE:
			continue
		img.set_pixelv(p, Color(c.r, c.g, c.b, 0.0))
		stack.append(p + Vector2i.RIGHT)
		stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN)
		stack.append(p + Vector2i.UP)
	# bordes suaves: los píxeles claros pegados al fondo quedan semitransparentes
	var copy: Image = img.duplicate()
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c := copy.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var touches := copy.get_pixel(x + 1, y).a == 0.0 or copy.get_pixel(x - 1, y).a == 0.0 \
					or copy.get_pixel(x, y + 1).a == 0.0 or copy.get_pixel(x, y - 1).a == 0.0
			var lightness := minf(c.r, minf(c.g, c.b))
			if touches and lightness > 0.6:
				img.set_pixel(x, y, Color(c.r, c.g, c.b, clampf((1.0 - lightness) / 0.4, 0.0, 1.0)))


# --- Encontrar los dibujos -----------------------------------------------------

## Rectángulos de cada dibujo (zonas no transparentes), juntando piezas cercanas,
## ordenados por filas y de izquierda a derecha.
func _find_sprites(img: Image, merge_gap: int, rows: String) -> Array[Rect2i]:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var found: Array[Rect2i] = []
	for y in h:
		for x in w:
			if seen[y * w + x] == 1 or _is_background(img.get_pixel(x, y)):
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[y * w + x] = 1
			var rect := Rect2i(x, y, 1, 1)
			var count := 0
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				count += 1
				rect = rect.expand(p)
				for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					var q := p + d
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
						continue
					if seen[q.y * w + q.x] == 1 or _is_background(img.get_pixel(q.x, q.y)):
						continue
					seen[q.y * w + q.x] = 1
					stack.append(q)
			if count > (150 if rows == "top" else 40):   # ignora puntitos sueltos
				found.append(rect)
	if merge_gap > 0:
		found = _merge_close(found, merge_gap)
	var min_area := 0 if rows == "top" else 900
	found = found.filter(func(r: Rect2i) -> bool: return r.get_area() > min_area)
	# por filas (según el centro o el borde de arriba, con tolerancia) y luego de izquierda a derecha
	found.sort_custom(func(a: Rect2i, b: Rect2i) -> bool:
		if rows == "top" and absi(a.position.y - b.position.y) > 40:
			return a.position.y < b.position.y
		if rows != "top" and absi(a.get_center().y - b.get_center().y) > 70:
			return a.get_center().y < b.get_center().y
		return a.position.x < b.position.x)
	var result: Array[Rect2i] = []
	for rect in found:
		result.append(rect.grow(2).intersection(Rect2i(0, 0, w, h)))
	return result


## Junta rectángulos que se tocan o están muy cerca (chispas, humo, piezas sueltas).
func _merge_close(rects: Array[Rect2i], gap: int) -> Array[Rect2i]:
	var merged := true
	while merged:
		merged = false
		for i in rects.size():
			for j in range(i + 1, rects.size()):
				if rects[i].grow(gap).intersects(rects[j]):
					rects[i] = rects[i].merge(rects[j])
					rects.remove_at(j)
					merged = true
					break
			if merged:
				break
	return rects


func _content_rect(img: Image) -> Rect2i:
	var used := img.get_used_rect()
	return used.grow(4).intersection(Rect2i(Vector2i.ZERO, img.get_size()))


func _is_background(c: Color) -> bool:
	return c.a < 0.1


# --- Formatos de salida --------------------------------------------------------

## Centra la imagen en un cuadrado transparente y la escala a `size`.
func _square(img: Image, size: int) -> Image:
	var side := maxi(img.get_width(), img.get_height()) + 8
	var canvas := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()),
			Vector2i((side - img.get_width()) / 2, (side - img.get_height()) / 2))
	canvas.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return canvas


## Pone la pose en un cuadro de POSE_FRAME con los pies abajo y centrada.
func _feet_aligned(img: Image) -> Image:
	var canvas := Image.create_empty(POSE_FRAME.x, POSE_FRAME.y, false, Image.FORMAT_RGBA8)
	var pos := Vector2i((POSE_FRAME.x - img.get_width()) / 2, POSE_FRAME.y - FEET_MARGIN - img.get_height())
	canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), pos)
	return canvas
