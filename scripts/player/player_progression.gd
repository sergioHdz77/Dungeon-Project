extends Node

signal progression_changed
signal player_died

@export var max_health: float = 100.0

var health: float = 100.0
var is_dead: bool = false
var enemies_killed: int = 0
var damage_taken_multiplier: float = 1.0
var health_regen_per_second: float = 0.0

func initialize() -> void:
	health = max_health
	is_dead = false
	progression_changed.emit()

func take_damage(amount: float) -> void:
	if is_dead:
		return

	health -= amount * damage_taken_multiplier
	health = max(health, 0.0)

	if health <= 0.0:
		die()
	else:
		progression_changed.emit()

func heal(amount: float) -> void:
	if is_dead:
		return

	health = min(max_health, health + amount)
	progression_changed.emit()

func add_max_health(amount: float, heal_amount: float = 0.0) -> void:
	max_health += amount

	if heal_amount > 0.0:
		health = min(max_health, health + heal_amount)

	progression_changed.emit()

func register_kill() -> void:
	enemies_killed += 1
	progression_changed.emit()

func apply_passive_effects(delta: float) -> void:
	if health_regen_per_second <= 0.0:
		return

	if health >= max_health:
		return

	health = min(max_health, health + health_regen_per_second * delta)
	progression_changed.emit()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	progression_changed.emit()
	player_died.emit()

func add_health_regen(amount: float) -> void:
	health_regen_per_second += amount
	progression_changed.emit()

func multiply_damage_taken(multiplier: float) -> void:
	damage_taken_multiplier *= multiplier
	progression_changed.emit()
