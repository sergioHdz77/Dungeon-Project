extends CharacterBody2D

# Señales públicas del jugador.
# Main escucha estas señales, no los componentes internos.
signal level_up_requested(new_level: int)
signal stats_changed
signal player_died

# Componentes internos del jugador.
# Player actúa como fachada: otros scripts hablan con Player,
# y Player delega en Economy, Combat o Progression.
@onready var economy = $Economy
@onready var combat = $Combat
@onready var progression = $Progression

# Velocidad de movimiento del jugador.
@export var speed: float = 220.0

# Mitad del tamaño del mapa.
# Se usa para impedir que el jugador salga fuera del rectángulo.
@export var map_half_size: Vector2 = Vector2(1200, 800)

func _ready() -> void:
	
	# Marcamos este nodo como jugador para que puertas y otros sistemas
	# puedan detectarlo sin depender solo del nombre del nodo.
	add_to_group("player")
	
	# Conectamos señales internas de los componentes.
	economy.economy_changed.connect(_on_economy_changed)
	progression.progression_changed.connect(_on_progression_changed)
	progression.level_up_requested.connect(_on_progression_level_up_requested)
	progression.player_died.connect(_on_progression_player_died)
	
	# Aplicamos progresión meta antes de inicializar vida,
	# para que la vida máxima aumentada se tenga en cuenta.
	apply_meta_upgrades()
	progression.initialize()
	
	stats_changed.emit()
	queue_redraw()

func _physics_process(delta: float) -> void:
	# Si el jugador ha muerto, deja de moverse.
	if progression.is_dead:
		return
	
	handle_movement()
	
	# Nuevo combate manual.
	# Ya no dispara automáticamente porque hemos reescrito PlayerCombat.
	combat.process_combat(delta)
	
	apply_passive_effects(delta)
	
	queue_redraw()

func handle_movement() -> void:
	# Lee input desde Input Map y mueve al jugador.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Velocidad final del jugador.
	# Normalmente es speed, pero puede modificarse por bloqueo,
	# equipo pesado, estados alterados, etc.
	var final_speed: float = speed

	if combat != null:
		if combat.has_method("get_movement_speed_multiplier"):
			final_speed *= combat.get_movement_speed_multiplier()

	velocity = input_dir * final_speed
	move_and_slide()
	
	# Evita que el jugador salga del mapa.
	var player_radius: float = 12.0

	global_position.x = clamp(
		global_position.x,
		-map_half_size.x + player_radius,
		map_half_size.x - player_radius
	)

	global_position.y = clamp(
		global_position.y,
		-map_half_size.y + player_radius,
		map_half_size.y - player_radius
	)

func _on_economy_changed() -> void:
	# La economía cambió, así que el HUD debe actualizarse.
	stats_changed.emit()

func _on_progression_changed() -> void:
	# Vida, XP, nivel o stats cambiaron.
	stats_changed.emit()
	queue_redraw()

func _on_progression_level_up_requested(new_level: int) -> void:
	# Reemitimos hacia Main.
	# Main no necesita saber que existe Progression.
	level_up_requested.emit(new_level)

func _on_progression_player_died() -> void:
	# Reemitimos hacia Main.
	player_died.emit()

func apply_passive_effects(delta: float) -> void:
	# Efectos pasivos de economía.
	economy.apply_passive_income(delta)
	
	# Efectos pasivos de vida: regen/drenaje.
	progression.apply_passive_effects(delta)

func apply_meta_upgrades() -> void:
	# Bonos iniciales según ahorro meta total.
	var meta_savings: int = SaveManager.meta_savings
	
	if meta_savings >= 30:
		progression.add_max_health(10.0)
	
	if meta_savings >= 75:
		combat.add_damage(4.0)
	
	if meta_savings >= 150:
		speed += 20.0
	
	if meta_savings >= 300:
		combat.add_projectiles(1)

