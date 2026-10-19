extends Control
## Pantalla de inicio: logo, gomitas cayendo de fondo y botones JUGAR / IDIOMA / SALIR.
## ENTER también empieza el juego y L cambia el idioma.

const GUMMY_COUNT := 26

var _gummies: Array[Dictionary] = []   # { "id", "pos", "speed", "spin", "size" }
var _time := 0.0

@onready var logo: TextureRect = $Logo
@onready var subtitle: Label = $Subtitle
@onready var play_button: Button = $Buttons/PlayButton
@onready var language_button: Button = $Buttons/LanguageButton
@onready var quit_button: Button = $Buttons/QuitButton
@onready var controls_label: Label = $ControlsLabel


func _ready() -> void:
	logo.texture = Art.LOGO
	play_button.pressed.connect(_play)
	language_button.pressed.connect(_toggle_language)
	quit_button.pressed.connect(get_tree().quit)
	var ids: Array = Products.INFO.keys()
	for i in GUMMY_COUNT:
		_gummies.append({"id": ids[i % ids.size()], "pos": Vector2(randf() * 1280, randf() * 720),
				"speed": randf_range(30, 80), "spin": randf_range(-1.5, 1.5), "size": randf_range(40, 80)})
	_update_texts()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_play()
	elif event.is_action_pressed("toggle_language"):
		_toggle_language()


func _process(delta: float) -> void:
	_time += delta
	var height := size.y
	for gummy in _gummies:
		gummy["pos"].y += gummy["speed"] * delta
		if gummy["pos"].y > height + 60:
			gummy["pos"] = Vector2(randf() * size.x, -60)
	# el logo "respira" un poco
	logo.scale = Vector2.ONE * (1.0 + 0.02 * sin(_time * 2.0))
	queue_redraw()


func _draw() -> void:
	# fondo con franjas de colores de gomita y gomitas cayendo
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.93, 0.85))
	var stripe_colors := [Color(1, 0.86, 0.86), Color(1, 0.95, 0.8), Color(0.88, 0.97, 0.86)]
	var stripe := 90.0
	for i in ceili((size.x + size.y) / stripe) + 1:
		var x := i * stripe - size.y + fmod(_time * 20.0, stripe * 3)
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + stripe, 0),
				Vector2(x + stripe + size.y, size.y), Vector2(x + size.y, size.y)]), stripe_colors[i % 3])
	for gummy in _gummies:
		var gummy_size: float = gummy["size"]
		draw_set_transform(gummy["pos"], _time * gummy["spin"])
		draw_texture_rect(Art.PRODUCTS[gummy["id"]], Rect2(-Vector2.ONE * gummy_size / 2, Vector2.ONE * gummy_size), false, Color(1, 1, 1, 0.55))
	draw_set_transform(Vector2.ZERO)


func _play() -> void:
	Levels.stars_won = [0, 0, 0]
	get_tree().change_scene_to_file(Levels.SCENES[0])


func _toggle_language() -> void:
	Lang.toggle()
	_update_texts()


func _update_texts() -> void:
	play_button.text = Lang.t("TITLE_PLAY")
	language_button.text = Lang.t("TITLE_LANGUAGE")
	quit_button.text = Lang.t("TITLE_QUIT")
	subtitle.text = Lang.t("TITLE_SUBTITLE")
	controls_label.text = Lang.t("CONTROLS")
