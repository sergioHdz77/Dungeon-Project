extends Node

# Movimiento propio del boss.
# No reutiliza EnemyMovement para no arrastrar lógica de enemigo común.
# De momento:
# - persigue al player
# - se detiene si está en rango de ataque
# - soporta knockback aunque por defecto será muy resistente

var boss: CharacterBody2D = null
var target: Node2D = null

var speed: float = 70.0
var knockback_resistance: float = 0.8
var knockback_friction: float = 1000.0
var knockback_velocity: Vector2 = Vector2.ZERO


func setup(
	owner_boss: CharacterBody2D,
	move_target: Node2D,
	base_speed: float,
	base_knockback_resistance: float,
	base_knockback_friction: float
) -> void:
	boss = owner_boss
	target = move_target
	speed = base_speed
	knockback_resistance = base_knockback_resistance
	knockback_friction = base_knockback_friction


func process_movement(delta: float, should_move: bool) -> void:
	if boss == null:
		return

	_update_knockback(delta)

	if not should_move:
		boss.velocity = knockback_velocity
		boss.move_and_slide()
		return

	if target == null:
		boss.velocity = knockback_velocity
		boss.move_and_slide()
		return

	var direction := boss.global_position.direction_to(target.global_position)
	boss.velocity = direction * speed + knockback_velocity
	boss.move_and_slide()


func apply_knockback(direction: Vector2, force: float) -> void:
	if direction.length() <= 0.01:
		return

	var final_force := force * (1.0 - knockback_resistance)

	if final_force <= 0.0:
		return

	knockback_velocity += direction.normalized() * final_force


func _update_knockback(delta: float) -> void:
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_friction * delta
	)
