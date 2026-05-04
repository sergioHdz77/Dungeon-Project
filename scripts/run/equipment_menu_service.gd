extends Node

# Servicio pequeño para quitar de Main.gd la construcción de opciones del menú.
# Lee SaveManager + ItemDatabase y devuelve datos listos para StartScreen.

const ItemDatabase = preload("res://scripts/data/item_database.gd")


func get_weapon_options_from_inventory() -> Array[Dictionary]:
	return _get_equipment_options("weapon")


func get_armor_options_from_inventory() -> Array[Dictionary]:
	return _get_equipment_options("armor")


func get_valid_selected_weapon_id() -> String:
	return _get_valid_selected_item_id(SaveManager.equipped_weapon_id, "weapon")


func get_valid_selected_armor_id() -> String:
	return _get_valid_selected_item_id(SaveManager.equipped_armor_id, "armor")


func get_equipment_menu_text(selected_weapon_id: String, selected_armor_id: String) -> String:
	var weapon_text: String = "Arma: ninguna"
	var armor_text: String = "Armadura: ninguna"

	if not selected_weapon_id.is_empty():
		weapon_text = "Arma: %s" % ItemDatabase.get_item_name(selected_weapon_id)

	if not selected_armor_id.is_empty():
		armor_text = "Armadura: %s" % ItemDatabase.get_item_name(selected_armor_id)

	return "Equipo para la próxima run:\n%s\n%s" % [weapon_text, armor_text]


func _get_equipment_options(item_type: String) -> Array[Dictionary]:
	var item_counts: Dictionary = {}

	for item_data: Dictionary in SaveManager.persistent_inventory:
		var item_id: String = str(item_data.get("id", ""))
		if item_id.is_empty():
			continue
		if not _matches_type(item_id, item_type):
			continue

		if not item_counts.has(item_id):
			item_counts[item_id] = 0
		item_counts[item_id] += 1

	var options: Array[Dictionary] = []
	for item_id: String in item_counts.keys():
		var count: int = int(item_counts[item_id])
		var item_name: String = ItemDatabase.get_item_name(item_id)
		options.append({
			"id": item_id,
			"name": "%s x%s" % [item_name, count],
		})

	return options


func _get_valid_selected_item_id(item_id: String, item_type: String) -> String:
	if item_id.is_empty():
		return ""

	if _inventory_contains_item_id(item_id) and _matches_type(item_id, item_type):
		return item_id

	if item_type == "weapon":
		SaveManager.clear_equipped_weapon()
	elif item_type == "armor":
		SaveManager.clear_equipped_armor()

	return ""


func _inventory_contains_item_id(item_id: String) -> bool:
	if item_id.is_empty():
		return false

	for item_data: Dictionary in SaveManager.persistent_inventory:
		if str(item_data.get("id", "")) == item_id:
			return true

	return false


func _matches_type(item_id: String, item_type: String) -> bool:
	if item_type == "weapon":
		return ItemDatabase.is_weapon(item_id)
	if item_type == "armor":
		return ItemDatabase.is_armor(item_id)
	return false
