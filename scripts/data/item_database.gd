extends RefCounted

# Base de datos provisional de items.
# De momento usamos un Dictionary simple.
# Más adelante esto podrá convertirse en Resources, JSON o una base más limpia.

const ITEMS: Dictionary = {
	"iron_sword": {
		"id": "iron_sword",
		"name": "Espada de hierro",
		"type": "weapon",
		"attack_damage_bonus": 10.0
	},
	"rusty_sword": {
		"id": "rusty_sword",
		"name": "Espada oxidada",
		"type": "weapon",
		"attack_damage_bonus": 4.0
	},
	"hunter_dagger": {
		"id": "hunter_dagger",
		"name": "Daga de cazador",
		"type": "weapon",
		"attack_damage_bonus": 6.0
	}
}


static func get_item(item_id: String) -> Dictionary:
	# Devuelve la definición del item.
	# Si no existe, devuelve un Dictionary vacío.

	if not ITEMS.has(item_id):
		return {}

	return ITEMS[item_id].duplicate()


static func is_weapon(item_id: String) -> bool:
	var item_data: Dictionary = get_item(item_id)

	if item_data.is_empty():
		return false

	return str(item_data.get("type", "")) == "weapon"


static func get_item_name(item_id: String) -> String:
	var item_data: Dictionary = get_item(item_id)

	if item_data.is_empty():
		return "Objeto desconocido"

	return str(item_data.get("name", "Objeto desconocido"))
