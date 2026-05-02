extends CharacterBody2D

const ItemDatabase = preload("res://scripts/data/item_database.gd")

# -------------------------------------------------------------------
# SEÑALES PÚBLICAS
# -------------------------------------------------------------------

signal level_up_requested(new_level: int)
signal stats_changed
signal player_died


# -------------------------------------------------------------------
# COMPONENTES
# -------------------------------------------------------------------

@onready var economy = $Economy
@onready var combat = $Combat
@onready var progression = $Progression


# -------------------------------------------------------------------
# MOVIMIENTO
# -------------------------------------------------------------------

@export var speed: float = 220.0

# Límite provisional del mapa/sala.
# Más adelante esto debería depender de la sala actual.
@export var map_half_size: Vector2 = Vector2(1200, 800)


# -------------------------------------------------------------------
# EQUIPO PROVISIONAL
# -------------------------------------------------------------------

# De momento solo soportamos arma.
# Más adelante esto debería moverse a PlayerEquipment.
var equipped_weapon_id: String = ""
var equipped_weapon_name: String = "Sin arma"

var equipped_armor_id: String = ""
var equipped_armor_name: String = "Sin armadura"

# Multiplicador final de daño recibido por armadura.
# 1.0 = daño completo.
# 0.85 = recibe el 85% del daño.
var armor_damage_taken_multiplier: float = 1.0

# -------------------------------------------------------------------
# CICLO DE VIDA
# -------------------------------------------------------------------

func _ready() -> void:
	add_to_group("player")

	connect_component_signals()

	# Inicializa vida, XP y estado de progresión.
	progression.initialize()

	stats_changed.emit()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if progression.is_dead:
		return

	handle_movement()
	combat.process_combat(delta)
	apply_passive_effects(delta)

	# De momento actualizamos HUD/redraw cada frame porque stamina,
	# bloqueo y barras locales cambian continuamente.
	stats_changed.emit()
	queue_redraw()


func connect_component_signals() -> void:
	economy.economy_changed.connect(_on_economy_changed)

	progression.progression_changed.connect(_on_progression_changed)
	progression.level_up_requested.connect(_on_progression_level_up_requested)
	progression.player_died.connect(_on_progression_player_died)


# -------------------------------------------------------------------
# MOVIMIENTO
# -------------------------------------------------------------------

func handle_movement() -> void:
	var input_dir: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	var final_speed: float = speed

	if combat != null:
		if combat.has_method("get_movement_speed_multiplier"):
			final_speed *= combat.get_movement_speed_multiplier()

	velocity = input_dir * final_speed
	move_and_slide()

	clamp_to_map_bounds()


func clamp_to_map_bounds() -> void:
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


# -------------------------------------------------------------------
# SEÑALES DE COMPONENTES
# -------------------------------------------------------------------

func _on_economy_changed() -> void:
	stats_changed.emit()


func _on_progression_changed() -> void:
	stats_changed.emit()
	queue_redraw()


func _on_progression_level_up_requested(new_level: int) -> void:
	level_up_requested.emit(new_level)


func _on_progression_player_died() -> void:
	player_died.emit()


# -------------------------------------------------------------------
# EFECTOS PASIVOS
# -------------------------------------------------------------------

func apply_passive_effects(delta: float) -> void:
	# Conservamos estos sistemas porque pueden servir para oro/XP
	# y mejoras temporales dentro de la run.

	if economy != null:
		economy.apply_passive_income(delta)

	if progression != null:
		progression.apply_passive_effects(delta)


func apply_meta_upgrades() -> void:
	# Sistema antiguo del prototipo survivor-like.
	# Ya no se usa en el nuevo roguelite dungeon crawler.
	pass


# -------------------------------------------------------------------
# MEJORAS TEMPORALES DE RUN
# -------------------------------------------------------------------

func apply_upgrade(upgrade_id: String) -> void:
	# Sistema provisional para futuras mejoras temporales.
	# Se mantiene porque XP/subida de nivel puede volver más adelante,
	# pero se han eliminado efectos antiguos de proyectiles/aura.

	match upgrade_id:
		"damage":
			combat.add_damage(6.0)

		"cooldown":
			combat.multiply_cooldown(0.88)

		"speed":
			speed += 25.0

		"health":
			progression.add_max_health(20.0, 20.0)

		"range":
			combat.add_range(30.0)

		"regeneration":
			progression.add_health_regen(0.8)

		"risk_damage":
			combat.add_damage(10.0)
			speed *= 0.88

		"risk_xp":
			progression.multiply_xp_gain(1.25)
			progression.multiply_damage_taken(1.15)

		# Legacy del survivor-like. No hacen nada.
		"projectile":
			pass

		"aura":
			pass

		"internship":
			pass

		"overtime":
			pass

		"master_humo":
			pass

		"networking_risky":
			pass

		"dental_insurance":
			pass

	stats_changed.emit()
	queue_redraw()


# -------------------------------------------------------------------
# API PÚBLICA PARA DROPS / ENEMIGOS / SISTEMAS EXTERNOS
# -------------------------------------------------------------------

func add_xp(amount: float) -> void:
	progression.add_xp(amount)


