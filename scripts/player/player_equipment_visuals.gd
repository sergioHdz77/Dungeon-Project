extends Node2D

# Este componente solo se encarga de mostrar visualmente el equipo.
# No aplica daño, defensa ni lógica de inventario.
#
# Estructura esperada:
#
# Player
# ├── EquipmentBackVisuals
# │   ├── WeaponBackSocket
# │   │   └── WeaponBackVisual
# │   └── WeaponBackAnimationPlayer
# ├── Visuals
# │   └── AnimatedSprite2D
# └── EquipmentVisuals
#     ├── WeaponSocket
#     │   └── WeaponVisual
#     ├── ArmorVisual
#     └── WeaponAnimationPlayer

@onready var weapon_socket: Node2D = get_node_or_null("WeaponSocket")
@onready var weapon_visual: Sprite2D = get_node_or_null("WeaponSocket/WeaponVisual")
@onready var armor_visual: Sprite2D = get_node_or_null("ArmorVisual")

@onready var weapon_back_socket: Node2D = get_node_or_null("../EquipmentBackVisuals/WeaponBackSocket")
@onready var weapon_back_visual: Sprite2D = get_node_or_null("../EquipmentBackVisuals/WeaponBackSocket/WeaponBackVisual")
@onready var weapon_back_animation_player: AnimationPlayer = get_node_or_null("../EquipmentBackVisuals/WeaponBackAnimationPlayer")

# Si ya tienes un WeaponAnimationPlayer, lo dejamos preparado.
@onready var weapon_animation_player: AnimationPlayer = get_node_or_null("WeaponAnimationPlayer")

@onready var equipment_back_visuals: Node2D = get_node_or_null("../EquipmentBackVisuals")

@export var weapon_visual_entries: Array[EquipmentVisualEntry] = []
@export var armor_visual_entries: Array[EquipmentVisualEntry] = []

@export_group("Weapon Socket Poses")
@export var weapon_socket_side_position: Vector2 = Vector2(7, 1)
@export var weapon_socket_front_position: Vector2 = Vector2(4, 6)
@export var weapon_socket_back_position: Vector2 = Vector2(-3, -5)

@export var weapon_socket_side_z_index: int = 2
@export var weapon_socket_front_z_index: int = 2

var current_weapon_entry: EquipmentVisualEntry = null
var current_armor_entry: EquipmentVisualEntry = null

func _ready() -> void:
	sync_back_visuals_transform()

func show_weapon(weapon_id: String, weapon_data: Dictionary) -> void:
	
	sync_back_visuals_transform()

	if weapon_socket == null:
		push_warning("EquipmentVisuals: falta WeaponSocket.")
		return

	if weapon_visual == null:
		push_warning("EquipmentVisuals: falta WeaponSocket/WeaponVisual.")
		return

	var entry: EquipmentVisualEntry = get_visual_entry_for_id(
		weapon_id,
		weapon_visual_entries
	)

	if entry == null:
		weapon_visual.visible = false
		weapon_visual.texture = null
		current_weapon_entry = null
		print("EquipmentVisuals: no hay entrada visual para arma: ", weapon_id)
		return

	if entry.texture == null:
		weapon_visual.visible = false
		weapon_visual.texture = null
		current_weapon_entry = null
		print("EquipmentVisuals: no hay textura para arma: ", weapon_id)
		return

	current_weapon_entry = entry

	weapon_visual.texture = entry.texture

	# Importante:
	# centered = false hace que el origen del sprite sea la esquina superior izquierda.
	# Luego offset = -grip_offset mueve la textura para que la empuñadura quede en el origen del WeaponSocket.
	weapon_visual.centered = false
	weapon_visual.offset = -entry.grip_offset
	weapon_visual.scale = entry.visual_scale
	weapon_visual.position = Vector2.ZERO
	weapon_visual.rotation_degrees = 0.0
	weapon_visual.visible = true

	if weapon_back_visual != null:
		weapon_back_visual.texture = entry.texture
		weapon_back_visual.centered = false
		weapon_back_visual.offset = -entry.grip_offset
		weapon_back_visual.scale = entry.visual_scale
		weapon_back_visual.position = Vector2.ZERO
		weapon_back_visual.rotation_degrees = 0.0
		weapon_back_visual.visible = false

	weapon_socket.rotation_degrees = entry.idle_rotation_degrees

	print("EquipmentVisuals: mostrando arma anclada a socket: ", weapon_id)


