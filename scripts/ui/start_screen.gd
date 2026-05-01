extends CanvasLayer

# Pantalla inicial de la run.
# No inicia la run directamente.
# Solo emite start_pressed y Main decide qué hacer.

signal start_pressed

var overlay: Control
var info_label: Label

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
	
	# Panel central.
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 360)
	panel.position = Vector2(200, 90)
	overlay.add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	var title := Label.new()
	title.text = "Piso Survivor"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)
	
	# Texto dinámico con duración, ahorro meta y desbloqueos.
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_label)
	
	var start_button := Button.new()
	start_button.text = "Empezar run"
	start_button.custom_minimum_size = Vector2(360, 54)
	start_button.pressed.connect(_on_start_button_pressed)
	vbox.add_child(start_button)

func show_screen(run_duration_seconds: float, meta_savings: int, meta_unlock_text: String) -> void:
	# Main llama a esto para mostrar los datos actuales antes de empezar.
	info_label.text = "Objetivo: sobrevivir %s segundos\n\nAhorro meta total: %s\n\nDesbloqueos meta:\n%s" % [
		int(run_duration_seconds),
		meta_savings,
		meta_unlock_text
	]
	
	overlay.visible = true

func hide_screen() -> void:
	overlay.visible = false

func _on_start_button_pressed() -> void:
	# La pantalla solo avisa.
	# Main recibe la señal y arranca la run.
	start_pressed.emit()
