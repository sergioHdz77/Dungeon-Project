extends Node2D

# Este componente solo se encarga de mostrar visualmente el equipo.
# No aplica daño, defensa ni lógica de inventario.

@onready var weapon_visual: Sprite2D = get_node_or_null("WeaponVisual")
@onready var armor_visual: Sprite2D = get_node_or_null("ArmorVisual")

@onready var weapon_animation_player: AnimationPlayer = get_node_or_null("WeaponAnimationPlayer")

# Listas configurables desde el inspector.
# Cada entrada relaciona:
# item_id -> textura
@export var weapon_visual_entries: Array[EquipmentVisualEntry] = []
@export var armor_visual_entries: Array[EquipmentVisualEntry] = []


func show_weapon(weapon_id: String, weapon_data: Dictionary) -> void:
	if weapon_visual == null:
		return

	var texture: Texture2D = get_texture_for_id(weapon_id, weapon_visual_entries)

	if texture == null:
		weapon_visual.visible = false
		weapon_visual.texture = null
		print("EquipmentVisuals: no hay textura para arma: ", weapon_id)
		return

	weapon_visual.texture = texture
	weapon_visual.visible = true

	print("EquipmentVisuals: mostrando arma: ", weapon_id)


func show_armor(armor_id: String, armor_data: Dictionary) -> void:
	if armor_visual == null:
		return

	var texture: Texture2D = get_texture_for_id(armor_id, armor_visual_entries)

	if texture == null:
		armor_visual.visible = false
		armor_visual.texture = null
		print("EquipmentVisuals: no hay textura para armadura: ", armor_id)
		return

	armor_visual.texture = texture
	armor_visual.visible = true

	print("EquipmentVisuals: mostrando armadura: ", armor_id)


func clear_weapon() -> void:
	if weapon_visual == null:
		return

	weapon_visual.texture = null
	weapon_visual.visible = false

	print("EquipmentVisuals: arma visual quitada")


func clear_armor() -> void:
	if armor_visual == null:
		return

	armor_visual.texture = null
	armor_visual.visible = false

	print("EquipmentVisuals: armadura visual quitada")


func get_texture_for_id(
	item_id: String,
	visual_entries: Array[EquipmentVisualEntry]
) -> Texture2D:
	if item_id.is_empty():
		return null

	for entry: EquipmentVisualEntry in visual_entries:
		if entry == null:
			continue

		if entry.item_id == item_id:
			return entry.texture

	return null
	
func play_weapon_attack(direction: Vector2) -> void:
	if weapon_visual == null:
		return

	if not weapon_visual.visible:
		return

	if weapon_animation_player == null:
		return

	var animation_name: String = get_weapon_attack_animation_name(direction)

	if not weapon_animation_player.has_animation(animation_name):
		print("EquipmentVisuals: no existe animación de arma: ", animation_name)
		return

	weapon_animation_player.stop()
	weapon_animation_player.play(animation_name)


func get_weapon_attack_animation_name(direction: Vector2) -> String:
	if direction.length() <= 0.01:
		return "weapon_attack_side"

	var normalized_direction: Vector2 = direction.normalized()

	if absf(normalized_direction.x) >= absf(normalized_direction.y):
		return "weapon_attack_side"

	if normalized_direction.y < 0.0:
		return "weapon_attack_back"

	return "weapon_attack_front"
