extends Node

# Componente responsable SOLO del movimiento del enemigo.
# No gestiona vida, daño, loot ni animaciones.

var enemy: CharacterBody2D = null
var target: Node2D = null

var speed: float = 120.0
var knockback_resistance: float = 0.0
var knockback_friction: float = 900.0
var chase_control_during_knockback: float = 0.25

var knockback_velocity: Vector2 = Vector2.ZERO


func setup(
	owner_enemy: CharacterBody2D,
	move_target: Node2D,
	base_speed: float,
	base_knockback_resistance: float,
	base_knockback_friction: float,
	base_chase_control_during_knockback: float
) -> void:
	enemy = owner_enemy
	target = move_target
	speed = base_speed
	knockback_resistance = base_knockback_resistance
	knockback_friction = base_knockback_friction
	chase_control_during_knockback = base_chase_control_during_knockback


func set_target(new_target: Node2D) -> void:
	target = new_target


func set_speed(new_speed: float) -> void:
	speed = new_speed


func move_towards_target() -> void:
	if enemy == null:
		return

	if target == null:
		return

	var direction: Vector2 = enemy.global_position.direction_to(target.global_position)
	var chase_velocity: Vector2 = direction * speed

	# Si está siendo empujado, reducimos temporalmente la persecución.
	# Así el knockback se nota incluso en enemigos rápidos.
	if knockback_velocity.length() > 5.0:
		chase_velocity *= chase_control_during_knockback

	enemy.velocity = chase_velocity + knockback_velocity
	enemy.move_and_slide()


func stop_and_slide() -> void:
	if enemy == null:
		return

	# Si el enemigo está parado por estar atacando, conservamos solo el knockback.
	enemy.velocity = knockback_velocity
	enemy.move_and_slide()


func apply_knockback(direction: Vector2, force: float) -> void:
	if direction.length() <= 0.01:
		return

	var final_force: float = force * (1.0 - knockback_resistance)

	if final_force <= 0.0:
		return

	knockback_velocity += direction.normalized() * final_force


func update_knockback(delta: float) -> void:
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_friction * delta
	)


func has_knockback() -> bool:
	return knockback_velocity.length() > 5.0
