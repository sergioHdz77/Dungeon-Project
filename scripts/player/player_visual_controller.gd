extends Node

# Componente responsable SOLO de animaciones y nodos visuales.
# Player.gd ya no necesita conocer nombres de animación, flip_h, nodos de arma, etc.

@export var hurt_animation_duration: float = 0.15

var player: CharacterBody2D = null
var equipment: Node = null

var visuals: Node2D = null
var animated_sprite: AnimatedSprite2D = null
var equipment_visuals: Node = null
var weapon_visual: Node2D = null
var armor_visual: Node2D = null

var animation_lock_timer: float = 0.0
var visual_facing_direction: Vector2 = Vector2.RIGHT



func setup(owner_player: CharacterBody2D, equipment_component: Node) -> void:
	player = owner_player
	equipment = equipment_component
	_cache_visual_nodes()
	refresh_equipment_visuals()
	play_idle()

	if equipment != null and equipment.has_signal("equipment_changed"):
		equipment.equipment_changed.connect(refresh_equipment_visuals)
		
func _ready() -> void:
	var player: Node = get_parent()

	if player != null:
		equipment_visuals = player.get_node_or_null("EquipmentVisuals")

func process_visuals(delta: float) -> void:
	if player == null:
		return

	if animation_lock_timer > 0.0:
		animation_lock_timer -= delta

	_update_visual_direction_from_velocity()
	_update_movement_animation()
	update_equipment_idle_pose()

func play_attack(attack_direction: Vector2) -> void:
	_set_visual_direction_from_vector(attack_direction)

	if visual_facing_direction == Vector2.UP:
		play_animation_with_fallback("attack_back", "attack_side", 0.35)
	elif visual_facing_direction == Vector2.DOWN:
		play_animation_with_fallback("attack_front", "attack_side", 0.35)
	else:
		play_animation_with_fallback("attack_side", "attack_side", 0.35)

	if equipment_visuals != null:
		if equipment_visuals.has_method("play_weapon_attack"):
			equipment_visuals.play_weapon_attack(attack_direction)

func play_hurt() -> void:
	play_animation("hurt", hurt_animation_duration)


func play_death() -> void:
	play_animation("death", 999.0)


func play_idle() -> void:
	_play_idle_animation()


func _cache_visual_nodes() -> void:
	if player == null:
		return

	visuals = player.get_node_or_null("Visuals") as Node2D
	if visuals != null:
		animated_sprite = visuals.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	equipment_visuals = player.get_node_or_null("EquipmentVisuals") as Node2D
	if equipment_visuals != null:
		weapon_visual = equipment_visuals.get_node_or_null("WeaponVisual") as Node2D
		armor_visual = equipment_visuals.get_node_or_null("ArmorVisual") as Node2D


func _update_visual_direction_from_velocity() -> void:
	if animated_sprite == null:
		return

	if player.velocity.length() <= 1.0:
		return

	var movement_direction: Vector2 = player.velocity.normalized()

	if absf(movement_direction.x) >= absf(movement_direction.y):
		if movement_direction.x < 0.0:
			visual_facing_direction = Vector2.LEFT
			animated_sprite.flip_h = true
		else:
			visual_facing_direction = Vector2.RIGHT
			animated_sprite.flip_h = false
	else:
		if movement_direction.y < 0.0:
			visual_facing_direction = Vector2.UP
		else:
			visual_facing_direction = Vector2.DOWN

		animated_sprite.flip_h = false


func _update_movement_animation() -> void:
	if animation_lock_timer > 0.0:
		return

	if player.velocity.length() > 1.0:
		_play_walk_animation()
	else:
		_play_idle_animation()

func update_equipment_idle_pose() -> void:
	# Si hay animación bloqueada, normalmente es ataque, hurt o death.
	# No queremos que la pose idle del arma pise el WeaponAnimationPlayer.
	if animation_lock_timer > 0.0:
		return

	if equipment_visuals == null:
		return

	if not equipment_visuals.has_method("update_weapon_idle_pose"):
		return

	equipment_visuals.update_weapon_idle_pose(visual_facing_direction)
	
func _play_walk_animation() -> void:
	if visual_facing_direction == Vector2.UP:
		play_animation_with_fallback("walk_back", "walk_side")
	elif visual_facing_direction == Vector2.DOWN:
		play_animation_with_fallback("walk_front", "walk_side")
	else:
		play_animation_with_fallback("walk_side", "walk_side")


func _play_idle_animation() -> void:
	if visual_facing_direction == Vector2.UP:
		play_animation_with_fallback("idle_back", "idle_side")
	elif visual_facing_direction == Vector2.DOWN:
		play_animation_with_fallback("idle_front", "idle_side")
	else:
		play_animation_with_fallback("idle_side", "idle_side")


func play_animation(animation_name: String, lock_duration: float = 0.0) -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	if animated_sprite.animation == animation_name and animated_sprite.is_playing():
		return

	animated_sprite.play(animation_name)

	if lock_duration > 0.0:
		animation_lock_timer = lock_duration


func play_animation_with_fallback(
	animation_name: String,
	fallback_animation_name: String,
	lock_duration: float = 0.0
) -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null:
		return

	if animated_sprite.sprite_frames.has_animation(animation_name):
		play_animation(animation_name, lock_duration)
		return

	if animated_sprite.sprite_frames.has_animation(fallback_animation_name):
		play_animation(fallback_animation_name, lock_duration)


func has_animated_visuals() -> bool:
	return animated_sprite != null and animated_sprite.sprite_frames != null

func refresh_equipment_visuals() -> void:
	if equipment == null:
		return

	if weapon_visual != null and equipment.has_method("get_equipped_weapon_id"):
		weapon_visual.visible = not equipment.get_equipped_weapon_id().is_empty()

	if armor_visual != null and equipment.has_method("get_equipped_armor_id"):
		armor_visual.visible = not equipment.get_equipped_armor_id().is_empty()


func _on_weapon_equipped(weapon_id: String, weapon_data: Dictionary) -> void:
	print("VisualController: arma equipada: ", weapon_id)

	if equipment_visuals != null:
		if equipment_visuals.has_method("show_weapon"):
			equipment_visuals.show_weapon(weapon_id, weapon_data)


func _on_armor_equipped(armor_id: String, armor_data: Dictionary) -> void:
	print("VisualController: armadura equipada: ", armor_id)

	if equipment_visuals != null:
		if equipment_visuals.has_method("show_armor"):
			equipment_visuals.show_armor(armor_id, armor_data)


func _on_weapon_unequipped() -> void:
	print("VisualController: arma desequipada")

	if equipment_visuals != null:
		if equipment_visuals.has_method("clear_weapon"):
			equipment_visuals.clear_weapon()


func _on_armor_unequipped() -> void:
	print("VisualController: armadura desequipada")

	if equipment_visuals != null:
		if equipment_visuals.has_method("clear_armor"):
			equipment_visuals.clear_armor()
			
func _set_visual_direction_from_vector(direction: Vector2) -> void:
	if animated_sprite == null:
		return

	if direction.length() <= 0.01:
		return

	var normalized_direction: Vector2 = direction.normalized()

	if absf(normalized_direction.x) >= absf(normalized_direction.y):
		if normalized_direction.x < 0.0:
			visual_facing_direction = Vector2.LEFT
			animated_sprite.flip_h = true
		else:
			visual_facing_direction = Vector2.RIGHT
			animated_sprite.flip_h = false
	else:
		if normalized_direction.y < 0.0:
			visual_facing_direction = Vector2.UP
		else:
			visual_facing_direction = Vector2.DOWN

		animated_sprite.flip_h = false
