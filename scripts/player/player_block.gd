extends Node

# Componente responsable SOLO de bloqueo y stamina.
# No decide ataques, equipo, animaciones ni movimiento físico.

@export var block_damage_multiplier: float = 0.35
@export var block_movement_multiplier: float = 0.45
@export var block_arc_degrees: float = 140.0

@export var max_stamina: float = 100.0
@export var block_stamina_drain_per_second: float = 28.0
@export var stamina_regen_per_second: float = 22.0
@export var stamina_regen_delay: float = 0.45
@export var minimum_stamina_to_block: float = 8.0

var player: Node2D = null

var is_blocking: bool = false
var stamina: float = 100.0
var stamina_regen_timer: float = 0.0


func setup(owner_player: Node2D) -> void:
	player = owner_player
	stamina = max_stamina


func process_block(delta: float, facing_direction: Vector2) -> void:
	var wants_to_block: bool = Input.is_action_pressed("block")

	if wants_to_block and stamina >= minimum_stamina_to_block:
		is_blocking = true

		stamina -= block_stamina_drain_per_second * delta
		stamina = maxf(stamina, 0.0)

		stamina_regen_timer = stamina_regen_delay

		if stamina <= 0.0:
			is_blocking = false

		return

	is_blocking = false

	if stamina_regen_timer > 0.0:
		stamina_regen_timer -= delta
		return

	if stamina < max_stamina:
		stamina += stamina_regen_per_second * delta
		stamina = minf(stamina, max_stamina)


func get_modified_incoming_damage(
	amount: float,
	damage_source: Node2D,
	facing_direction: Vector2
) -> float:
	if not is_blocking:
		return amount

	if damage_source == null:
		return amount * block_damage_multiplier

	if is_damage_source_in_front(damage_source, facing_direction):
		return amount * block_damage_multiplier

	return amount


func is_damage_source_in_front(
	damage_source: Node2D,
	facing_direction: Vector2
) -> bool:
	if player == null:
		return false

	var safe_facing_direction: Vector2 = _get_safe_direction(facing_direction)
	var to_source: Vector2 = damage_source.global_position - player.global_position

	if to_source.length() <= 0.01:
		return true

	var direction_to_source: Vector2 = to_source.normalized()
	var angle: float = safe_facing_direction.angle_to(direction_to_source)
	var angle_degrees: float = absf(rad_to_deg(angle))

	return angle_degrees <= block_arc_degrees / 2.0


func get_movement_speed_multiplier() -> float:
	if is_blocking:
		return block_movement_multiplier

	return 1.0


func get_stamina() -> float:
	return stamina


func get_max_stamina() -> float:
	return max_stamina


func get_stamina_ratio() -> float:
	if max_stamina <= 0.0:
		return 0.0

	return stamina / max_stamina


func _get_safe_direction(direction: Vector2) -> Vector2:
	if direction.length() <= 0.01:
		return Vector2.RIGHT

	return direction.normalized()
