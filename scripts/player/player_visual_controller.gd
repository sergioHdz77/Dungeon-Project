extends Node

# Componente responsable SOLO de animaciones y nodos visuales.
# Player.gd ya no necesita conocer nombres de animación, flip_h, nodos de arma, etc.

@export var hurt_animation_duration: float = 0.15

# -------------------------------------------------------------------
# FEEDBACK VISUAL DE DAÑO / INVULNERABILIDAD
# -------------------------------------------------------------------

@export var damage_flash_duration: float = 0.08
@export var invulnerability_blink_interval: float = 0.08

@export var normal_modulate: Color = Color(1, 1, 1, 1)
@export var damage_flash_modulate: Color = Color(1, 0.25, 0.25, 1)
@export var invulnerability_blink_modulate: Color = Color(1, 1, 1, 0.35)

var damage_flash_timer: float = 0.0
var invulnerability_feedback_active: bool = false
var blink_timer: float = 0.0
var blink_visible: bool = true

var player: CharacterBody2D = null
var equipment: Node = null

var visuals: Node2D = null
var animated_sprite: AnimatedSprite2D = null
var equipment_visuals: Node = null

var animation_lock_timer: float = 0.0
var visual_facing_direction: Vector2 = Vector2.RIGHT



func setup(owner_player: CharacterBody2D, equipment_component: Node) -> void:
	player = owner_player
	equipment = equipment_component
	_cache_visual_nodes()
	play_idle()

		
func _ready() -> void:
	var owner_player: Node = get_parent()

	if owner_player != null:
		equipment_visuals = owner_player.get_node_or_null("EquipmentVisuals")

func process_visuals(delta: float) -> void:
	if player == null:
		return

	if animation_lock_timer > 0.0:
		animation_lock_timer -= delta

	_update_visual_direction_from_velocity()
	_update_movement_animation()
	update_equipment_idle_pose()
	_process_damage_feedback(delta)
	
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
	start_damage_feedback()
	play_animation("hurt", hurt_animation_duration)


func play_death() -> void:
	reset_damage_feedback()
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
		
func start_damage_feedback() -> void:
	damage_flash_timer = damage_flash_duration
	_apply_visual_modulate(damage_flash_modulate)


func set_invulnerability_feedback(active: bool) -> void:
	if invulnerability_feedback_active == active:
		return

	invulnerability_feedback_active = active
	blink_timer = 0.0
	blink_visible = true

	if not invulnerability_feedback_active and damage_flash_timer <= 0.0:
		_apply_visual_modulate(normal_modulate)


func _process_damage_feedback(delta: float) -> void:
	if damage_flash_timer > 0.0:
		damage_flash_timer -= delta

		if damage_flash_timer > 0.0:
			_apply_visual_modulate(damage_flash_modulate)
			return

		damage_flash_timer = 0.0

	if invulnerability_feedback_active:
		_process_invulnerability_blink(delta)
		return

	_apply_visual_modulate(normal_modulate)


func _process_invulnerability_blink(delta: float) -> void:
	blink_timer -= delta

	if blink_timer > 0.0:
		return

	blink_timer = invulnerability_blink_interval
	blink_visible = not blink_visible

	if blink_visible:
		_apply_visual_modulate(normal_modulate)
	else:
		_apply_visual_modulate(invulnerability_blink_modulate)


func _apply_visual_modulate(color: Color) -> void:
	if visuals != null:
		visuals.modulate = color

	if equipment_visuals != null and equipment_visuals is CanvasItem:
		var equipment_canvas := equipment_visuals as CanvasItem
		equipment_canvas.modulate = color


func reset_damage_feedback() -> void:
	damage_flash_timer = 0.0
	invulnerability_feedback_active = false
	blink_timer = 0.0
	blink_visible = true
	_apply_visual_modulate(normal_modulate)
