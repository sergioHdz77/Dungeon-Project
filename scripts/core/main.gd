extends Node2D

const ItemDatabase = preload("res://scripts/data/item_database.gd")

# Referencias principales de la escena.
@onready var dungeon_manager: Node = get_node_or_null("DungeonManager")
@onready var player: Node = get_node_or_null("Player")
@onready var hud: Node = get_node_or_null("HUD")
@onready var start_screen: Node = get_node_or_null("StartScreen")
@onready var run_end_screen: Node = get_node_or_null("RunEndScreen")
@onready var dungeon_complete_screen: Node = get_node_or_null("DungeonCompleteScreen")

# Estado de la run actual.
var run_active: bool = false

# Dificultad elegida en el menú para empezar una cadena de mazmorras.
var selected_starting_difficulty: int = 1

# Dificultad actual dentro de la cadena.
var current_difficulty: int = 1

# Dificultad máxima seleccionable desde el menú.
# Más adelante puede depender de progreso/desbloqueos.
var max_starting_difficulty: int = 3

# Loot conseguido durante la run actual.
# Si el jugador gana, pasa al inventario persistente.
# Si el jugador muere, se pierde.
var run_loot: Array[Dictionary] = []

func _ready() -> void:
	randomize()

	connect_player_signals()
	connect_dungeon_signals()
	connect_ui_signals()

	update_hud()
	show_start_screen()


# -------------------------------------------------------------------
# CONEXIÓN DE SEÑALES
# -------------------------------------------------------------------

func connect_player_signals() -> void:
	if player == null:
		return

	if player.has_signal("stats_changed"):
		player.stats_changed.connect(update_hud)

	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)


func connect_dungeon_signals() -> void:
	if dungeon_manager == null:
		return

	if dungeon_manager.has_signal("dungeon_completed"):
		dungeon_manager.dungeon_completed.connect(_on_dungeon_completed)

	if dungeon_manager.has_signal("item_collected"):
		dungeon_manager.item_collected.connect(_on_item_collected)


func connect_ui_signals() -> void:
	if start_screen != null:
		if start_screen.has_signal("start_pressed"):
			start_screen.start_pressed.connect(_on_start_button_pressed)

		if start_screen.has_signal("weapon_selected"):
			start_screen.weapon_selected.connect(_on_weapon_selected)

		if start_screen.has_signal("armor_selected"):
			start_screen.armor_selected.connect(_on_armor_selected)

		if start_screen.has_signal("difficulty_selected"):
			start_screen.difficulty_selected.connect(_on_difficulty_selected)

	if dungeon_complete_screen != null:
		if dungeon_complete_screen.has_signal("return_home_pressed"):
			dungeon_complete_screen.return_home_pressed.connect(_on_return_home_pressed)

		if dungeon_complete_screen.has_signal("open_portal_pressed"):
			dungeon_complete_screen.open_portal_pressed.connect(_on_open_portal_pressed)

	if run_end_screen != null:
		if run_end_screen.has_signal("restart_pressed"):
			run_end_screen.restart_pressed.connect(_on_restart_button_pressed)


# -------------------------------------------------------------------
# PANTALLA INICIAL
# -------------------------------------------------------------------

func show_start_screen() -> void:
	if start_screen != null:
		if start_screen.has_method("show_screen"):
			var inventory_text: String = SaveManager.get_inventory_text()

			var selected_weapon_id: String = get_valid_selected_weapon_id()
			var selected_armor_id: String = get_valid_selected_armor_id()

			var equipment_text: String = get_equipment_menu_text(
				selected_weapon_id,
				selected_armor_id
			)

			var weapon_options: Array[Dictionary] = get_weapon_options_from_inventory()
			var armor_options: Array[Dictionary] = get_armor_options_from_inventory()

			start_screen.show_screen(
				SaveManager.persistent_gold,
				inventory_text,
				equipment_text,
				weapon_options,
				selected_weapon_id,
				armor_options,
				selected_armor_id,
				selected_starting_difficulty,
				max_starting_difficulty
			)
		else:
			start_screen.visible = true

	get_tree().paused = true
	

func _on_start_button_pressed() -> void:
	hide_start_screen()
	start_dungeon_run()


func hide_start_screen() -> void:
	if start_screen == null:
		return

	if start_screen.has_method("hide_screen"):
		start_screen.hide_screen()
	else:
		start_screen.visible = false

