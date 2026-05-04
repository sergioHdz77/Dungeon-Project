extends Node

# Componente responsable SOLO del ataque melee del jugador.
# No gestiona bloqueo, stamina, vida, equipo ni movimiento.

signal attack_performed

@export var attack_damage: float = 20.0
@export var attack_cooldown: float = 0.45
@export var melee_range: float = 90.0
@export var melee_arc_degrees: float = 120.0
@export var melee_knockback_force: float = 350.0

@export var attack_debug_duration: float = 0.12

var player: Node2D = null

var attack_timer: float = 0.0
var attack_debug_timer: float = 0.0
var last_attack_direction: Vector2 = Vector2.RIGHT


func setup(owner_player: Node2D) -> void:
	player = owner_player


func process_attack_timers(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta

	if attack_debug_timer > 0.0:
		attack_debug_timer -= delta


func try_melee_attack(facing_direction: Vector2) -> bool:
	if player == null:
		return false

	if attack_timer > 0.0:
		return false

	var attack_direction: Vector2 = _get_safe_direction(facing_direction)

	attack_timer = attack_cooldown
	last_attack_direction = attack_direction
	attack_debug_timer = attack_debug_duration

	var enemies: Array = get_tree().get_nodes_in_group("enemies")

	for enemy: Node in enemies:
		if not is_instance_valid(enemy):
			continue

		var enemy_2d := enemy as Node2D

		if enemy_2d == null:
			continue

		if is_enemy_inside_melee_arc(enemy_2d, attack_direction):
			if enemy_2d.has_method("take_damage"):
				enemy_2d.call("take_damage", attack_damage)

			apply_knockback_to_enemy(enemy_2d, attack_direction)

	attack_performed.emit()
	return true


func is_enemy_inside_melee_arc(enemy: Node2D, attack_direction: Vector2) -> bool:
	if player == null:
		return false

	var to_enemy: Vector2 = enemy.global_position - player.global_position
	var distance: float = to_enemy.length()

	if distance > melee_range:
		return false

	# Si está muy pegado al jugador, permitimos el golpe.
	# Evita que un enemigo encima del jugador falle por ángulo raro.
	if distance <= 32.0:
		return true

	var direction_to_enemy: Vector2 = to_enemy.normalized()
	var angle: float = attack_direction.angle_to(direction_to_enemy)
	var angle_degrees: float = absf(rad_to_deg(angle))

	return angle_degrees <= melee_arc_degrees / 2.0


func apply_knockback_to_enemy(enemy: Node2D, attack_direction: Vector2) -> void:
	if player == null:
		return

	if not enemy.has_method("apply_knockback"):
		return

	var direction: Vector2 = enemy.global_position - player.global_position

	if direction.length() <= 0.01:
		direction = attack_direction

	enemy.call(
		"apply_knockback",
		direction.normalized(),
		melee_knockback_force
	)


func add_damage(amount: float) -> void:
	attack_damage += amount


func multiply_cooldown(multiplier: float) -> void:
	attack_cooldown *= multiplier


func add_range(amount: float) -> void:
	melee_range += amount


func multiply_range(multiplier: float) -> void:
	melee_range *= multiplier


func _get_safe_direction(direction: Vector2) -> Vector2:
	if direction.length() <= 0.01:
		return Vector2.RIGHT

	return direction.normalized()