func show_armor(armor_id: String, armor_data: Dictionary) -> void:
	if armor_visual == null:
		return

	var entry: EquipmentVisualEntry = get_visual_entry_for_id(
		armor_id,
		armor_visual_entries
	)

	if entry == null:
		armor_visual.visible = false
		armor_visual.texture = null
		current_armor_entry = null
		print("EquipmentVisuals: no hay entrada visual para armadura: ", armor_id)
		return

	if entry.texture == null:
		armor_visual.visible = false
		armor_visual.texture = null
		current_armor_entry = null
		print("EquipmentVisuals: no hay textura para armadura: ", armor_id)
		return

	current_armor_entry = entry

	armor_visual.texture = entry.texture
	armor_visual.visible = true

	print("EquipmentVisuals: mostrando armadura: ", armor_id)


func clear_weapon() -> void:
	current_weapon_entry = null

	if weapon_visual != null:
		weapon_visual.texture = null
		weapon_visual.visible = false
		weapon_visual.offset = Vector2.ZERO
		weapon_visual.position = Vector2.ZERO
		weapon_visual.rotation_degrees = 0.0

	if weapon_socket != null:
		weapon_socket.position = Vector2.ZERO
		weapon_socket.rotation_degrees = 0.0
		weapon_socket.scale = Vector2.ONE

	if weapon_back_visual != null:
		weapon_back_visual.texture = null
		weapon_back_visual.visible = false
		weapon_back_visual.offset = Vector2.ZERO
		weapon_back_visual.position = Vector2.ZERO
		weapon_back_visual.rotation_degrees = 0.0

	if weapon_back_socket != null:
		weapon_back_socket.position = Vector2.ZERO
		weapon_back_socket.rotation_degrees = 0.0
		weapon_back_socket.scale = Vector2.ONE

	print("EquipmentVisuals: arma visual quitada")


func clear_armor() -> void:
	current_armor_entry = null

	if armor_visual == null:
		return

	armor_visual.texture = null
	armor_visual.visible = false

	print("EquipmentVisuals: armadura visual quitada")


func get_visual_entry_for_id(
	item_id: String,
	visual_entries: Array[EquipmentVisualEntry]
) -> EquipmentVisualEntry:
	if item_id.is_empty():
		return null

	for entry: EquipmentVisualEntry in visual_entries:
		if entry == null:
			continue

		if entry.item_id == item_id:
			return entry

	return null


func play_weapon_attack(direction: Vector2) -> void:
	if current_weapon_entry == null:
		return

	# Coloca la capa correcta antes de animar:
	# - arriba usa arma trasera
	# - frente/lateral usa arma delantera
	apply_weapon_socket_idle_pose(direction)

	var animation_name: String = get_weapon_attack_animation_name(direction)

	if is_back_direction(direction):
		play_back_weapon_attack(animation_name)
	else:
		play_front_weapon_attack(animation_name)

func play_front_weapon_attack(animation_name: String) -> void:
	if weapon_visual == null:
		return

	if not weapon_visual.visible:
		return

	if weapon_animation_player == null:
		return

	if not weapon_animation_player.has_animation(animation_name):
		print("EquipmentVisuals: no existe animación delantera de arma: ", animation_name)
		return

	weapon_animation_player.stop()
	weapon_animation_player.play(animation_name)


func play_back_weapon_attack(animation_name: String) -> void:
	if weapon_back_visual == null:
		return

	if not weapon_back_visual.visible:
		return

	if weapon_back_animation_player == null:
		print("EquipmentVisuals: falta WeaponBackAnimationPlayer.")
		return

	if not weapon_back_animation_player.has_animation(animation_name):
		print("EquipmentVisuals: no existe animación trasera de arma: ", animation_name)
		return

	weapon_back_animation_player.stop()
	weapon_back_animation_player.play(animation_name)


