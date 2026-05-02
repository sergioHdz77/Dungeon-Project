extends Node2D

const ItemDatabase = preload("res://scripts/data/item_database.gd")

# Referencias principales de la escena.
@onready var dungeon_manager: Node = get_node_or_null("DungeonManager")
@onready var dungeon_run_manager: Node = get_node_or_null("DungeonRunManager")
@onready var player: Node = get_node_or_null("Player")
@onready var hud: Node = get_node_or_null("HUD")
@onready var start_screen: Node = get_node_or_null("StartScreen")
@onready var run_end_screen: Node = get_node_or_null("RunEndScreen")

# Estado de la run actual.
var run_active: bool = false

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
			var equipped_weapon_text: String = get_auto_equipped_weapon_text()

			start_screen.show_screen(
				SaveManager.persistent_gold,
				inventory_text,
				equipped_weapon_text
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


# -------------------------------------------------------------------
# INICIO DE RUN
# -------------------------------------------------------------------

func start_dungeon_run() -> void:
	get_tree().paused = false
	run_active = true

	# El loot temporal siempre empieza vacío.
	run_loot.clear()

	# Equipamiento automático provisional.
	# Más adelante lo sustituiremos por una pantalla de equipamiento.
	equip_first_weapon_from_inventory()

	# Creamos la mazmorra actual.
	if dungeon_manager != null:
		if dungeon_manager.has_method("create_test_dungeon"):
			dungeon_manager.create_test_dungeon()

	# DungeonRunManager queda como punto futuro para dificultad, estado de run, etc.
	if dungeon_run_manager != null:
		if dungeon_run_manager.has_method("start_run"):
			dungeon_run_manager.start_run()

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

	finish_run(true)


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


func equip_first_weapon_from_inventory() -> void:
	if player == null:
		return

	if not player.has_method("equip_weapon"):
		return

	for item_data: Dictionary in SaveManager.persistent_inventory:
		var item_id: String = str(item_data.get("id", ""))

		if item_id.is_empty():
			continue

		if ItemDatabase.is_weapon(item_id):
			player.equip_weapon(item_id)
			return

	print("No hay armas en el inventario persistente para equipar.")


func lose_equipped_items_on_death() -> String:
	if player == null:
		return "No había equipo equipado."

	if not player.has_method("get_equipped_weapon_id"):
		return "No había equipo equipado."

	var weapon_id: String = player.get_equipped_weapon_id()

	if weapon_id.is_empty():
		return "No había arma equipada."

	var weapon_name: String = "Arma desconocida"

	if player.has_method("get_equipped_weapon_name"):
		weapon_name = player.get_equipped_weapon_name()

	var removed: bool = SaveManager.remove_inventory_item_once(weapon_id)

	if removed:
		return "Equipo perdido:\n- %s" % weapon_name

	return "El arma equipada no estaba en el inventario persistente."


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
			0
		)


func get_run_gold() -> int:
	if player == null:
		return 0

	if player.has_method("get_run_coins"):
		return player.get_run_coins()

	return 0