func apply_upgrade(upgrade_id: String) -> void:
	# Aplica una mejora elegida en el menú de subida de nivel.
	# Los efectos concretos se delegan a los componentes correspondientes.
	match upgrade_id:
		"damage":
			combat.add_damage(6.0)
		
		"cooldown":
			combat.multiply_cooldown(0.88)
		
		"speed":
			speed += 25.0
		
		"health":
			progression.add_max_health(20.0, 20.0)
		
		"projectile":
			combat.add_projectiles(1)
		
		"range":
			combat.add_range(80.0)
		
		"aura":
			combat.upgrade_aura()
		
		"internship":
			economy.add_passive_coin_rate(1.0)
			progression.add_life_drain(0.35)
		
		"overtime":
			combat.add_damage(10.0)
			speed *= 0.88
		
		"master_humo":
			progression.multiply_xp_gain(1.25)
			progression.multiply_damage_taken(1.15)
		
		"networking_risky":
			combat.add_projectiles(1)
			combat.multiply_range(0.85)
		
		"dental_insurance":
			progression.add_health_regen(0.8)
			combat.multiply_cooldown(1.12)
	
	stats_changed.emit()
	queue_redraw()

# Métodos públicos usados por drops, enemigos y zonas.
# Mantienen una API simple: otros nodos hablan con Player,
# no con sus componentes internos.

func add_xp(amount: float) -> void:
	progression.add_xp(amount)

func add_coins(amount: int) -> void:
	economy.add_coins(amount)

func try_secure_savings(cost: int, amount: int) -> bool:
	return economy.try_secure_savings(cost, amount)

func register_kill() -> void:
	progression.register_kill()

func take_damage(amount: float) -> void:
	# El daño pasa primero por Combat porque Combat sabe
	# si el jugador está bloqueando o no.

	var final_damage: float = amount

	if combat != null:
		if combat.has_method("get_modified_incoming_damage"):
			final_damage = combat.get_modified_incoming_damage(amount)

	progression.take_damage(final_damage)

func die() -> void:
	progression.die()

func _draw() -> void:
	draw_aura()
	draw_melee_attack_debug()
	draw_block_debug()
	draw_player_body()
	draw_health_bar()
	draw_stamina_bar()
	draw_xp_bar()

func draw_aura() -> void:
	# Dibuja el aura si está desbloqueada.
	if combat.aura_level <= 0:
		return
	
	draw_circle(Vector2.ZERO, combat.aura_radius, Color(0.55, 0.25, 1.0, 0.14))
	draw_arc(Vector2.ZERO, combat.aura_radius, 0.0, TAU, 64, Color(0.7, 0.45, 1.0, 0.85), 2.0)
	
func draw_melee_attack_debug() -> void:
	# Dibuja temporalmente el arco del ataque melee.
	# Esto es solo debug visual. Más adelante lo cambiaremos por animación real.

	if combat == null:
		return

	if combat.attack_debug_timer <= 0.0:
		return

	var attack_direction: Vector2 = combat.last_attack_direction.normalized()
	var base_angle: float = attack_direction.angle()

	var half_arc: float = deg_to_rad(combat.melee_arc_degrees / 2.0)
	var start_angle: float = base_angle - half_arc
	var end_angle: float = base_angle + half_arc

	var radius: float = combat.melee_range

	# Arco exterior del golpe.
	draw_arc(
		Vector2.ZERO,
		radius,
		start_angle,
		end_angle,
		24,
		Color(1.0, 0.9, 0.35, 0.9),
		4.0
	)

	# Dos líneas laterales del cono.
	var left_dir: Vector2 = Vector2.RIGHT.rotated(start_angle)
	var right_dir: Vector2 = Vector2.RIGHT.rotated(end_angle)

	draw_line(
		Vector2.ZERO,
		left_dir * radius,
		Color(1.0, 0.9, 0.35, 0.55),
		2.0
	)

	draw_line(
		Vector2.ZERO,
		right_dir * radius,
		Color(1.0, 0.9, 0.35, 0.55),
		2.0
	)

