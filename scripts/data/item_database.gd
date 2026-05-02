extends RefCounted

# Base de datos provisional de items.
# Más adelante esto podrá pasar a Resources o JSON.

const ITEMS: Dictionary = {
	# -------------------------
	# ARMAS
	# -------------------------

	"rusty_sword": {
		"id": "rusty_sword",
		"name": "Espada oxidada",
		"type": "weapon",
		"attack_damage_bonus": 4.0,
		"loot_tier": 1
	},

	"hunter_dagger": {
		"id": "hunter_dagger",
		"name": "Daga de cazador",
		"type": "weapon",
		"attack_damage_bonus": 6.0,
		"loot_tier": 1
	},

	"iron_sword": {
		"id": "iron_sword",
		"name": "Espada de hierro",
		"type": "weapon",
		"attack_damage_bonus": 10.0,
		"loot_tier": 2
	},

	"war_axe": {
		"id": "war_axe",
		"name": "Hacha de guerra",
		"type": "weapon",
		"attack_damage_bonus": 14.0,
		"loot_tier": 3
	},

	# -------------------------
	# ARMADURAS
	# -------------------------

	"worn_tunic": {
		"id": "worn_tunic",
		"name": "Túnica gastada",
		"type": "armor",
		"damage_taken_multiplier": 0.95,
		"loot_tier": 1
	},

	"leather_armor": {
		"id": "leather_armor",
		"name": "Cota de cuero",
		"type": "armor",
		"damage_taken_multiplier": 0.85,
		"loot_tier": 2
	},

	"chainmail": {
		"id": "chainmail",
		"name": "Cota de malla",
		"type": "armor",
		"damage_taken_multiplier": 0.72,
		"loot_tier": 3
	}
}


static func get_item(item_id: String) -> Dictionary:
	if not ITEMS.has(item_id):
		return {}

	return ITEMS[item_id].duplicate()


static func get_item_name(item_id: String) -> String:
	var item_data: Dictionary = get_item(item_id)

	if item_data.is_empty():
		return "Objeto desconocido"

	return str(item_data.get("name", "Objeto desconocido"))


static func get_item_type(item_id: String) -> String:
	var item_data: Dictionary = get_item(item_id)

	if item_data.is_empty():
		return ""

	return str(item_data.get("type", ""))


static func get_item_loot_tier(item_id: String) -> int:
	var item_data: Dictionary = get_item(item_id)

	if item_data.is_empty():
		return 1

	return int(item_data.get("loot_tier", 1))


static func is_weapon(item_id: String) -> bool:
	return get_item_type(item_id) == "weapon"


static func is_armor(item_id: String) -> bool:
	return get_item_type(item_id) == "armor"


static func get_loot_tiers_for_difficulty(difficulty: int) -> Array[int]:
	# Define qué tiers pueden aparecer según dificultad.
	#
	# Dificultad 1: items básicos.
	# Dificultad 2: items básicos y medios.
	# Dificultad 3+: items medios y buenos.

	if difficulty <= 1:
		return [1]

	if difficulty == 2:
		return [1, 2]

	return [2, 3]


static func get_loot_item_ids_for_difficulty(difficulty: int) -> Array[String]:
	var allowed_tiers: Array[int] = get_loot_tiers_for_difficulty(difficulty)
	var item_ids: Array[String] = []

	for raw_item_id: Variant in ITEMS.keys():
		var item_id: String = str(raw_item_id)
		var item_tier: int = get_item_loot_tier(item_id)

		if allowed_tiers.has(item_tier):
			item_ids.append(item_id)

	return item_ids


static func get_random_loot_item_for_difficulty(difficulty: int) -> Dictionary:
	# Devuelve un item aleatorio filtrado por dificultad.

	var item_ids: Array[String] = get_loot_item_ids_for_difficulty(difficulty)

	if item_ids.is_empty():
		return {}

	var random_index: int = randi_range(0, item_ids.size() - 1)
	var selected_item_id: String = item_ids[random_index]

	return get_item(selected_item_id)
