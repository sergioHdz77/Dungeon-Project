extends Node

const ItemDatabase = preload("res://scripts/data/item_database.gd")

# Componente responsable SOLO de soltar loot al limpiar una sala.
# No controla enemigos, puertas ni estado cleared.

signal item_collected(item_id: String, display_name: String)

@export var drops_loot_on_clear: bool = false
@export var loot_item_scene: PackedScene

var room: Node2D = null


func setup(owner_room: Node2D) -> void:
	room = owner_room


func drop_clear_loot(difficulty: int) -> void:
	if not drops_loot_on_clear:
		return

	if loot_item_scene == null:
		return

	if room == null:
		return

	var item_data: Dictionary = ItemDatabase.get_random_loot_item_for_difficulty(difficulty)

	if item_data.is_empty():
		push_warning("%s: ItemDatabase no devolvió loot válido." % room.name)
		return

	var item_id: String = str(item_data.get("id", ""))
	var display_name: String = str(item_data.get("name", "Objeto desconocido"))

	if item_id.is_empty():
		push_warning("%s: loot generado sin id." % room.name)
		return

	var loot_item := loot_item_scene.instantiate() as Node2D

	if loot_item == null:
		return

	room.add_child(loot_item)
	loot_item.global_position = room.global_position

	if loot_item.has_method("setup_item"):
		loot_item.setup_item(item_id, display_name)

	if loot_item.has_signal("collected"):
		loot_item.collected.connect(_on_loot_item_collected)

	print("Loot generado en ", room.name, " dificultad ", difficulty, ": ", display_name)


func _on_loot_item_collected(item_id: String, display_name: String) -> void:
	item_collected.emit(item_id, display_name)