func draw_block_debug() -> void:
	# Dibujo provisional para ver cuándo el jugador está bloqueando.
	# Más adelante será una animación o sprite de escudo.

	if combat == null:
		return

	if not combat.is_blocking:
		return

	var block_direction: Vector2 = combat.facing_direction.normalized()
	var block_center: Vector2 = block_direction * 22.0

	draw_circle(
		block_center,
		14.0,
		Color(0.25, 0.55, 1.0, 0.45)
	)

	draw_arc(
		block_center,
		14.0,
		0.0,
		TAU,
		24,
		Color(0.45, 0.75, 1.0, 0.95),
		3.0
	)

func draw_player_body() -> void:
	# Placeholder visual del jugador.
	draw_circle(Vector2.ZERO, 12, Color(0.85, 0.85, 0.95))

func draw_health_bar() -> void:
	# Barra de vida local encima del jugador.
	var bar_width := 44.0
	var bar_height := 6.0
	var bar_position := Vector2(-bar_width / 2.0, -32.0)
	var health_ratio := 0.0
	
	if progression.max_health > 0.0:
		health_ratio = progression.health / progression.max_health
	
	draw_rect(
		Rect2(bar_position, Vector2(bar_width, bar_height)),
		Color(0.15, 0.15, 0.15)
	)
	
	draw_rect(
		Rect2(bar_position, Vector2(bar_width * health_ratio, bar_height)),
		Color(0.2, 0.9, 0.3)
	)
	
func draw_stamina_bar() -> void:
	# Barra local de stamina debajo de la vida.
	# Es provisional hasta adaptar el HUD.

	if combat == null:
		return

	if not combat.has_method("get_stamina_ratio"):
		return

	var bar_width: float = 44.0
	var bar_height: float = 4.0
	var bar_position: Vector2 = Vector2(-bar_width / 2.0, -18.0)
	var stamina_ratio: float = combat.get_stamina_ratio()

	draw_rect(
		Rect2(bar_position, Vector2(bar_width, bar_height)),
		Color(0.10, 0.10, 0.10)
	)

	draw_rect(
		Rect2(bar_position, Vector2(bar_width * stamina_ratio, bar_height)),
		Color(0.35, 0.75, 1.0)
	)
	
func draw_xp_bar() -> void:
	# Barra de XP local encima del jugador.
	var bar_width := 44.0
	var bar_height := 4.0
	var bar_position := Vector2(-bar_width / 2.0, -24.0)
	var xp_ratio := 0.0
	
	if progression.xp_to_next_level > 0.0:
		xp_ratio = progression.xp / progression.xp_to_next_level
	
	draw_rect(
		Rect2(bar_position, Vector2(bar_width, bar_height)),
		Color(0.1, 0.1, 0.2)
	)
	
	draw_rect(
		Rect2(bar_position, Vector2(bar_width * xp_ratio, bar_height)),
		Color(0.2, 0.7, 1.0)
	)

# Getters públicos para UI y pantalla final.
# Así HUD/Main no acceden directamente a componentes internos.

func get_level() -> int:
	return progression.level

func get_health() -> float:
	return progression.health

func get_max_health() -> float:
	return progression.max_health

func get_xp() -> float:
	return progression.xp

func get_xp_to_next_level() -> float:
	return progression.xp_to_next_level

func get_enemies_killed() -> int:
	return progression.enemies_killed

func get_total_xp_collected() -> int:
	return progression.total_xp_collected

func get_run_coins() -> int:
	return economy.run_coins

func get_run_savings() -> int:
	return economy.run_savings

func get_total_coins_collected() -> int:
	return economy.total_coins_collected

func get_passive_coin_per_second() -> float:
	return economy.passive_coin_per_second

func get_attack_damage() -> float:
	return combat.attack_damage

func get_projectile_count() -> int:
	return combat.projectile_count

func get_attack_range() -> float:
	return combat.attack_range

func get_aura_level() -> int:
	return combat.aura_level

func get_aura_damage_per_second() -> float:
	return combat.aura_damage_per_second
