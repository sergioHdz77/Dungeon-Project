extends Node

# Componente responsable SOLO del equipo del jugador.
# Ventaja principal frente al código anterior:
# - evita que el bonus de daño del arma se acumule al reequipar
# - separa arma/armadura de Player.gd
# - deja preparada la integración visual del equipo


# Señales de equipamiento.
# Este componente no actualiza sprites directamente.
# Solo avisa de que el equipo ha cambiado.

signal weapon_equipped(weapon_id: String, weapon_data: Dictionary)
signal armor_equipped(armor_id: String, armor_data: Dictionary)
signal weapon_unequipped()
signal armor_unequipped()

const ItemDatabase = preload("res://scripts/data/item_database.gd")

signal equipment_changed

var combat: Node = null

var equipped_weapon_id: String = ""
var equipped_weapon_name: String = "Sin arma"
var equipped_weapon_damage_bonus: float = 0.0

var equipped_armor_id: String = ""
var equipped_armor_name: String = "Sin armadura"
var armor_damage_taken_multiplier: float = 1.0


func setup(combat_component: Node) -> void:
	combat = combat_component


func equip_weapon(item_id: String) -> void:
	if item_id.is_empty():
		clear_weapon()
		return

	var item_data: Dictionary = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		push_warning("No existe item en ItemDatabase: %s" % item_id)
		return

	if str(item_data.get("type", "")) != "weapon":
		push_warning("El item no es un arma: %s" % item_id)
		return

	_remove_previous_weapon_bonus()

	equipped_weapon_id = item_id
	equipped_weapon_name = str(item_data.get("name", "Arma desconocida"))
	equipped_weapon_damage_bonus = float(item_data.get("attack_damage_bonus", 0.0))

	if combat != null and combat.has_method("add_damage"):
		combat.add_damage(equipped_weapon_damage_bonus)

	equipment_changed.emit()
	weapon_equipped.emit(item_id, item_data)

func clear_weapon() -> void:
	_remove_previous_weapon_bonus()
	equipped_weapon_id = ""
	equipped_weapon_name = "Sin arma"
	equipment_changed.emit()
	weapon_unequipped.emit()

func _remove_previous_weapon_bonus() -> void:
	if equipped_weapon_damage_bonus == 0.0:
		return

	if combat != null and combat.has_method("add_damage"):
		combat.add_damage(-equipped_weapon_damage_bonus)

	equipped_weapon_damage_bonus = 0.0


func equip_armor(item_id: String) -> void:
	if item_id.is_empty():
		clear_armor()
		return

	var item_data: Dictionary = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		push_warning("No existe item en ItemDatabase: %s" % item_id)
		return

	if str(item_data.get("type", "")) != "armor":
		push_warning("El item no es una armadura: %s" % item_id)
		return

	equipped_armor_id = item_id
	equipped_armor_name = str(item_data.get("name", "Armadura desconocida"))
	armor_damage_taken_multiplier = float(item_data.get("damage_taken_multiplier", 1.0))

	equipment_changed.emit()
	armor_equipped.emit(item_id, item_data)

func clear_armor() -> void:
	equipped_armor_id = ""
	equipped_armor_name = "Sin armadura"
	armor_damage_taken_multiplier = 1.0
	equipment_changed.emit()
	armor_unequipped.emit()

func modify_incoming_damage(amount: float) -> float:
	return amount * armor_damage_taken_multiplier


func get_equipped_weapon_id() -> String:
	return equipped_weapon_id


func get_equipped_weapon_name() -> String:
	return equipped_weapon_name


func get_equipped_armor_id() -> String:
	return equipped_armor_id


func get_equipped_armor_name() -> String:
	return equipped_armor_name
