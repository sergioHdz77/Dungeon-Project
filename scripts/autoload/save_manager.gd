extends Node

# SaveManager es Autoload.
# Eso significa que existe globalmente como SaveManager
# y se mantiene accesible desde cualquier escena.

# Archivo donde se guarda el progreso.
# user:// apunta a una carpeta segura de datos del usuario.
const SAVE_PATH := "user://save_game.json"

# Ahorro meta antiguo.
# De momento lo mantenemos para no romper HUD/StartScreen.
# Más adelante lo eliminaremos del todo.
var meta_savings: int = 0

# Oro persistente del jugador.
# Se consigue al completar mazmorras.
# Se gastará en mejoras permanentes desde el menú principal.
var persistent_gold: int = 0

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
	# Al arrancar el juego, cargamos el guardado.
	load_game()


func add_savings(amount: int) -> void:
	# Sistema antiguo.
	# Lo mantenemos temporalmente para compatibilidad.
	if amount <= 0:
		return
	
	meta_savings += amount
	save_game()


func add_inventory_item(item_id: String, display_name: String) -> void:
	# Añade un item al inventario persistente y guarda.
	# Permitimos duplicados porque más adelante puede tener sentido:
	# dos espadas, dos armaduras, etc.

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
	# Esto se usará al ganar una run.

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

func remove_inventory_item_once(item_id: String) -> bool:
	# Elimina una sola copia de un item del inventario persistente.
	# Esto es importante porque podemos tener varias espadas iguales.

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
	# Devuelve texto legible del inventario persistente.
	# De momento sirve para debug.

	if persistent_inventory.is_empty():
		return "Inventario vacío."

	var text: String = ""

	for item_data: Dictionary in persistent_inventory:
		var display_name: String = str(item_data.get("name", "Objeto desconocido"))
		text += "- %s\n" % display_name

	return text


func save_game() -> void:
	# Datos que queremos persistir.
	var data: Dictionary = {
		"meta_savings": meta_savings,
		"persistent_inventory": persistent_inventory,
		"persistent_gold": persistent_gold
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("No se pudo abrir el archivo de guardado para escribir.")
		return
	
	file.store_string(JSON.stringify(data))


func load_game() -> void:
	# Si no existe guardado, empezamos desde cero.
	if not FileAccess.file_exists(SAVE_PATH):
		meta_savings = 0
		persistent_inventory.clear()
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	if file == null:
		push_error("No se pudo abrir el archivo de guardado para leer.")
		meta_savings = 0
		persistent_inventory.clear()
		return
	
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	
	if typeof(parsed) != TYPE_DICTIONARY:
		# Si el archivo está corrupto o no tiene el formato esperado,
		# reiniciamos el progreso para evitar errores.
		meta_savings = 0
		persistent_inventory.clear()
		return

	var data: Dictionary = parsed

	# Cargamos ahorro antiguo si existe.
	if data.has("meta_savings"):
		meta_savings = int(data["meta_savings"])
	else:
		meta_savings = 0
	
	# Cargamos oro persistente si existe.
	if data.has("persistent_gold"):
		persistent_gold = int(data["persistent_gold"])
	else:
		persistent_gold = 0

	# Cargamos inventario persistente si existe.
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


func reset_save() -> void:
	# Resetea todo el progreso persistente.

	meta_savings = 0
	persistent_gold = 0
	persistent_inventory.clear()
	save_game()
