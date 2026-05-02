extends CanvasLayer

# Pantalla inicial del juego.
# No inicia la run directamente.
# Solo emite start_pressed y Main decide qué hacer.

signal start_pressed

var overlay: Control = null
var info_label: Label = null


func _ready() -> void:
	# Capa alta para que aparezca por encima del juego y del HUD.
	layer = 50
	
	# Debe funcionar aunque el árbol esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	build_ui()


func build_ui() -> void:
	# Overlay completo de pantalla.
	overlay = Control.new()
	overlay.name = "StartOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)
	
	# Fondo oscuro semitransparente.
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.78)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	
	# Contenedor centrado.
	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_container)
	
	# Panel central.
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 440)
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
	title.text = "Dungeon Roguelite"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)
	
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_label)
	
	var start_button := Button.new()
	start_button.text = "Entrar en la mazmorra"
	start_button.custom_minimum_size = Vector2(360, 54)
	start_button.pressed.connect(_on_start_button_pressed)
	vbox.add_child(start_button)


func show_screen(gold: int, inventory_text: String, equipped_weapon_text: String) -> void:
	# Main llama a esto para mostrar el estado persistente antes de empezar.
	# Esta pantalla ya no usa duración, ahorro meta ni desbloqueos antiguos.

	info_label.text = "Oro: %s\n\nInventario persistente:\n%s\n\nEquipo para la próxima run:\n%s" % [
		gold,
		inventory_text,
		equipped_weapon_text
	]
	
	overlay.visible = true


func hide_screen() -> void:
	overlay.visible = false


func _on_start_button_pressed() -> void:
	# La pantalla solo avisa.
	# Main recibe la señal y arranca la run.
	start_pressed.emit()