func start_dungeon_at_current_difficulty() -> void:
	if dungeon_manager != null:
		if dungeon_manager.has_method("create_test_dungeon"):
			dungeon_manager.create_test_dungeon(current_difficulty)

# -------------------------------------------------------------------
# INICIO DE RUN
# -------------------------------------------------------------------

func start_dungeon_run() -> void:
	get_tree().paused = false
	run_active = true

	# La cadena de mazmorras empieza en la dificultad elegida.
	current_difficulty = selected_starting_difficulty

	# El loot temporal siempre empieza vacío al iniciar una cadena nueva.
	run_loot.clear()

	# Equipamiento elegido desde el menú.
	equip_selected_weapon_from_inventory()
	equip_selected_armor_from_inventory()

	start_dungeon_at_current_difficulty()

	update_hud()


# -------------------------------------------------------------------
# FINAL DE RUN
# -------------------------------------------------------------------

func _on_player_died() -> void:
	if not run_active:
		return

	finish_run(false)


func _on_dungeon_completed() -> void:
	if not run_active:
		return

	show_dungeon_complete_screen()

func show_dungeon_complete_screen() -> void:
	if dungeon_complete_screen == null:
		# Fallback por seguridad.
		finish_run(true)
		return

	var run_gold: int = get_run_gold()
	var loot_text: String = get_run_loot_text()

	if loot_text.is_empty():
		loot_text = "- Ninguno"

	if dungeon_complete_screen.has_method("show_screen"):
		dungeon_complete_screen.show_screen(
			current_difficulty,
			current_difficulty + 1,
			run_gold,
			loot_text
		)
	else:
		dungeon_complete_screen.visible = true

	get_tree().paused = true


func _on_return_home_pressed() -> void:
	# El jugador decide asegurar lo conseguido.
	# Ahora sí se guarda loot y oro persistente.

	if dungeon_complete_screen != null:
		if dungeon_complete_screen.has_method("hide_screen"):
			dungeon_complete_screen.hide_screen()

	finish_run(true)


func _on_open_portal_pressed() -> void:
	# El jugador decide arriesgar lo conseguido.
	# No guardamos nada todavía.
	# Subimos dificultad y generamos otra mazmorra.

	if dungeon_complete_screen != null:
		if dungeon_complete_screen.has_method("hide_screen"):
			dungeon_complete_screen.hide_screen()

	get_tree().paused = false

	current_difficulty += 1

	print("Abriendo portal a dificultad: ", current_difficulty)

	start_dungeon_at_current_difficulty()
	update_hud()


func finish_run(victory: bool) -> void:
	run_active = false

	var run_gold: int = get_run_gold()
	var lost_equipment_text: String = ""

	if victory:
		apply_victory_rewards(run_gold)
	else:
		lost_equipment_text = apply_death_penalties()

	update_hud()

	var result_text: String = build_run_result_text(
		victory,
		run_gold,
		lost_equipment_text
	)

	show_run_end_screen(victory, result_text)

	get_tree().paused = true


func apply_victory_rewards(run_gold: int) -> void:
	# Si gana, el loot de run pasa al inventario persistente.
	if not run_loot.is_empty():
		SaveManager.add_inventory_items(run_loot)

		print("Inventario persistente actual:")
		print(SaveManager.get_inventory_text())

	# Si gana, también conserva las monedas recogidas durante la run.
	if run_gold > 0:
		SaveManager.add_gold(run_gold)


func apply_death_penalties() -> String:
	# Si muere:
	# - pierde equipo equipado
	# - pierde loot de run
	# - pierde oro de run

	return lose_equipped_items_on_death()


func show_run_end_screen(victory: bool, result_text: String) -> void:
	if run_end_screen == null:
		return

	if run_end_screen.has_method("show_screen"):
		run_end_screen.show_screen(
			victory,
			result_text
		)
	else:
		run_end_screen.visible = true


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# -------------------------------------------------------------------
# TEXTO DE RESULTADO
# -------------------------------------------------------------------

func build_run_result_text(
	victory: bool,
	run_gold: int,
	lost_equipment_text: String
) -> String:
	if victory:
		return build_victory_result_text(run_gold)

	return build_defeat_result_text(run_gold, lost_equipment_text)


