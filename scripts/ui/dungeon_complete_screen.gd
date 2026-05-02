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
	panel.custom_minimum_size = Vector2(720, 520)
	center_container.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Mazmorra completada"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	# El texto largo va dentro de un scroll para que no empuje los botones.
	var info_scroll := ScrollContainer.new()
	info_scroll.custom_minimum_size = Vector2(640, 270)
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	info_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(info_scroll)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_scroll.add_child(info_label)

	var return_button := Button.new()
	return_button.text = "Volver a casa y asegurar recompensas"
	return_button.custom_minimum_size = Vector2(460, 50)
	return_button.pressed.connect(_on_return_button_pressed)
	vbox.add_child(return_button)

	var portal_button := Button.new()
	portal_button.text = "Abrir portal a una mazmorra más difícil"
	portal_button.custom_minimum_size = Vector2(460, 50)
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

	info_label.text = "Has completado la mazmorra de dificultad %s.\n\nRECOMPENSAS EN RIESGO\nOro acumulado: %s\nLoot acumulado:\n%s\n\nOPCIONES\nVolver a casa:\n- Guardas todo el loot acumulado.\n- Guardas todo el oro acumulado.\n- Conservas el equipo equipado.\n\nAbrir portal:\n- Entras en una mazmorra de dificultad %s.\n- Las recompensas serán mejores.\n- Nada se guarda todavía.\n- Si mueres, pierdes equipo equipado, loot acumulado y oro acumulado." % [
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