func add_coins(amount: int) -> void:
	economy.add_coins(amount)


func try_secure_savings(cost: int, amount: int) -> bool:
	# Legacy del prototipo anterior.
	# Se mantiene temporalmente por compatibilidad.
	if economy.has_method("try_secure_savings"):
		return economy.try_secure_savings(cost, amount)

	return false


func register_kill() -> void:
	progression.register_kill()


func take_damage(amount: float, damage_source: Node2D = null) -> void:
	var final_damage: float = amount

	# Primero aplicamos bloqueo.
	if combat != null:
		if combat.has_method("get_modified_incoming_damage"):
			final_damage = combat.get_modified_incoming_damage(amount, damage_source)

	# Después aplicamos reducción de armadura.
	final_damage *= armor_damage_taken_multiplier

	progression.take_damage(final_damage)


func die() -> void:
	progression.die()


# -------------------------------------------------------------------
# EQUIPO
# -------------------------------------------------------------------

func equip_weapon(item_id: String) -> void:
	if item_id.is_empty():
		return

	var item_data: Dictionary = ItemDatabase.get_item(item_id)

	if item_data.is_empty():
		push_warning("No existe item en ItemDatabase: %s" % item_id)
		return

	var item_type: String = str(item_data.get("type", ""))

	if item_type != "weapon":
		push_warning("El item no es un arma: %s" % item_id)
		return

	equipped_weapon_id = item_id
	equipped_weapon_name = str(item_data.get("name", "Arma desconocida"))

	var damage_bonus: float = float(item_data.get("attack_damage_bonus", 0.0))

	if combat != null:
		combat.add_damage(damage_bonus)

	print("Arma equipada: ", equipped_weapon_name, " | daño bonus: ", damage_bonus)

	stats_changed.emit()
	queue_redraw()

func equip_armor(item_id: String) -> void:
	if item_id.is_empty():
		return

	var item_data: Dictionary = ItemDatabase.get_item(item_id)

	if item_data.is_empty():
		push_warning("No existe item en ItemDatabase: %s" % item_id)
		return

	var item_type: String = str(item_data.get("type", ""))

	if item_type != "armor":
		push_warning("El item no es una armadura: %s" % item_id)
		return

	equipped_armor_id = item_id
	equipped_armor_name = str(item_data.get("name", "Armadura desconocida"))

	armor_damage_taken_multiplier = float(item_data.get("damage_taken_multiplier", 1.0))

	print(
		"Armadura equipada: ",
		equipped_armor_name,
		" | multiplicador daño recibido: ",
		armor_damage_taken_multiplier
	)

	stats_changed.emit()
	queue_redraw()

func get_equipped_weapon_name() -> String:
	return equipped_weapon_name

func get_equipped_weapon_id() -> String:
	return equipped_weapon_id

func get_equipped_armor_name() -> String:
	return equipped_armor_name

func get_equipped_armor_id() -> String:
	return equipped_armor_id

# -------------------------------------------------------------------
# DIBUJO DEBUG / PLACEHOLDER
# -------------------------------------------------------------------

func _draw() -> void:
	draw_melee_attack_debug()
	draw_block_debug()
	draw_player_body()
	draw_health_bar()
	draw_stamina_bar()
	draw_xp_bar()


func draw_melee_attack_debug() -> void:
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

	draw_arc(
		Vector2.ZERO,
		radius,
		start_angle,
		end_angle,
		24,
		Color(1.0, 0.9, 0.35, 0.9),
		4.0
	)

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
	draw_circle(Vector2.ZERO, 12.0, Color(0.85, 0.85, 0.95))


func draw_health_bar() -> void:
	var bar_width: float = 44.0
	var bar_height: float = 6.0
	var bar_position: Vector2 = Vector2(-bar_width / 2.0, -36.0)
	var health_ratio: float = 0.0

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
	if combat == null:
		return

	if not combat.has_method("get_stamina_ratio"):
		return

	var bar_width: float = 44.0
	var bar_height: float = 4.0
	var bar_position: Vector2 = Vector2(-bar_width / 2.0, -27.0)
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
	var bar_width: float = 44.0
	var bar_height: float = 4.0
	var bar_position: Vector2 = Vector2(-bar_width / 2.0, -21.0)
	var xp_ratio: float = 0.0

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


# -------------------------------------------------------------------
# GETTERS PARA HUD / MAIN
# -------------------------------------------------------------------

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
	# Legacy del prototipo anterior.
	if "run_savings" in economy:
		return economy.run_savings

	return 0


func get_total_coins_collected() -> int:
	return economy.total_coins_collected


func get_passive_coin_per_second() -> float:
	return economy.passive_coin_per_second


func get_attack_damage() -> float:
	return combat.attack_damage


func get_attack_range() -> float:
	return combat.melee_range


# -------------------------------------------------------------------
# GETTERS LEGACY PARA NO ROMPER SCRIPTS ANTIGUOS
# -------------------------------------------------------------------

func get_projectile_count() -> int:
	return 0


func get_aura_level() -> int:
	return 0


func get_aura_damage_per_second() -> float:
	return 0.0
