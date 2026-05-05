extends Node

# Fachada/orquestador de combate del jugador.
# Mantiene la API pública que usan Player, Movement, HUD, Equipment y DebugView.
# La lógica detallada se delega en:
# - Attack
# - Block

signal attack_started(attack_direction: Vector2)

var player: Node2D = null

@onready var attack: Node = get_node_or_null("Attack")
@onready var block: Node = get_node_or_null("Block")

# Dirección compartida para ataque y bloqueo.
var facing_direction: Vector2 = Vector2.RIGHT

# Variables públicas sincronizadas para mantener compatibilidad con HUD/DebugView.
var attack_damage: float = 0.0
var attack_cooldown: float = 0.0
var melee_range: float = 0.0
var melee_arc_degrees: float = 0.0
var melee_knockback_force: float = 0.0

var attack_debug_timer: float = 0.0
var last_attack_direction: Vector2 = Vector2.RIGHT

var is_blocking: bool = false


func _ready() -> void:
	player = get_parent() as Node2D

	if attack != null and attack.has_method("setup"):
		attack.setup(player)

	if block != null and block.has_method("setup"):
		block.setup(player)

	_sync_public_state()


func process_combat(delta: float) -> void:
	if player == null:
		return

	update_facing_direction()

	if attack != null and attack.has_method("process_attack_timers"):
		attack.process_attack_timers(delta)

	if block != null and block.has_method("process_block"):
		block.process_block(delta, facing_direction)

	_sync_public_state()

	# Si está bloqueando, no puede atacar.
	if is_blocking:
		return

	if Input.is_action_just_pressed("attack"):
		try_melee_attack()


func update_facing_direction() -> void:
	var input_dir: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if input_dir.length() > 0.0:
		facing_direction = input_dir.normalized()


func try_melee_attack() -> void:
	if attack == null:
		return

	if not attack.has_method("try_melee_attack"):
		return

	var attack_was_started: bool = attack.try_melee_attack(facing_direction)

	_sync_public_state()

	if attack_was_started:
		attack_started.emit(facing_direction)


func get_modified_incoming_damage(
	amount: float,
	damage_source: Node2D = null
) -> float:
	if block == null:
		return amount

	if not block.has_method("get_modified_incoming_damage"):
		return amount

	return block.get_modified_incoming_damage(
		amount,
		damage_source,
		facing_direction
	)


func get_movement_speed_multiplier() -> float:
	if block == null:
		return 1.0

	if not block.has_method("get_movement_speed_multiplier"):
		return 1.0

	return block.get_movement_speed_multiplier()


func get_stamina() -> float:
	if block != null and block.has_method("get_stamina"):
		return block.get_stamina()

	return 0.0


func get_max_stamina() -> float:
	if block != null and block.has_method("get_max_stamina"):
		return block.get_max_stamina()

	return 0.0


func get_stamina_ratio() -> float:
	if block != null and block.has_method("get_stamina_ratio"):
		return block.get_stamina_ratio()

	return 0.0


func add_damage(amount: float) -> void:
	if attack != null and attack.has_method("add_damage"):
		attack.add_damage(amount)

	_sync_public_state()


func multiply_cooldown(multiplier: float) -> void:
	if attack != null and attack.has_method("multiply_cooldown"):
		attack.multiply_cooldown(multiplier)

	_sync_public_state()


func add_range(amount: float) -> void:
	if attack != null and attack.has_method("add_range"):
		attack.add_range(amount)

	_sync_public_state()


func multiply_range(multiplier: float) -> void:
	if attack != null and attack.has_method("multiply_range"):
		attack.multiply_range(multiplier)

	_sync_public_state()


func _sync_public_state() -> void:
	if attack != null:
		if "attack_damage" in attack:
			attack_damage = attack.attack_damage

		if "attack_cooldown" in attack:
			attack_cooldown = attack.attack_cooldown

		if "melee_range" in attack:
			melee_range = attack.melee_range

		if "melee_arc_degrees" in attack:
			melee_arc_degrees = attack.melee_arc_degrees

		if "melee_knockback_force" in attack:
			melee_knockback_force = attack.melee_knockback_force

		if "attack_debug_timer" in attack:
			attack_debug_timer = attack.attack_debug_timer

		if "last_attack_direction" in attack:
			last_attack_direction = attack.last_attack_direction

	if block != null:
		if "is_blocking" in block:
			is_blocking = block.is_blocking
