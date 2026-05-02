extends Node

# SaveManager es Autoload.
# Guarda el progreso persistente entre runs.

const SAVE_PATH := "user://save_game.json"


# -------------------------------------------------------------------
# LEGACY / SISTEMA ANTIGUO
# -------------------------------------------------------------------

# Sistema antiguo del prototipo survivor-like.
# Se mantiene temporalmente para no romper scripts antiguos,
# pero el nuevo juego NO debería usarlo.
var meta_savings: int = 0


func add_savings(amount: int) -> void:
	# Sistema antiguo.
	# No usar para el nuevo roguelite dungeon crawler.
	if amount <= 0:
		return
	
	meta_savings += amount
	save_game()


# -------------------------------------------------------------------
# NUEVO SISTEMA PERSISTENTE
# -------------------------------------------------------------------

# Oro persistente del jugador.
# Se consigue al completar mazmorras.
# Se gastará en mejoras permanentes desde el menú principal.
var persistent_gold: int = 0

# Arma seleccionada para entrar en la próxima run.
# Guardamos solo el id. El item real sigue estando en persistent_inventory.
var equipped_weapon_id: String = ""

# Armadura seleccionada para entrar en la próxima run.
var equipped_armor_id: String = ""

# Inventario persistente del jugador.
# Aquí se guardan los objetos que el jugador conserva al ganar una mazmorra.
#
# Formato de cada item:
# {
#   "id": "iron_sword",
#   "name": "Espada de hierro"
# }
var persistent_inventory: Array[Dictionary] = []


func _ready() -> void:
	load_game()


# -------------------------------------------------------------------
# ORO PERSISTENTE
# -------------------------------------------------------------------

func add_gold(amount: int) -> void:
	# Añade oro persistente y guarda.
	# Este oro solo debería añadirse cuando el jugador gana la mazmorra.

	if amount <= 0:
		return

	persistent_gold += amount
	save_game()

	print("Oro persistente añadido: ", amount, " | total: ", persistent_gold)


func spend_gold(amount: int) -> bool:
	# Intenta gastar oro persistente.
	# Devuelve true si se ha podido pagar.

	if amount <= 0:
		return false

	if persistent_gold < amount:
		return false

	persistent_gold -= amount
	save_game()

	print("Oro gastado: ", amount, " | restante: ", persistent_gold)

	return true


# -------------------------------------------------------------------
# INVENTARIO PERSISTENTE
# -------------------------------------------------------------------

func add_inventory_item(item_id: String, display_name: String) -> void:
	# Añade un item al inventario persistente y guarda.
	# Permitimos duplicados porque puede haber varias armas iguales.

	if item_id.is_empty():
		return

	var item_data: Dictionary = {
		"id": item_id,
		"name": display_name
	}

	persistent_inventory.append(item_data)
	save_game()

	print("Item añadido al inventario persistente: ", display_name, " | id: ", item_id)


func add_inventory_items(items: Array[Dictionary]) -> void:
	# Añade varios items al inventario persistente.
	# Esto se usa al ganar una run.

	if items.is_empty():
		return

	for item_data: Dictionary in items:
		var item_id: String = str(item_data.get("id", ""))
		var display_name: String = str(item_data.get("name", "Objeto desconocido"))

		if item_id.is_empty():
			continue

		var saved_item: Dictionary = {
			"id": item_id,
			"name": display_name
		}

		persistent_inventory.append(saved_item)

	save_game()

	print("Inventario persistente actualizado. Total items: ", persistent_inventory.size())

func set_equipped_weapon(item_id: String) -> void:
	# Guarda qué arma quiere usar el jugador en la próxima run.
	# Si item_id está vacío, entra sin arma.

	equipped_weapon_id = item_id
	save_game()

	print("Arma seleccionada guardada: ", equipped_weapon_id)


func clear_equipped_weapon() -> void:
	equipped_weapon_id = ""
	save_game()
	
func set_equipped_armor(item_id: String) -> void:
	# Guarda qué armadura quiere usar el jugador en la próxima run.
	# Si item_id está vacío, entra sin armadura.

	equipped_armor_id = item_id
	save_game()

	print("Armadura seleccionada guardada: ", equipped_armor_id)


func clear_equipped_armor() -> void:
	equipped_armor_id = ""
	save_game()

