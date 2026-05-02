extends CanvasLayer

# Pantalla final de la run.
# Muestra el resultado de la mazmorra y permite volver al menú.

signal restart_pressed

var overlay: Control = null
var result_label: Label = null


func _ready() -> void:
	# Capa más alta de las pantallas actuales.
	layer = 70
	
	# Debe responder aunque el juego esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	build_ui()


func build_ui() -> void:
	overlay = Control.new()
	overlay.name = "RunEndOverlay"
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
	panel.custom_minimum_size = Vector2(620, 460)
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
	
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(result_label)
	
	var restart_button := Button.new()
	restart_button.text = "Volver al menú"
	restart_button.custom_minimum_size = Vector2(360, 54)
	restart_button.pressed.connect(_on_restart_button_pressed)
	vbox.add_child(restart_button)


func show_screen(victory: bool, result_text: String) -> void:
	# Main ya construye el texto de resultado.
	# Esta pantalla solo lo muestra.

	var title := "Has caído"

	if victory:
		title = "Mazmorra completada"

	result_label.text = "%s\n\n%s" % [
		title,
		result_text
	]
	
	overlay.visible = true


func hide_screen() -> void:
	overlay.visible = false


func _on_restart_button_pressed() -> void:
	# La pantalla no recarga la escena directamente.
	# Main recibe la señal y decide cómo reiniciar.
	restart_pressed.emit()
