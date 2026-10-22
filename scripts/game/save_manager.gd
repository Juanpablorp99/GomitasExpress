extends Node
## GUARDADO DE PARTIDAS (autoload "SaveManager", siempre activo, también en pausa).
##
## Se guarda el PROGRESO, no la mitad de un nivel: niveles desbloqueados, mejores
## estrellas y mejor dinero de cada nivel. Hay SLOT_COUNT ranuras, cada una es un
## archivo JSON en la carpeta de usuario (user://save_1.json ... save_5.json).
##
## - Nueva partida: progreso en cero y sin ranura asignada (no se autoguarda).
## - Cargar / guardar en una ranura: esa pasa a ser la "ranura actual".
## - Al ganar un nivel se autoguarda en la ranura actual (si hay una).
##
## Aparte, en user://settings.cfg se guardan las opciones del jugador (idioma y
## pantalla completa, sonido), que no dependen de la partida.
## F11 o Alt+Enter cambian entre pantalla completa y ventana desde cualquier pantalla.

const SLOT_COUNT := 5
const SAVE_VERSION := 1
const SLOT_PATH := "user://save_%d.json"
const SETTINGS_PATH := "user://settings.cfg"
## Tamaño de la ventana cuando no está en pantalla completa (el juego se diseñó a
## 1280x720 y Godot lo escala: a 1920x1080 todo se ve 1,5 veces más grande).
const WINDOW_SIZE := Vector2i(1920, 1080)

## Ranura en uso (1..SLOT_COUNT) o 0 si la partida todavía no se guardó en ninguna.
var current_slot := 0
## Progreso de la partida actual: { "unlocked": nivel más alto desbloqueado,
##   "stars": [estrellas por nivel], "best_money": [mejor dinero por nivel] }
var progress := {}
var fullscreen := true
## Sonido silenciado con M (ver audio_manager.gd).
var muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	new_game()
	_load_settings()
	_apply_window()


## F11 o Alt+Enter. Se atiende en _input para que Alt+Enter no cuente también como ENTER.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		fullscreen = not fullscreen
		_apply_window()
		save_settings()
		get_viewport().set_input_as_handled()


# --- Partida actual ------------------------------------------------------------

## Empieza de cero: solo el Nivel 1, sin estrellas y sin ranura.
func new_game() -> void:
	current_slot = 0
	progress = _empty_progress()


func is_unlocked(level_number: int) -> bool:
	return level_number <= progress["unlocked"]


func get_stars(level_number: int) -> int:
	return progress["stars"][level_number - 1]


func get_best_money(level_number: int) -> int:
	return progress["best_money"][level_number - 1]


## Lo llama warehouse.gd al ganar un nivel: guarda el MEJOR resultado (jugar peor
## no quita estrellas), desbloquea el siguiente y autoguarda en la ranura actual.
func record_win(level_number: int, stars: int, money: int) -> void:
	var i := level_number - 1
	progress["stars"][i] = maxi(progress["stars"][i], stars)
	progress["best_money"][i] = maxi(progress["best_money"][i], money)
	progress["unlocked"] = clampi(level_number + 1, progress["unlocked"], Levels.count())
	if current_slot > 0:
		save_to_slot(current_slot)


# --- Ranuras -------------------------------------------------------------------

## Guarda la partida actual en `slot` (la sobreescribe si ya tenía algo).
func save_to_slot(slot: int) -> bool:
	var data := progress.duplicate(true)
	data["version"] = SAVE_VERSION
	data["saved_at"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(SLOT_PATH % slot, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar en la ranura %d: %s" % [slot, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	current_slot = slot
	return true


## Carga la partida de `slot`. Devuelve false si está vacía o dañada.
func load_slot(slot: int) -> bool:
	var data := read_slot(slot)
	if data.is_empty():
		return false
	progress = data
	current_slot = slot
	return true


## Datos de una ranura para mostrarla en el menú ({} si está vacía o dañada):
## { "unlocked", "stars", "best_money", "saved_at" }
func read_slot(slot: int) -> Dictionary:
	if not FileAccess.file_exists(SLOT_PATH % slot):
		return {}
	var json := JSON.new()   # (JSON.parse_string mostraría un error en consola si el archivo está dañado)
	if json.parse(FileAccess.get_file_as_string(SLOT_PATH % slot)) != OK or not json.data is Dictionary:
		return {}
	var parsed: Dictionary = json.data
	# JSON guarda los números como decimales: se pasan a enteros. Lo que falte o
	# esté mal (archivo viejo o editado a mano) queda con su valor por defecto.
	var data := _empty_progress()
	data["unlocked"] = clampi(_to_int(parsed.get("unlocked"), 1), 1, Levels.count())
	for list: String in ["stars", "best_money"]:
		var saved = parsed.get(list)
		if saved is Array:
			for i in mini(saved.size(), Levels.count()):
				data[list][i] = maxi(_to_int(saved[i], 0), 0)
	data["stars"] = data["stars"].map(func(value: int) -> int: return mini(value, 3))
	data["saved_at"] = _to_int(parsed.get("saved_at"), 0)
	return data


static func _to_int(value, default: int) -> int:
	return int(value) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else default


func has_any_save() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if not read_slot(slot).is_empty():
			return true
	return false


func _empty_progress() -> Dictionary:
	var zeros := []
	zeros.resize(Levels.count())
	zeros.fill(0)
	return {"unlocked": 1, "stars": zeros.duplicate(), "best_money": zeros.duplicate()}


# --- Opciones (idioma y pantalla) ----------------------------------------------

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "language", Lang.current)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("audio", "muted", muted)
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	Lang.current = config.get_value("game", "language", Lang.current)
	fullscreen = config.get_value("display", "fullscreen", fullscreen)
	muted = config.get_value("audio", "muted", muted)


## Pantalla completa, o ventana de 1920x1080 centrada (más chica si el monitor no da).
func _apply_window() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var size := WINDOW_SIZE
	if size.x > usable.size.x or size.y > usable.size.y:
		var scale := minf(float(usable.size.x) / size.x, float(usable.size.y) / size.y) * 0.95
		size = Vector2i(Vector2(size) * scale)
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)
