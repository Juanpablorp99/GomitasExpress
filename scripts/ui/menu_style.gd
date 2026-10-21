class_name MenuStyle
## Estilos compartidos de los menús que se arman por código (ranuras y selector de
## niveles), con los mismos colores que el HUD y la pantalla de título.

const PANEL_BG := Color(0.1, 0.08, 0.15, 0.95)
const PANEL_BORDER := Color(1, 0.45, 0.7)
const TITLE_COLOR := Color(1, 0.85, 0.3)
const PRIMARY := Color(0.86, 0.15, 0.22)
const SECONDARY := Color(0.2, 0.55, 0.85)
const DISABLED := Color(0.3, 0.28, 0.34)


## Fondo oscuro que tapa la pantalla y bloquea los clics de lo que hay detrás.
static func backdrop() -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(0.05, 0.03, 0.1, 0.88)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


## Panel centrado con borde rosa; devuelve el VBoxContainer donde va el contenido.
static func centered_panel(parent: Control, min_width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL_BG, PANEL_BORDER, 3, 14, 22))
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = min_width
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	return content


static func title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", TITLE_COLOR)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)
	return label


static func text(value: String, size := 18, color := Color(0.85, 0.85, 0.95)) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


## Botón redondeado: rojo (principal) o azul (secundario). Sin foco de teclado,
## igual que el resto de los botones del juego.
static func button(value: String, primary := false, size := 22) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 50
	button.add_theme_font_size_override("font_size", size)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.65, 0.63, 0.7))
	var color := PRIMARY if primary else SECONDARY
	button.add_theme_stylebox_override("normal", _box(color, color.darkened(0.6), 4, 14, 16))
	button.add_theme_stylebox_override("hover", _box(color.lightened(0.15), color.darkened(0.6), 4, 14, 16))
	button.add_theme_stylebox_override("pressed", _box(color.darkened(0.1), color.darkened(0.6), 4, 14, 16))
	button.add_theme_stylebox_override("disabled", _box(DISABLED, DISABLED.darkened(0.4), 4, 14, 16))
	return button


static func _box(bg: Color, border: Color, border_width: int, radius: int, margin: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = margin * 0.6
	box.content_margin_bottom = margin * 0.6
	return box
