extends Node

# UpgradeManager gestiona las mejoras disponibles y las mejoras elegidas.
# No aplica efectos directamente.
# Solo elige mejoras y guarda el historial de la run.

const UpgradeDatabase = preload("res://scripts/data/upgrade_database.gd")

# Lista completa de mejoras disponibles.
var upgrade_pool: Array = []

# Nombres de mejoras elegidas durante la run.
# Se usa para la pantalla final.
var chosen_upgrades: Array[String] = []

func _ready() -> void:
	# Cargamos todas las mejoras desde la base de datos.
	upgrade_pool = UpgradeDatabase.get_all_upgrades()

func get_random_upgrades(amount: int) -> Array:
	# Devuelve una lista de mejoras aleatorias sin repetir dentro de la misma tirada.
	# Ejemplo: si amount = 3, devuelve 3 mejoras distintas.
	var pool: Array = upgrade_pool.duplicate(true)
	var result: Array = []
	
	while result.size() < amount and pool.size() > 0:
		var index: int = randi_range(0, pool.size() - 1)
		
		result.append(pool[index])
		pool.remove_at(index)
	
	return result

func register_upgrade(upgrade: Dictionary) -> void:
	# Guarda el nombre de una mejora elegida.
	# No aplica la mejora; eso lo hace Player.apply_upgrade().
	if not upgrade.has("name"):
		return
	
	chosen_upgrades.append(upgrade["name"])

func get_chosen_upgrades_text() -> String:
	# Devuelve las mejoras elegidas como texto para pantalla final.
	if chosen_upgrades.is_empty():
		return "Ninguna"
	
	var text := ""
	
	for upgrade_name in chosen_upgrades:
		text += "- %s\n" % upgrade_name
	
	return text

func reset() -> void:
	# Limpia el historial de mejoras.
	# De momento casi no se usa porque recargamos escena para nueva run.
	chosen_upgrades.clear()