func build_victory_result_text(run_gold: int) -> String:
	var result_text: String = ""

	result_text += "Oro conseguido: %s\n" % run_gold
	result_text += "Oro total: %s\n\n" % SaveManager.persistent_gold

	if run_loot.is_empty():
		result_text += "No has conseguido loot."
	else:
		result_text += "Loot conseguido:\n"
		result_text += get_run_loot_text()
		result_text += "\nGuardado en inventario persistente."

	return result_text


func build_defeat_result_text(run_gold: int, lost_equipment_text: String) -> String:
	var result_text: String = ""

	result_text += lost_equipment_text
	result_text += "\n\nOro perdido: %s\n" % run_gold
	result_text += "\nLoot perdido:\n"

	if run_loot.is_empty():
		result_text += "- Ninguno"
	else:
		result_text += get_run_loot_text()

	return result_text


func get_run_loot_text() -> String:
	var text: String = ""

	for item_data: Dictionary in run_loot:
		var item_name: String = str(item_data.get("name", "Objeto desconocido"))
		text += "- %s\n" % item_name

	return text


# -------------------------------------------------------------------
# LOOT DE RUN
# -------------------------------------------------------------------

func _on_item_collected(item_id: String, display_name: String) -> void:
	var item_data: Dictionary = {
		"id": item_id,
		"name": display_name
	}

	run_loot.append(item_data)

	print("Loot de run añadido: ", display_name, " | id: ", item_id)


# -------------------------------------------------------------------
# EQUIPAMIENTO PROVISIONAL
# -------------------------------------------------------------------

func get_auto_equipped_weapon_text() -> String:
	for item_data: Dictionary in SaveManager.persistent_inventory:
		var item_id: String = str(item_data.get("id", ""))

		if item_id.is_empty():
			continue

		if ItemDatabase.is_weapon(item_id):
			var weapon_name: String = ItemDatabase.get_item_name(item_id)
			return "Arma: %s" % weapon_name

	return "Arma: ninguna"


func equip_selected_weapon_from_inventory() -> void:
	if player == null:
		return

	if not player.has_method("equip_weapon"):
		return

	var selected_weapon_id: String = get_valid_selected_weapon_id()

	if selected_weapon_id.is_empty():
		print("El jugador entra sin arma equipada.")
		return

	player.equip_weapon(selected_weapon_id)


func equip_selected_armor_from_inventory() -> void:
	if player == null:
		return

	if not player.has_method("equip_armor"):
		return

	var selected_armor_id: String = get_valid_selected_armor_id()

	if selected_armor_id.is_empty():
		print("El jugador entra sin armadura equipada.")
		return

	player.equip_armor(selected_armor_id)

func _on_weapon_selected(item_id: String) -> void:
	# Guarda el arma elegida desde el menú.
	# Si item_id está vacío, el jugador entra sin arma.

	SaveManager.set_equipped_weapon(item_id)
	show_start_screen()

func _on_armor_selected(item_id: String) -> void:
	SaveManager.set_equipped_armor(item_id)
	show_start_screen()

func lose_equipped_items_on_death() -> String:
	if player == null:
		return "No había equipo equipado."

	var lost_lines: Array[String] = []

	# Arma equipada.
	if player.has_method("get_equipped_weapon_id"):
		var weapon_id: String = player.get_equipped_weapon_id()

		if not weapon_id.is_empty():
			var weapon_name: String = "Arma desconocida"

			if player.has_method("get_equipped_weapon_name"):
				weapon_name = player.get_equipped_weapon_name()

			var removed_weapon: bool = SaveManager.remove_inventory_item_once(weapon_id)

			if removed_weapon:
				SaveManager.clear_equipped_weapon()
				lost_lines.append("- %s" % weapon_name)

	# Armadura equipada.
	if player.has_method("get_equipped_armor_id"):
		var armor_id: String = player.get_equipped_armor_id()

		if not armor_id.is_empty():
			var armor_name: String = "Armadura desconocida"

			if player.has_method("get_equipped_armor_name"):
				armor_name = player.get_equipped_armor_name()

			var removed_armor: bool = SaveManager.remove_inventory_item_once(armor_id)

			if removed_armor:
				SaveManager.clear_equipped_armor()
				lost_lines.append("- %s" % armor_name)

	if lost_lines.is_empty():
		return "No había equipo equipado."

	var text: String = "Equipo perdido:\n"

	for line in lost_lines:
		text += "%s\n" % line

	return text.strip_edges()


# -------------------------------------------------------------------
# HUD / DATOS DE RUN
# -------------------------------------------------------------------

