extends CanvasLayer

# Pantalla que aparece al completar una mazmorra.
# El jugador decide si asegura recompensas o continúa por portal.

signal return_home_pressed
signal open_portal_pressed

var overlay: Control = null
var info_label: Label = null


func _ready() -> void:
	layer = 65
	process_mode = Node.PROCESS_MODE_ALWAYS

	build_ui()


func build_ui() -> void:
	overlay = Control.new()
	overlay.name = "DungeonCompleteOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.82)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)

	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_container)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 420)
	center_container.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Mazmorra completada"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_label)

	var return_button := Button.new()
	return_button.text = "Volver a casa y asegurar recompensas"
	return_button.custom_minimum_size = Vector2(440, 52)
	return_button.pressed.connect(_on_return_button_pressed)
	vbox.add_child(return_button)

	var portal_button := Button.new()
	portal_button.text = "Abrir portal a una mazmorra más difícil"
	portal_button.custom_minimum_size = Vector2(440, 52)
	portal_button.pressed.connect(_on_portal_button_pressed)
	vbox.add_child(portal_button)


func show_screen(
	current_difficulty: int,
	next_difficulty: int,
	run_gold: int,
	loot_text: String
) -> void:
	if loot_text.is_empty():
		loot_text = "- Ninguno"

	info_label.text = "Has completado la mazmorra de dificultad %s.\n\nRecompensas en riesgo:\nOro acumulado: %s\nLoot acumulado:\n%s\n\nPuedes volver a casa para guardar todo, o abrir un portal a dificultad %s.\nSi mueres después, perderás todo lo acumulado y el equipo equipado." % [
		current_difficulty,
		run_gold,
		loot_text,
		next_difficulty
	]

	overlay.visible = true


func hide_screen() -> void:
	overlay.visible = false


func _on_return_button_pressed() -> void:
	return_home_pressed.emit()


func _on_portal_button_pressed() -> void:
	open_portal_pressed.emit()