func is_back_direction(direction: Vector2) -> bool:
	if direction.length() <= 0.01:
		return false

	var normalized_direction: Vector2 = direction.normalized()

	return absf(normalized_direction.y) > absf(normalized_direction.x) and normalized_direction.y < 0.0

func update_weapon_idle_pose(direction: Vector2) -> void:
	if current_weapon_entry == null:
		return

	apply_weapon_socket_idle_pose(direction)

func apply_weapon_socket_idle_pose(direction: Vector2) -> void:
	if weapon_socket == null:
		return

	var normalized_direction: Vector2 = Vector2.RIGHT

	if direction.length() > 0.01:
		normalized_direction = direction.normalized()

	var idle_rotation: float = 0.0

	if current_weapon_entry != null:
		idle_rotation = current_weapon_entry.idle_rotation_degrees

	if absf(normalized_direction.x) >= absf(normalized_direction.y):
		# Lateral: usamos el arma delantera.
		weapon_socket.position = weapon_socket_side_position
		weapon_socket.rotation_degrees = idle_rotation
		weapon_socket.z_index = weapon_socket_side_z_index

		if normalized_direction.x < 0.0:
			weapon_socket.scale.x = -1.0
		else:
			weapon_socket.scale.x = 1.0

		weapon_socket.scale.y = 1.0

		if weapon_visual != null:
			weapon_visual.visible = true
			weapon_visual.z_index = 0

		if weapon_back_visual != null:
			weapon_back_visual.visible = false

		if weapon_back_socket != null:
			weapon_back_socket.position = weapon_socket_back_position
			weapon_back_socket.rotation_degrees = idle_rotation
			weapon_back_socket.scale = Vector2.ONE

	elif normalized_direction.y < 0.0:
		# Mirando arriba / espalda: usamos el arma trasera.
		# Esta capa está por debajo del cuerpo en el árbol, así que el personaje tapa el arma.
		if weapon_visual != null:
			weapon_visual.visible = false

		if weapon_back_socket != null:
			weapon_back_socket.position = weapon_socket_back_position
			weapon_back_socket.rotation_degrees = idle_rotation
			weapon_back_socket.scale = Vector2.ONE
			weapon_back_socket.z_index = 0

		if weapon_back_visual != null:
			weapon_back_visual.visible = true
			weapon_back_visual.z_index = 0

		# Dejamos el socket delantero preparado, pero oculto.
		weapon_socket.position = weapon_socket_front_position
		weapon_socket.rotation_degrees = idle_rotation
		weapon_socket.scale = Vector2.ONE
		weapon_socket.z_index = weapon_socket_front_z_index

	else:
		# Mirando abajo / frente: usamos el arma delantera.
		weapon_socket.position = weapon_socket_front_position
		weapon_socket.rotation_degrees = idle_rotation
		weapon_socket.scale = Vector2.ONE
		weapon_socket.z_index = weapon_socket_front_z_index

		if weapon_visual != null:
			weapon_visual.visible = true
			weapon_visual.z_index = 0

		if weapon_back_visual != null:
			weapon_back_visual.visible = false

		if weapon_back_socket != null:
			weapon_back_socket.position = weapon_socket_back_position
			weapon_back_socket.rotation_degrees = idle_rotation
			weapon_back_socket.scale = Vector2.ONE
	
func get_weapon_attack_animation_name(direction: Vector2) -> String:
	if direction.length() <= 0.01:
		return "weapon_attack_side"

	var normalized_direction: Vector2 = direction.normalized()

	if absf(normalized_direction.x) >= absf(normalized_direction.y):
		return "weapon_attack_side"

	if normalized_direction.y < 0.0:
		return "weapon_attack_back"

	return "weapon_attack_front"

func sync_back_visuals_transform() -> void:
	if equipment_back_visuals == null:
		return

	# La capa trasera debe vivir en el mismo espacio visual que EquipmentVisuals.
	equipment_back_visuals.position = position
	equipment_back_visuals.scale = scale
	equipment_back_visuals.rotation = rotation