func update_hud() -> void:
	if hud == null:
		return

	if hud.has_method("update_hud") and player != null:
		hud.update_hud(
			player,
			0,
			0,
			current_difficulty
		)


func get_run_gold() -> int:
	if player == null:
		return 0

	if player.has_method("get_run_coins"):
		return player.get_run_coins()

	return 0
	
func get_weapon_options_from_inventory() -> Array[Dictionary]:
	# Devuelve armas únicas para el desplegable.
	# Si tienes 3 espadas iguales, aparece una vez como "Espada x3".

	var weapon_counts: Dictionary = {}

	for item_data: Dictionary in SaveManager.persistent_inventory:
		var item_id: String = str(item_data.get("id", ""))

		if item_id.is_empty():
			continue

		if not ItemDatabase.is_weapon(item_id):
			continue

		if not weapon_counts.has(item_id):
			weapon_counts[item_id] = 0

		weapon_counts[item_id] += 1

	var weapons: Array[Dictionary] = []

	for item_id: String in weapon_counts.keys():
		var count: int = int(weapon_counts[item_id])
		var item_name: String = ItemDatabase.get_item_name(item_id)

		var display_name: String = "%s x%s" % [
			item_name,
			count
		]

		weapons.append({
			"id": item_id,
			"name": display_name
		})

	return weapons

func get_valid_selected_weapon_id() -> String:
	var selected_weapon_id: String = SaveManager.equipped_weapon_id

	if selected_weapon_id.is_empty():
		return ""

	if inventory_contains_item_id(selected_weapon_id) and ItemDatabase.is_weapon(selected_weapon_id):
		return selected_weapon_id

	# Si el arma guardada ya no existe, limpiamos la selección.
	SaveManager.clear_equipped_weapon()
	return ""
	
func get_armor_options_from_inventory() -> Array[Dictionary]:
	# Devuelve armaduras únicas para el desplegable.
	# Si tienes 3 cotas iguales, aparece una vez como "Cota x3".

	var armor_counts: Dictionary = {}

	for item_data: Dictionary in SaveManager.persistent_inventory:
		var item_id: String = str(item_data.get("id", ""))

		if item_id.is_empty():
			continue

		if not ItemDatabase.is_armor(item_id):
			continue

		if not armor_counts.has(item_id):
			armor_counts[item_id] = 0

		armor_counts[item_id] += 1

	var armors: Array[Dictionary] = []

	for item_id: String in armor_counts.keys():
		var count: int = int(armor_counts[item_id])
		var item_name: String = ItemDatabase.get_item_name(item_id)

		var display_name: String = "%s x%s" % [
			item_name,
			count
		]

		armors.append({
			"id": item_id,
			"name": display_name
		})

	return armors


func get_valid_selected_armor_id() -> String:
	var selected_armor_id: String = SaveManager.equipped_armor_id

	if selected_armor_id.is_empty():
		return ""

	if inventory_contains_item_id(selected_armor_id) and ItemDatabase.is_armor(selected_armor_id):
		return selected_armor_id

	SaveManager.clear_equipped_armor()
	return ""


func get_equipment_menu_text(selected_weapon_id: String, selected_armor_id: String) -> String:
	var weapon_text: String = "Arma: ninguna"
	var armor_text: String = "Armadura: ninguna"

	if not selected_weapon_id.is_empty():
		weapon_text = "Arma: %s" % ItemDatabase.get_item_name(selected_weapon_id)

	if not selected_armor_id.is_empty():
		armor_text = "Armadura: %s" % ItemDatabase.get_item_name(selected_armor_id)

	return "Equipo para la próxima run:\n%s\n%s" % [
		weapon_text,
		armor_text
	]

func inventory_contains_item_id(item_id: String) -> bool:
	if item_id.is_empty():
		return false

	for item_data: Dictionary in SaveManager.persistent_inventory:
		var current_id: String = str(item_data.get("id", ""))

		if current_id == item_id:
			return true

	return false


func get_equipped_weapon_menu_text(selected_weapon_id: String) -> String:
	if selected_weapon_id.is_empty():
		return "Equipo para la próxima run:\nArma: ninguna"

	var weapon_name: String = ItemDatabase.get_item_name(selected_weapon_id)

	return "Equipo para la próxima run:\nArma: %s" % weapon_name


func _on_difficulty_selected(difficulty: int) -> void:
	selected_starting_difficulty = clamp(
		difficulty,
		1,
		max_starting_difficulty
	)

	show_start_screen()
