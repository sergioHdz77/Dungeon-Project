extends Node

# Este componente sustituye el combate survivor-like anterior.
#
# Antes:
# - buscaba enemigos automáticamente
# - disparaba proyectiles
# - aplicaba aura
#
# Ahora:
# - espera a que el jugador pulse attack
# - hace un golpe melee corto
# - golpea enemigos delante del jugador
# - usa cooldown para evitar spam

# Daño del ataque melee.
@export var attack_damage: float = 20.0

# Tiempo entre ataques.
@export var attack_cooldown: float = 0.45

# Alcance del golpe cuerpo a cuerpo.
@export var melee_range: float = 90.0

# Anchura del golpe en grados.
# 90 grados significa que golpea en un cono frontal amplio.
@export var melee_arc_degrees: float = 120.0

# Mantengo attack_range para no romper HUD/getters antiguos.
# Internamente lo usaremos como alias visual del melee_range.
@export var attack_range: float = 70.0

# Variables antiguas conservadas para que Player.gd no rompa todavía.
# Más adelante limpiaremos esto.
@export var projectile_count: int = 0
@export var aura_level: int = 0
@export var aura_damage_per_second: float = 0.0
@export var aura_radius: float = 0.0

# Tiempo que se verá el arco del ataque.
@export var attack_debug_duration: float = 0.12

# Multiplicador de daño recibido mientras bloquea.
# 0.35 significa que recibe solo el 35% del daño.
@export var block_damage_multiplier: float = 0.35

# Multiplicador de velocidad mientras bloquea.
# 0.45 significa que se mueve al 45% de su velocidad normal.
@export var block_movement_multiplier: float = 0.45

# Temporizador visual del ataque.
var attack_debug_timer: float = 0.0

# Dirección usada para dibujar el último ataque.
var last_attack_direction: Vector2 = Vector2.RIGHT

# Temporizador interno del cooldown.
var attack_timer: float = 0.0

# Dirección hacia la que mira/ataca el jugador.
# Por defecto mira a la derecha.
var facing_direction: Vector2 = Vector2.RIGHT

# Referencia al Player.
var player: Node2D = null

# Indica si el jugador está bloqueando ahora mismo.
var is_blocking: bool = false



func _ready() -> void:
	player = get_parent() as Node2D
	attack_range = melee_range


func process_combat(delta: float) -> void:
	if player == null:
		return

	# Reducimos cooldown.
	if attack_timer > 0.0:
		attack_timer -= delta

	# Reducimos el tiempo visible del arco de ataque.
	if attack_debug_timer > 0.0:
		attack_debug_timer -= delta

	# Actualizamos dirección de ataque/bloqueo según movimiento.
	update_facing_direction()

	# Actualizamos si el jugador está bloqueando.
	update_block_state()

	# Si está bloqueando, no puede atacar.
	if is_blocking:
		return

	# Ataque manual.
	if Input.is_action_just_pressed("attack"):
		try_melee_attack()

func update_facing_direction() -> void:
	# Usamos los mismos inputs de movimiento que el Player.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Solo cambiamos la dirección si el jugador está pulsando movimiento.
	# Así, si se queda quieto, ataca hacia la última dirección usada.
	if input_dir.length() > 0.0:
		facing_direction = input_dir.normalized()


func try_melee_attack() -> void:
	# Si el ataque está en cooldown, no hacemos nada.
	if attack_timer > 0.0:
		return

	attack_timer = attack_cooldown
	
	#guardamos datos visuales del ataque
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
				print("Golpeando enemigo: ", enemy_2d.name, " daño: ", attack_damage)
				enemy_2d.call("take_damage", attack_damage)


func is_enemy_inside_melee_arc(enemy: Node2D) -> bool:
	var to_enemy: Vector2 = enemy.global_position - player.global_position
	var distance: float = to_enemy.length()

	# Rango máximo del golpe.
	if distance > melee_range:
		return false

	# Si el enemigo está muy pegado al jugador, permitimos el golpe.
	# Esto evita la sensación rara de "lo tengo encima pero no le doy".
	if distance <= 32.0:
		return true

	var direction_to_enemy: Vector2 = to_enemy.normalized()

	# Ángulo entre la dirección del jugador y la dirección al enemigo.
	var angle: float = facing_direction.angle_to(direction_to_enemy)
	var angle_degrees: float = absf(rad_to_deg(angle))

	# Cono frontal.
	return angle_degrees <= melee_arc_degrees / 2.0
	
func update_block_state() -> void:
	# El bloqueo se mantiene mientras el jugador pulse la acción block.
	is_blocking = Input.is_action_pressed("block")
	
func get_modified_incoming_damage(amount: float) -> float:
	# Permite que Player pregunte cuánto daño debe recibir realmente.
	# Si está bloqueando, reducimos el daño.
	# Si no está bloqueando, entra completo.

	if is_blocking:
		return amount * block_damage_multiplier

	return amount

func get_movement_speed_multiplier() -> float:
	# Permite que Player pregunte si debe moverse más lento.
	# De momento solo afecta el bloqueo.
	# Más adelante aquí también podrían entrar peso de armadura,
	# ralentizaciones, buffs, etc.

	if is_blocking:
		return block_movement_multiplier

	return 1.0

# Métodos antiguos conservados para no romper llamadas existentes.
# Luego limpiaremos Player.gd y el HUD.

func add_damage(amount: float) -> void:
	attack_damage += amount


func multiply_cooldown(multiplier: float) -> void:
	attack_cooldown *= multiplier


func add_projectiles(_amount: int) -> void:
	# Ya no usamos proyectiles.
	pass


func add_range(amount: float) -> void:
	melee_range += amount
	attack_range = melee_range


func multiply_range(multiplier: float) -> void:
	melee_range *= multiplier
	attack_range = melee_range


func upgrade_aura() -> void:
	# El aura survivor-like queda desactivada.
	pass
