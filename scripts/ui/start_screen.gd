extends CanvasLayer

# Pantalla inicial del juego.
# Muestra oro, inventario persistente y permite elegir arma.

signal start_pressed
signal weapon_selected(item_id: String)

var overlay: Control = null
var info_label: Label = null
var weapon_option_button: OptionButton = null


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	build_ui()


func build_ui() -> void:
	overlay = Control.new()
	overlay.name = "StartOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)
	
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.78)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	
	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_container)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(660, 500)
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

	var weapon_title := Label.new()
	weapon_title.text = "Arma equipada"
	weapon_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(weapon_title)

	weapon_option_button = OptionButton.new()
	weapon_option_button.custom_minimum_size = Vector2(360, 42)
	weapon_option_button.item_selected.connect(_on_weapon_option_selected)
	vbox.add_child(weapon_option_button)
	
	var start_button := Button.new()
	start_button.text = "Entrar en la mazmorra"
	start_button.custom_minimum_size = Vector2(360, 54)
	start_button.pressed.connect(_on_start_button_pressed)
	vbox.add_child(start_button)


func show_screen(
	gold: int,
	inventory_text: String,
	equipped_weapon_text: String,
	weapon_options: Array[Dictionary],
	selected_weapon_id: String
) -> void:
	info_label.text = "Oro: %s\n\nInventario persistente:\n%s\n\n%s" % [
		gold,
		inventory_text,
		equipped_weapon_text
	]

	refresh_weapon_options(weapon_options, selected_weapon_id)
	
	overlay.visible = true


func refresh_weapon_options(weapon_options: Array[Dictionary], selected_weapon_id: String) -> void:
	weapon_option_button.clear()

	# Opción para entrar sin arma.
	weapon_option_button.add_item("Sin arma")
	weapon_option_button.set_item_metadata(0, "")

	var selected_index: int = 0

	for weapon_data: Dictionary in weapon_options:
		var item_id: String = str(weapon_data.get("id", ""))
		var item_name: String = str(weapon_data.get("name", "Arma desconocida"))

		if item_id.is_empty():
			continue

		var index: int = weapon_option_button.item_count
		weapon_option_button.add_item(item_name)
		weapon_option_button.set_item_metadata(index, item_id)

		if item_id == selected_weapon_id:
			selected_index = index

	weapon_option_button.select(selected_index)


func hide_screen() -> void:
	overlay.visible = false


func _on_weapon_option_selected(index: int) -> void:
	var item_id: String = str(weapon_option_button.get_item_metadata(index))
	weapon_selected.emit(item_id)


func _on_start_button_pressed() -> void:
	start_pressed.emit()
