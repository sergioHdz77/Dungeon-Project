extends Node

# Componente responsable SOLO del movimiento físico del jugador.
# No decide animaciones, combate, equipo ni progresión.
#
# Ahora también aplica knockback externo.
# El knockback es movimiento físico, por eso vive aquí y no en Player.gd.

@export var speed: float = 220.0
@export var map_half_size: Vector2 = Vector2(1200, 800)
@export var player_radius: float = 12.0

# -------------------------------------------------------------------
# KNOCKBACK
# -------------------------------------------------------------------

@export var knockback_friction: float = 1200.0

# Mientras hay knockback, dejamos algo de control al jugador.
# 0.0 = no puede moverse durante el empuje.
# 1.0 = control total aunque esté siendo empujado.
@export_range(0.0, 1.0, 0.05) var input_control_during_knockback: float = 0.35

var player: CharacterBody2D = null
var combat: Node = null
var knockback_velocity: Vector2 = Vector2.ZERO


func setup(owner_player: CharacterBody2D, combat_component: Node) -> void:
	player = owner_player
	combat = combat_component


func process_movement(input_dir: Vector2) -> void:
	if player == null:
		return

	var delta := get_physics_process_delta_time()

	_update_knockback(delta)

	var final_speed: float = speed

	if combat != null and combat.has_method("get_movement_speed_multiplier"):
		final_speed *= combat.get_movement_speed_multiplier()

	var input_velocity := input_dir * final_speed

	if has_knockback():
		input_velocity *= input_control_during_knockback

	player.velocity = input_velocity + knockback_velocity
	player.move_and_slide()

	_clamp_to_map_bounds()


func apply_knockback(direction: Vector2, force: float) -> void:
	if direction.length() <= 0.01:
		return

	if force <= 0.0:
		return

	knockback_velocity += direction.normalized() * force


func clear_knockback() -> void:
	knockback_velocity = Vector2.ZERO


func has_knockback() -> bool:
	return knockback_velocity.length() > 5.0


func _update_knockback(delta: float) -> void:
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_friction * delta
	)


func _clamp_to_map_bounds() -> void:
	if player == null:
		return

	player.global_position.x = clamp(
		player.global_position.x,
		-map_half_size.x + player_radius,
		map_half_size.x - player_radius
	)

	player.global_position.y = clamp(
		player.global_position.y,
		-map_half_size.y + player_radius,
		map_half_size.y - player_radius
	)
