extends Node

# Estado de una cadena de mazmorras.
# Este nodo permite sacar de Main.gd todo lo que no es UI:
# - dificultad actual
# - loot temporal
# - recompensas al volver a casa
# - pérdida de equipo al morir

const ItemDatabase = preload("res://scripts/data/item_database.gd")

signal session_changed

@export var max_starting_difficulty: int = 3

var active: bool = false
var selected_starting_difficulty: int = 1
var current_difficulty: int = 1
var run_loot: Array[Dictionary] = []


func start_new_chain(starting_difficulty: int) -> void:
	selected_starting_difficulty = clamp(starting_difficulty, 1, max_starting_difficulty)
	current_difficulty = selected_starting_difficulty
	run_loot.clear()
	active = true
	session_changed.emit()


func complete_chain_successfully(run_gold: int) -> void:
	if not run_loot.is_empty():
		SaveManager.add_inventory_items(run_loot)

	if run_gold > 0:
		SaveManager.add_gold(run_gold)

	active = false
	session_changed.emit()


func fail_chain(player: Node) -> String:
	var lost_equipment_text: String = lose_equipped_items_on_death(player)
	active = false
	session_changed.emit()
	return lost_equipment_text


func open_portal() -> void:
	current_difficulty += 1
	session_changed.emit()


func collect_item(item_id: String, display_name: String) -> void:
	if item_id.is_empty():
		return

	run_loot.append({
		"id": item_id,
		"name": display_name,
	})
	session_changed.emit()


func get_run_loot_text() -> String:
	if run_loot.is_empty():
		return "- Ninguno"

	var text: String = ""
	for item_data: Dictionary in run_loot:
		var item_name: String = str(item_data.get("name", "Objeto desconocido"))
		text += "- %s\n" % item_name

	return text.strip_edges()


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
	result_text += get_run_loot_text()
	return result_text


func lose_equipped_items_on_death(player: Node) -> String:
	if player == null:
		return "No había equipo equipado."

	var lost_lines: Array[String] = []
	_try_remove_equipped_weapon(player, lost_lines)
	_try_remove_equipped_armor(player, lost_lines)

	if lost_lines.is_empty():
		return "No había equipo equipado."

	var text: String = "Equipo perdido:\n"
	for line: String in lost_lines:
		text += "%s\n" % line

	return text.strip_edges()


func _try_remove_equipped_weapon(player: Node, lost_lines: Array[String]) -> void:
	if not player.has_method("get_equipped_weapon_id"):
		return

	var weapon_id: String = player.get_equipped_weapon_id()
	if weapon_id.is_empty():
		return

	var weapon_name: String = "Arma desconocida"
	if player.has_method("get_equipped_weapon_name"):
		weapon_name = player.get_equipped_weapon_name()

	if SaveManager.remove_inventory_item_once(weapon_id):
		SaveManager.clear_equipped_weapon()
		lost_lines.append("- %s" % weapon_name)


func _try_remove_equipped_armor(player: Node, lost_lines: Array[String]) -> void:
	if not player.has_method("get_equipped_armor_id"):
		return

	var armor_id: String = player.get_equipped_armor_id()
	if armor_id.is_empty():
		return

	var armor_name: String = "Armadura desconocida"
	if player.has_method("get_equipped_armor_name"):
		armor_name = player.get_equipped_armor_name()

	if SaveManager.remove_inventory_item_once(armor_id):
		SaveManager.clear_equipped_armor()
		lost_lines.append("- %s" % armor_name)


func set_selected_starting_difficulty(difficulty: int) -> void:
	selected_starting_difficulty = clamp(difficulty, 1, max_starting_difficulty)
	session_changed.emit()
