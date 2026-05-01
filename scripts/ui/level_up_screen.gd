extends CanvasLayer

# Pantalla de subida de nivel.
# Recibe una lista de mejoras desde Main.
# Cuando el jugador elige una, emite upgrade_selected(upgrade).

signal upgrade_selected(upgrade)

var overlay: Control
var buttons: Array[Button] = []
var current_choices: Array = []

func _ready() -> void:
	# Debe estar por encima del HUD y de la pantalla inicial si coincidieran.
	layer = 60
	
	# Debe funcionar con el juego pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	build_ui()

func build_ui() -> void:
	overlay = Control.new()
	overlay.name = "LevelUpOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)
	
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.65)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 310)
	panel.position = Vector2(210, 115)
	overlay.add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	var title := Label.new()
	title.text = "Subida de nivel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var subtitle := Label.new()
	subtitle.text = "Elige una mejora"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	# Creamos 3 botones porque el diseño actual ofrece 3 opciones.
	for i in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(500, 60)
		button.pressed.connect(_on_upgrade_button_pressed.bind(i))
		buttons.append(button)
		vbox.add_child(button)

func show_screen(choices: Array) -> void:
	# Guardamos las opciones actuales para saber qué botón corresponde a qué mejora.
	current_choices = choices
	
	for i in range(buttons.size()):
		# Si algún día hay menos de 3 opciones, ocultamos botones sobrantes.
		if i >= current_choices.size():
			buttons[i].visible = false
			continue
		
		var upgrade = current_choices[i]
		buttons[i].visible = true
		buttons[i].text = upgrade["name"] + "\n" + upgrade["description"]
	
	overlay.visible = true

func hide_screen() -> void:
	overlay.visible = false

func _on_upgrade_button_pressed(index: int) -> void:
	# Seguridad por si llega un índice inválido.
	if index >= current_choices.size():
		return
	
	var upgrade = current_choices[index]
	
	hide_screen()
	
	# Avisamos a Main de qué mejora se eligió.
	upgrade_selected.emit(upgrade)
