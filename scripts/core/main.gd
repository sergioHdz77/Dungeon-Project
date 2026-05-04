extends Node2D

const ItemDatabase = preload("res://scripts/data/item_database.gd")

# Referencias principales de la escena.
@onready var dungeon_manager: Node = get_node_or_null("DungeonManager")
@onready var player: Node = get_node_or_null("Player")
@onready var hud: Node = get_node_or_null("HUD")
@onready var start_screen: Node = get_node_or_null("StartScreen")
@onready var run_end_screen: Node = get_node_or_null("RunEndScreen")
@onready var dungeon_complete_screen: Node = get_node_or_null("DungeonCompleteScreen")

@onready var run_session: Node = get_node_or_null("RunSession")
@onready var equipment_menu_service: Node = get_node_or_null("EquipmentMenuService")

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

			if equipment_menu_service == null:
				push_error("Main.show_start_screen(): falta el nodo EquipmentMenuService.")
				return

			var selected_weapon_id: String = equipment_menu_service.get_valid_selected_weapon_id()
			var selected_armor_id: String = equipment_menu_service.get_valid_selected_armor_id()

			var equipment_text: String = equipment_menu_service.get_equipment_menu_text(
				selected_weapon_id,
				selected_armor_id
			)

			var weapon_options: Array[Dictionary] = equipment_menu_service.get_weapon_options_from_inventory()
			var armor_options: Array[Dictionary] = equipment_menu_service.get_armor_options_from_inventory()

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

	if run_session != null:
		run_session.start_new_chain(selected_starting_difficulty)
		run_active = run_session.active
		current_difficulty = run_session.current_difficulty
		run_loot = run_session.run_loot
	else:
		run_active = true
		current_difficulty = selected_starting_difficulty
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

	if run_session != null:
		run_session.open_portal()
		current_difficulty = run_session.current_difficulty
	else:
		current_difficulty += 1

	print("Abriendo portal a dificultad: ", current_difficulty)

	start_dungeon_at_current_difficulty()
	update_hud()


func finish_run(victory: bool) -> void:
	var run_gold: int = get_run_gold()
	var lost_equipment_text: String = ""

	if run_session == null:
		push_error("Main.finish_run(): falta el nodo RunSession.")
		return

	if victory:
		run_session.complete_chain_successfully(run_gold)
	else:
		lost_equipment_text = run_session.fail_chain(player)

	run_active = run_session.active
	current_difficulty = run_session.current_difficulty
	run_loot = run_session.run_loot

	update_hud()

	var result_text: String = build_run_result_text(
		victory,
		run_gold,
		lost_equipment_text
	)

	show_run_end_screen(victory, result_text)
	get_tree().paused = true

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
	if run_session != null:
		return run_session.build_victory_result_text(run_gold)

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
	if run_session != null:
		return run_session.build_defeat_result_text(run_gold, lost_equipment_text)

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
	if run_session != null:
		return run_session.get_run_loot_text()

	var text: String = ""

	for item_data: Dictionary in run_loot:
		var item_name: String = str(item_data.get("name", "Objeto desconocido"))
		text += "- %s\n" % item_name

	return text


# -------------------------------------------------------------------
# LOOT DE RUN
# -------------------------------------------------------------------

func _on_item_collected(item_id: String, display_name: String) -> void:
	if run_session != null:
		run_session.collect_item(item_id, display_name)
		run_loot = run_session.run_loot
	else:
		var item_data: Dictionary = {
			"id": item_id,
			"name": display_name,
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

	if equipment_menu_service == null:
		push_error("Main.equip_selected_weapon_from_inventory(): falta el nodo EquipmentMenuService.")
		return

	var selected_weapon_id: String = equipment_menu_service.get_valid_selected_weapon_id()

	if selected_weapon_id.is_empty():
		print("El jugador entra sin arma equipada.")
		return

	player.equip_weapon(selected_weapon_id)


func equip_selected_armor_from_inventory() -> void:
	if player == null:
		return

	if not player.has_method("equip_armor"):
		return

	if equipment_menu_service == null:
		push_error("Main.equip_selected_armor_from_inventory(): falta el nodo EquipmentMenuService.")
		return

	var selected_armor_id: String = equipment_menu_service.get_valid_selected_armor_id()

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

func _on_difficulty_selected(difficulty: int) -> void:
	selected_starting_difficulty = clamp(
		difficulty,
		1,
		max_starting_difficulty
	)

	if run_session != null:
		run_session.set_selected_starting_difficulty(selected_starting_difficulty)

	show_start_screen()
