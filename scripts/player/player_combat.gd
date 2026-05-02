extends Node

# Componente de combate del jugador.
#
# Sistema actual:
# - ataque melee manual
# - arco de golpe frontal
# - bloqueo direccional
# - stamina de bloqueo
#
# Ya no contiene:
# - proyectiles
# - aura
# - autoataque
# - búsqueda automática de enemigos

# -------------------------
# ATAQUE MELEE
# -------------------------

@export var attack_damage: float = 20.0
@export var attack_cooldown: float = 0.45
@export var melee_range: float = 90.0
@export var melee_arc_degrees: float = 120.0

var attack_timer: float = 0.0

# Dirección hacia la que mira/ataca/bloquea el jugador.
var facing_direction: Vector2 = Vector2.RIGHT

# Referencia al Player.
var player: Node2D = null


# -------------------------
# DEBUG VISUAL DEL ATAQUE
# -------------------------

@export var attack_debug_duration: float = 0.12

var attack_debug_timer: float = 0.0
var last_attack_direction: Vector2 = Vector2.RIGHT


# -------------------------
# BLOQUEO
# -------------------------

var is_blocking: bool = false

@export var block_damage_multiplier: float = 0.35
@export var block_movement_multiplier: float = 0.45
@export var block_arc_degrees: float = 140.0


# -------------------------
# STAMINA
# -------------------------

@export var max_stamina: float = 100.0
@export var block_stamina_drain_per_second: float = 28.0
@export var stamina_regen_per_second: float = 22.0
@export var stamina_regen_delay: float = 0.45
@export var minimum_stamina_to_block: float = 8.0

var stamina: float = 100.0
var stamina_regen_timer: float = 0.0


func _ready() -> void:
	player = get_parent() as Node2D
	stamina = max_stamina


func process_combat(delta: float) -> void:
	if player == null:
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	if attack_debug_timer > 0.0:
		attack_debug_timer -= delta

	update_facing_direction()
	update_block_state(delta)

	# Si está bloqueando, no puede atacar.
	if is_blocking:
		return

	if Input.is_action_just_pressed("attack"):
		try_melee_attack()


func update_facing_direction() -> void:
	# Usamos los mismos inputs de movimiento que el Player.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Solo actualizamos dirección si el jugador se está moviendo.
	# Si se queda quieto, conserva la última dirección.
	if input_dir.length() > 0.0:
		facing_direction = input_dir.normalized()


func try_melee_attack() -> void:
	if attack_timer > 0.0:
		return

	attack_timer = attack_cooldown

	last_attack_direction = facing_direction
	attack_debug_timer = attack_debug_duration

	var enemies := get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var enemy_2d := enemy as Node2D

		if enemy_2d == null:
			continue

		if is_enemy_inside_melee_arc(enemy_2d):
			if enemy_2d.has_method("take_damage"):
				enemy_2d.call("take_damage", attack_damage)


func is_enemy_inside_melee_arc(enemy: Node2D) -> bool:
	var to_enemy: Vector2 = enemy.global_position - player.global_position
	var distance: float = to_enemy.length()

	if distance > melee_range:
		return false

	# Si está muy pegado al jugador, permitimos el golpe.
	# Evita la sensación rara de tenerlo encima y fallar.
	if distance <= 32.0:
		return true

	var direction_to_enemy: Vector2 = to_enemy.normalized()

	var angle: float = facing_direction.angle_to(direction_to_enemy)
	var angle_degrees: float = absf(rad_to_deg(angle))

	return angle_degrees <= melee_arc_degrees / 2.0


# -------------------------
# BLOQUEO / DAÑO
# -------------------------

func update_block_state(delta: float) -> void:
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


func get_modified_incoming_damage(amount: float, damage_source: Node2D = null) -> float:
	if not is_blocking:
		return amount

	if damage_source == null:
		return amount * block_damage_multiplier

	if is_damage_source_in_front(damage_source):
		return amount * block_damage_multiplier

	return amount


func is_damage_source_in_front(damage_source: Node2D) -> bool:
	if player == null:
		return false

	var to_source: Vector2 = damage_source.global_position - player.global_position

	if to_source.length() <= 0.01:
		return true

	var direction_to_source: Vector2 = to_source.normalized()

	var angle: float = facing_direction.angle_to(direction_to_source)
	var angle_degrees: float = absf(rad_to_deg(angle))

	return angle_degrees <= block_arc_degrees / 2.0


func get_movement_speed_multiplier() -> float:
	if is_blocking:
		return block_movement_multiplier

	return 1.0


# -------------------------
# STAMINA GETTERS
# -------------------------

func get_stamina() -> float:
	return stamina


func get_max_stamina() -> float:
	return max_stamina


func get_stamina_ratio() -> float:
	if max_stamina <= 0.0:
		return 0.0

	return stamina / max_stamina


# -------------------------
# MODIFICADORES DE STATS
# -------------------------

func add_damage(amount: float) -> void:
	attack_damage += amount


func multiply_cooldown(multiplier: float) -> void:
	attack_cooldown *= multiplier


func add_range(amount: float) -> void:
	melee_range += amount


func multiply_range(multiplier: float) -> void:
	melee_range *= multiplier
