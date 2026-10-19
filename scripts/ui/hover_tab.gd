class_name HoverTab
extends Button
## Pestaña del HUD: al pasar el mouse por encima muestra su panel y lo vuelve a
## esconder cuando el mouse sale de la pestaña y del panel (así se pueden usar
## los botones del panel). El texto de la pestaña lo pone hud.gd.

@export var panel: Control


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	panel.visible = false


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		panel.visible = false
		return
	var area := get_global_rect()
	if panel.visible:
		# incluye el hueco entre pestaña y panel para que no parpadee al bajar el mouse
		area = area.merge(panel.get_global_rect())
	panel.visible = area.has_point(get_global_mouse_position())