func remove_inventory_item_once(item_id: String) -> bool:
	# Elimina una sola copia de un item del inventario persistente.
	# Importante porque puede haber duplicados.

	if item_id.is_empty():
		return false

	for i in range(persistent_inventory.size()):
		var item_data: Dictionary = persistent_inventory[i]
		var current_id: String = str(item_data.get("id", ""))

		if current_id == item_id:
			var removed_name: String = str(item_data.get("name", "Objeto desconocido"))

			persistent_inventory.remove_at(i)
			save_game()

			print("Item eliminado del inventario persistente: ", removed_name, " | id: ", item_id)
			return true

	return false


func get_inventory_text() -> String:
	# Devuelve texto legible del inventario persistente agrupando duplicados.
	# Internamente seguimos guardando cada item por separado,
	# pero en el menú mostramos "Objeto xN".

	if persistent_inventory.is_empty():
		return "Inventario vacío."

	var item_counts: Dictionary = {}

	for item_data: Dictionary in persistent_inventory:
		var item_id: String = str(item_data.get("id", ""))
		var display_name: String = str(item_data.get("name", "Objeto desconocido"))

		if item_id.is_empty():
			continue

		if not item_counts.has(item_id):
			item_counts[item_id] = {
				"name": display_name,
				"count": 0
			}

		item_counts[item_id]["count"] += 1

	var text: String = ""

	for item_id: String in item_counts.keys():
		var grouped_data: Dictionary = item_counts[item_id]
		var display_name: String = str(grouped_data.get("name", "Objeto desconocido"))
		var count: int = int(grouped_data.get("count", 1))

		text += "- %s x%s\n" % [
			display_name,
			count
		]

	if text.is_empty():
		return "Inventario vacío."

	return text


# -------------------------------------------------------------------
# GUARDADO / CARGA
# -------------------------------------------------------------------

func save_game() -> void:
	var data: Dictionary = {
		# Legacy
		"meta_savings": meta_savings,

		# Nuevo sistema
		"persistent_gold": persistent_gold,
		"persistent_inventory": persistent_inventory,
		"equipped_weapon_id": equipped_weapon_id,
		"equipped_armor_id": equipped_armor_id

	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("No se pudo abrir el archivo de guardado para escribir.")
		return
	
	file.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_reset_runtime_values()
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	if file == null:
		push_error("No se pudo abrir el archivo de guardado para leer.")
		_reset_runtime_values()
		return
	
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	
	if typeof(parsed) != TYPE_DICTIONARY:
		_reset_runtime_values()
		return

	var data: Dictionary = parsed

	# Legacy.
	if data.has("meta_savings"):
		meta_savings = int(data["meta_savings"])
	else:
		meta_savings = 0

	# Nuevo oro persistente.
	if data.has("persistent_gold"):
		persistent_gold = int(data["persistent_gold"])
	else:
		persistent_gold = 0

	# Arma equipada seleccionada.
	if data.has("equipped_weapon_id"):
		equipped_weapon_id = str(data["equipped_weapon_id"])
	else:
		equipped_weapon_id = ""
	
	# Armadura equipada seleccionada.
	if data.has("equipped_armor_id"):
		equipped_armor_id = str(data["equipped_armor_id"])
	else:
		equipped_armor_id = ""

	# Nuevo inventario persistente.
	persistent_inventory.clear()

	if data.has("persistent_inventory") and typeof(data["persistent_inventory"]) == TYPE_ARRAY:
		var loaded_inventory: Array = data["persistent_inventory"]

		for entry: Variant in loaded_inventory:
			if typeof(entry) != TYPE_DICTIONARY:
				continue

			var item_data: Dictionary = entry
			var item_id: String = str(item_data.get("id", ""))
			var display_name: String = str(item_data.get("name", "Objeto desconocido"))

			if item_id.is_empty():
				continue

			var loaded_item: Dictionary = {
				"id": item_id,
				"name": display_name
			}

			persistent_inventory.append(loaded_item)


func reset_save() -> void:
	# Resetea todo el progreso persistente.
	# De momento también resetea meta_savings legacy.

	_reset_runtime_values()
	save_game()


func _reset_runtime_values() -> void:
	# Valores por defecto cuando no hay guardado o está corrupto.

	meta_savings = 0
	persistent_gold = 0
	equipped_weapon_id = ""
	equipped_armor_id = ""
	persistent_inventory.clear()
