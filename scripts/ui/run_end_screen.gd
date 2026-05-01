extends CanvasLayer

# Pantalla final de la run.
# Muestra estadísticas y emite restart_pressed cuando el jugador quiere otra run.

signal restart_pressed

var overlay: Control
var result_label: Label

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
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 460)
	panel.position = Vector2(170, 40)
	overlay.add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	# Texto principal de resultados.
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(result_label)
	
	var restart_button := Button.new()
	restart_button.text = "Nueva run"
	restart_button.custom_minimum_size = Vector2(360, 54)
	restart_button.pressed.connect(_on_restart_button_pressed)
	vbox.add_child(restart_button)

func show_screen(
	victory: bool,
	survived_time: int,
	level: int,
	enemies_killed: int,
	total_xp_collected: int,
	total_coins_collected: int,
	secured_savings: int,
	meta_savings: int,
	upgrades_text: String
) -> void:
	# Construye el texto final de la run.
	var result_text := "Has caído"
	
	if victory:
		result_text = "Run completada"
	
	result_label.text = "%s\n\nTiempo sobrevivido: %ss\nNivel alcanzado: %s\nEnemigos eliminados: %s\nXP recogida: %s\nMonedas recogidas: %s\nAhorro asegurado: +%s\nAhorro meta total: %s\n\nMejoras elegidas:\n%s" % [
		result_text,
		survived_time,
		level,
		enemies_killed,
		total_xp_collected,
		total_coins_collected,
		secured_savings,
		meta_savings,
		upgrades_text
	]
	
	overlay.visible = true

func hide_screen() -> void:
	overlay.visible = false

func _on_restart_button_pressed() -> void:
	# La pantalla no recarga la escena directamente.
	# Main recibe la señal y decide cómo reiniciar.
	restart_pressed.emit()
