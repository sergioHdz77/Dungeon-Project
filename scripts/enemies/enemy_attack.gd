extends Node

# Componente responsable SOLO del ataque del enemigo.
# No mueve al enemigo, no gestiona vida y no suelta loot.

@export var attack_range: float = 34.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 1.0
@export var attack_windup: float = 0.25

var enemy: Node2D = null
var target: Node2D = null

var cooldown_timer: float = 0.0
var windup_timer: float = 0.0
var is_preparing_attack: bool = false


func setup(owner_enemy: Node2D, attack_target: Node2D, base_damage: float) -> void:
	enemy = owner_enemy
	target = attack_target
	attack_damage = base_damage


func process_attack(delta: float) -> void:
	if enemy == null:
		return

	if target == null:
		return

	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	if is_preparing_attack:
		process_windup(delta)
		return

	if cooldown_timer > 0.0:
		return

	if is_target_in_range():
		start_attack()


func start_attack() -> void:
	is_preparing_attack = true
	windup_timer = attack_windup


func process_windup(delta: float) -> void:
	windup_timer -= delta

	if windup_timer > 0.0:
		return

	is_preparing_attack = false
	apply_attack_damage()
	cooldown_timer = attack_cooldown


func apply_attack_damage() -> void:
	if target == null:
		return

	if not is_target_in_range():
		return

	if target.has_method("take_damage"):
		target.take_damage(attack_damage, enemy)


func is_target_in_range() -> bool:
	if enemy == null:
		return false

	if target == null:
		return false

	var distance: float = enemy.global_position.distance_to(target.global_position)

	return distance <= attack_range


func is_busy() -> bool:
	return is_preparing_attack
