extends CharacterBody2D

# Player queda como fachada/orquestador fino.
# Responsabilidades que conserva:
# - conectar componentes
# - exponer API pública para Main, enemigos, HUD y drops
# - coordinar daño/muerte
# No contiene ya lógica detallada de movimiento, equipo, animación ni dibujo debug.

signal stats_changed
signal player_died

@onready var economy: Node = get_node_or_null("Economy")
@onready var combat: Node = get_node_or_null("Combat")
@onready var progression: Node = get_node_or_null("Progression")
@onready var movement: Node = get_node_or_null("Movement")
@onready var equipment: Node = get_node_or_null("Equipment")
@onready var visual_controller: Node = get_node_or_null("VisualController")
@onready var debug_view: Node = get_node_or_null("DebugView")


func _ready() -> void:
	add_to_group("player")
	_setup_components()
	_connect_component_signals()

	if progression != null and progression.has_method("initialize"):
		progression.initialize()

	stats_changed.emit()


func _physics_process(delta: float) -> void:
	if progression != null and "is_dead" in progression and progression.is_dead:
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if movement != null and movement.has_method("process_movement"):
		movement.process_movement(input_dir)

	if combat != null and combat.has_method("process_combat"):
		combat.process_combat(delta)

	if progression != null and progression.has_method("apply_passive_effects"):
		progression.apply_passive_effects(delta)

	if visual_controller != null and visual_controller.has_method("process_visuals"):
		visual_controller.process_visuals(delta)

	# De momento seguimos avisando cada frame porque HUD/stamina/bloqueo cambian continuamente.
	stats_changed.emit()


func _setup_components() -> void:
	if movement != null and movement.has_method("setup"):
		movement.setup(self, combat)

	if equipment != null and equipment.has_method("setup"):
		equipment.setup(combat)

	if visual_controller != null and visual_controller.has_method("setup"):
		visual_controller.setup(self, equipment)

	if debug_view != null and debug_view.has_method("setup"):
		debug_view.setup(self, combat, progression, visual_controller)


func _connect_component_signals() -> void:
	if economy != null and economy.has_signal("economy_changed"):
		economy.economy_changed.connect(_on_stats_source_changed)

	if progression != null:
		if progression.has_signal("progression_changed"):
			progression.progression_changed.connect(_on_stats_source_changed)
		if progression.has_signal("player_died"):
			progression.player_died.connect(_on_progression_player_died)

	if equipment != null and equipment.has_signal("equipment_changed"):
		equipment.equipment_changed.connect(_on_stats_source_changed)


func _on_stats_source_changed() -> void:
	stats_changed.emit()


func _on_progression_player_died() -> void:
	if visual_controller != null and visual_controller.has_method("play_death"):
		visual_controller.play_death()

	player_died.emit()


# -------------------------------------------------------------------
# API pública para drops / enemigos / sistemas externos
# -------------------------------------------------------------------

func add_coins(amount: int) -> void:
	if economy != null and economy.has_method("add_coins"):
		economy.add_coins(amount)


func try_secure_savings(cost: int, amount: int) -> bool:
	if economy != null and economy.has_method("try_secure_savings"):
		return economy.try_secure_savings(cost, amount)
	return false


func register_kill() -> void:
	if progression != null and progression.has_method("register_kill"):
		progression.register_kill()


func take_damage(amount: float, damage_source: Node2D = null) -> void:
	var final_damage: float = amount

	if combat != null and combat.has_method("get_modified_incoming_damage"):
		final_damage = combat.get_modified_incoming_damage(final_damage, damage_source)

	if equipment != null and equipment.has_method("modify_incoming_damage"):
		final_damage = equipment.modify_incoming_damage(final_damage)

	if final_damage <= 0.0:
		return

	if visual_controller != null and visual_controller.has_method("play_hurt"):
		visual_controller.play_hurt()

	if progression != null and progression.has_method("take_damage"):
		progression.take_damage(final_damage)


func die() -> void:
	if progression != null and progression.has_method("die"):
		progression.die()


# -------------------------------------------------------------------
# API de equipo usada por Main.gd
# -------------------------------------------------------------------

func equip_weapon(item_id: String) -> void:
	if equipment != null and equipment.has_method("equip_weapon"):
		equipment.equip_weapon(item_id)


func equip_armor(item_id: String) -> void:
	if equipment != null and equipment.has_method("equip_armor"):
		equipment.equip_armor(item_id)


func get_equipped_weapon_id() -> String:
	if equipment != null and equipment.has_method("get_equipped_weapon_id"):
		return equipment.get_equipped_weapon_id()
	return ""


func get_equipped_weapon_name() -> String:
	if equipment != null and equipment.has_method("get_equipped_weapon_name"):
		return equipment.get_equipped_weapon_name()
	return "Sin arma"


func get_equipped_armor_id() -> String:
	if equipment != null and equipment.has_method("get_equipped_armor_id"):
		return equipment.get_equipped_armor_id()
	return ""


func get_equipped_armor_name() -> String:
	if equipment != null and equipment.has_method("get_equipped_armor_name"):
		return equipment.get_equipped_armor_name()
	return "Sin armadura"


# -------------------------------------------------------------------
# Getters para HUD / Main
# -------------------------------------------------------------------

func get_health() -> float:
	if progression != null and "health" in progression:
		return progression.health
	return 0.0


func get_max_health() -> float:
	if progression != null and "max_health" in progression:
		return progression.max_health
	return 0.0


func get_enemies_killed() -> int:
	if progression != null and "enemies_killed" in progression:
		return progression.enemies_killed
	return 0


func get_run_coins() -> int:
	if economy != null and "run_coins" in economy:
		return economy.run_coins
	return 0


func get_run_savings() -> int:
	if economy != null and "run_savings" in economy:
		return economy.run_savings
	return 0


func get_total_coins_collected() -> int:
	if economy != null and "total_coins_collected" in economy:
		return economy.total_coins_collected
	return 0


func get_attack_damage() -> float:
	if combat != null and "attack_damage" in combat:
		return combat.attack_damage
	return 0.0


func get_attack_range() -> float:
	if combat != null and "melee_range" in combat:
		return combat.melee_range
	return 0.0
