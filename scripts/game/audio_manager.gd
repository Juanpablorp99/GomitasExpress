extends Node
## SONIDO (autoload "AudioManager", siempre activo, también en pausa).
##
## Música de fondo: AudioManager.play_music("level_1") -> assets/audio/music/level_1.wav
## Efectos:         AudioManager.play("deliver")       -> assets/audio/sfx/deliver.wav
## Para cambiar un sonido basta con reemplazar el .wav (u .ogg) con el mismo nombre.
## Los sonidos originales se generan con tools/generate_audio.js.
##
## Todos los botones del juego hacen "click" solos (ver _on_node_added).
## M silencia / activa el sonido (se guarda en settings.cfg con SaveManager).

const MUSIC_PATH := "res://assets/audio/music/%s"
const SFX_PATH := "res://assets/audio/sfx/%s"
const EXTENSIONS := [".ogg", ".wav"]
const SFX_PLAYERS := 8           # efectos que pueden sonar a la vez
const MUSIC_VOLUME_DB := -8.0
const PAUSED_VOLUME_DB := -20.0  # la música baja en el menú de pausa
const FADE_TIME := 0.6

var _music: AudioStreamPlayer
var _music_name := ""
var _fade: Tween
var _sfx: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_VOLUME_DB
	_music.finished.connect(_music.play)   # repetir la canción en bucle
	add_child(_music)
	for i in SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		_sfx.append(player)
		add_child(player)
	get_tree().node_added.connect(_on_node_added)
	_apply_mute()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mute"):
		SaveManager.muted = not SaveManager.muted
		_apply_mute()
		SaveManager.save_settings()


## Cambia la música de fondo (no hace nada si ya está sonando esa).
func play_music(track: String) -> void:
	if track == _music_name and _music.playing:
		return
	var stream := _load(MUSIC_PATH, track)
	if stream == null:
		return
	_music_name = track
	_music.stream = stream
	_music.volume_db = -40.0
	_music.play()
	_fade_music_to(MUSIC_VOLUME_DB)


func stop_music() -> void:
	_music_name = ""
	_music.stop()


## Baja la música mientras el juego está en pausa.
func set_paused(paused: bool) -> void:
	_fade_music_to(PAUSED_VOLUME_DB if paused else MUSIC_VOLUME_DB, 0.25)


## Efecto de sonido. `pitch_variation` lo hace sonar un poco distinto cada vez.
func play(sound: String, volume_db := 0.0, pitch_variation := 0.0) -> void:
	var stream := _load(SFX_PATH, sound)
	if stream == null:
		return
	var player := _sfx[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


func _fade_music_to(volume_db: float, time := FADE_TIME) -> void:
	if _fade != null:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_music, "volume_db", volume_db, time)


func _apply_mute() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), SaveManager.muted)


## Busca el archivo .ogg o .wav y lo guarda en memoria. null si no existe.
func _load(folder: String, sound: String) -> AudioStream:
	var key := folder % sound
	if not _cache.has(key):
		_cache[key] = null
		for extension: String in EXTENSIONS:
			var path := key + extension
			if ResourceLoader.exists(path):
				_cache[key] = load(path)
				break
		if _cache[key] == null:
			push_warning("Falta el sonido: " + key)
	return _cache[key]


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play.bind("click", -4.0))
