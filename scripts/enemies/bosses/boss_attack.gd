extends Node

# Ataques propios del boss.
#
# V1:
# - ataque normal
# - ataque pesado
# - el ataque pesado tiene más rango, daño y preparación
# - no depende todavía de animaciones reales
#
# Más adelante:
# - conectar hit frames reales de AnimatedSprite2D
# - fases
# - patrones
# - ataques especiales

@export var normal_attack_range: float = 44.0
@export var normal_attack_damage: float = 16.0
@export var normal_attack_windup: float = 0.25
@export var normal_attack_recovery: float = 0.25
@export var normal_attack_cooldown: float = 1.0

@export var heavy_attack_range: float = 72.0
@export var heavy_attack_damage: float = 28.0
@export var heavy_attack_windup: float = 0.65
@export var heavy_attack_recovery: float = 0.45
@export var heavy_attack_cooldown: float = 3.0

# Si el player está dentro de rango de heavy, el boss puede elegirlo.
@export_range(0.0, 1.0, 0.05) var heavy_attack_chance: float = 0.35

var boss: Node2D = null
var target: Node2D = null

var damage_multiplier: float = 1.0

var normal_cooldown_timer: float = 0.0
var heavy_cooldown_timer: float = 0.0

var is_attacking: bool = false
var attack_has_hit: bool = false
var current_attack_name: String = ""
var current_attack_range: float = 0.0
var current_attack_damage: float = 0.0
var current_windup_timer: float = 0.0
var current_recovery_timer: float = 0.0


func setup(
	owner_boss: Node2D,
	attack_target: Node2D,
	base_damage_multiplier: float
) -> void:
	boss = owner_boss
	target = attack_target
	damage_multiplier = base_damage_multiplier


func process_attack(delta: float) -> void:
	if boss == null:
		return

	if target == null:
		return

	_update_cooldowns(delta)

	if is_attacking:
		_process_current_attack(delta)
		return

	if _can_start_heavy_attack():
		if randf() <= heavy_attack_chance:
			_start_heavy_attack()
			return

	if _can_start_normal_attack():
		_start_normal_attack()


func is_busy() -> bool:
	return is_attacking


func is_target_in_any_attack_range() -> bool:
	if target == null or boss == null:
		return false

	var distance := boss.global_position.distance_to(target.global_position)
	return distance <= max(normal_attack_range, heavy_attack_range)


func is_target_in_move_stop_range() -> bool:
	if target == null or boss == null:
		return false

	var distance := boss.global_position.distance_to(target.global_position)

	# El boss se para cuando puede atacar con normal.
	# Si está cerca de heavy pero no de normal, seguirá acercándose.
	return distance <= normal_attack_range


func _update_cooldowns(delta: float) -> void:
	if normal_cooldown_timer > 0.0:
		normal_cooldown_timer = max(0.0, normal_cooldown_timer - delta)

	if heavy_cooldown_timer > 0.0:
		heavy_cooldown_timer = max(0.0, heavy_cooldown_timer - delta)


func _can_start_normal_attack() -> bool:
	if normal_cooldown_timer > 0.0:
		return false

	return _is_target_in_range(normal_attack_range)


func _can_start_heavy_attack() -> bool:
	if heavy_cooldown_timer > 0.0:
		return false

	return _is_target_in_range(heavy_attack_range)


func _start_normal_attack() -> void:
	_start_attack(
		"normal_attack",
		normal_attack_range,
		normal_attack_damage,
		normal_attack_windup,
		normal_attack_recovery
	)


func _start_heavy_attack() -> void:
	_start_attack(
		"heavy_attack",
		heavy_attack_range,
		heavy_attack_damage,
		heavy_attack_windup,
		heavy_attack_recovery
	)


func _start_attack(
	attack_name: String,
	attack_range: float,
	attack_damage: float,
	windup: float,
	recovery: float
) -> void:
	is_attacking = true
	attack_has_hit = false
	current_attack_name = attack_name
	current_attack_range = attack_range
	current_attack_damage = attack_damage * damage_multiplier
	current_windup_timer = windup
	current_recovery_timer = recovery

	if boss != null and boss.has_method("play_animation"):
		if attack_name == "heavy_attack":
			boss.play_animation("heavy_attack")
		else:
			boss.play_animation("attack")


func _process_current_attack(delta: float) -> void:
	if not attack_has_hit:
		current_windup_timer -= delta

		if current_windup_timer > 0.0:
			return

		_apply_current_attack_hit()
		attack_has_hit = true
		return

	current_recovery_timer -= delta

	if current_recovery_timer <= 0.0:
		_finish_attack()


func _apply_current_attack_hit() -> void:
	if target == null:
		return

	if not _is_target_in_range(current_attack_range):
		return

	if target.has_method("take_damage"):
		target.take_damage(current_attack_damage, boss)


func _finish_attack() -> void:
	if current_attack_name == "heavy_attack":
		heavy_cooldown_timer = heavy_attack_cooldown
	else:
		normal_cooldown_timer = normal_attack_cooldown

	is_attacking = false
	attack_has_hit = false
	current_attack_name = ""
	current_attack_range = 0.0
	current_attack_damage = 0.0
	current_windup_timer = 0.0
	current_recovery_timer = 0.0

	if boss != null and boss.has_method("play_animation"):
		boss.play_animation("idle")


func _is_target_in_range(range_value: float) -> bool:
	if boss == null or target == null:
		return false

	return boss.global_position.distance_to(target.global_position) <= range_value
