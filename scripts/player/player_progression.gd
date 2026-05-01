extends Node

# Señal para avisar de que cambió vida, XP, nivel, kills o estadísticas.
# Player la escucha y reemite stats_changed para actualizar el HUD.
signal progression_changed

# Señal para avisar al Player/Main de que hay que mostrar el menú de mejoras.
signal level_up_requested(new_level: int)

# Señal para avisar de que el jugador ha muerto.
signal player_died

# Vida máxima base del jugador.
@export var max_health: float = 100.0

# Vida actual.
var health: float = 100.0

# Controla si el jugador está muerto.
# Evita recibir daño o morir varias veces.
var is_dead: bool = false

# Nivel actual de la run.
var level: int = 1

# XP actual acumulada hacia el siguiente nivel.
var xp: float = 0.0

# XP necesaria para subir de nivel.
var xp_to_next_level: float = 30.0

# Enemigos eliminados durante esta run.
var enemies_killed: int = 0

# XP total recogida durante esta run.
# Se usa para estadísticas finales.
var total_xp_collected: int = 0

# Multiplicador de XP.
# Ejemplo: 1.25 significa +25% XP.
var xp_gain_multiplier: float = 1.0

# Multiplicador de daño recibido.
# Ejemplo: 1.15 significa +15% daño recibido.
var damage_taken_multiplier: float = 1.0

# Regeneración de vida por segundo.
var health_regen_per_second: float = 0.0

# Drenaje de vida por segundo.
# Lo usan mejoras de riesgo/recompensa.
var life_drain_per_second: float = 0.0

func initialize() -> void:
	# Inicializa la vida al empezar la run.
	# Se llama desde Player después de aplicar los bonos meta.
	health = max_health
	is_dead = false
	progression_changed.emit()

func add_xp(amount: float) -> void:
	# Añade XP al jugador.
	# La XP recogida para estadísticas se cuenta antes del multiplicador.
	if amount <= 0.0:
		return
	
	total_xp_collected += int(amount)
	xp += amount * xp_gain_multiplier
	
	# Puede subir más de un nivel si recoge mucha XP de golpe.
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level_up()
	
	progression_changed.emit()

func level_up() -> void:
	# Sube nivel y aumenta la XP necesaria para el siguiente.
	level += 1
	xp_to_next_level = round(xp_to_next_level * 1.35)
	
	progression_changed.emit()
	level_up_requested.emit(level)

func take_damage(amount: float) -> void:
	# Aplica daño al jugador teniendo en cuenta el multiplicador de daño recibido.
	if is_dead:
		return
	
	health -= amount * damage_taken_multiplier
	health = max(health, 0.0)
	
	if health <= 0.0:
		die()
	else:
		progression_changed.emit()

func heal(amount: float) -> void:
	# Cura al jugador sin superar la vida máxima.
	if is_dead:
		return
	
	health = min(max_health, health + amount)
	progression_changed.emit()

func add_max_health(amount: float, heal_amount: float = 0.0) -> void:
	# Aumenta la vida máxima.
	# Opcionalmente también cura una cantidad concreta.
	max_health += amount
	
	if heal_amount > 0.0:
		health = min(max_health, health + heal_amount)
	
	progression_changed.emit()

func register_kill() -> void:
	# Suma una kill.
	# Lo llama el enemigo al morir si su target es el jugador.
	enemies_killed += 1
	progression_changed.emit()

func apply_passive_effects(delta: float) -> void:
	# Aplica efectos pasivos relacionados con vida.
	# La economía pasiva va en PlayerEconomy, no aquí.
	var changed := false
	
	if health_regen_per_second > 0.0 and health < max_health:
		health = min(max_health, health + health_regen_per_second * delta)
		changed = true
	
	if life_drain_per_second > 0.0:
		take_damage(life_drain_per_second * delta)
		return
	
	if changed:
		progression_changed.emit()

func die() -> void:
	# Marca al jugador como muerto y avisa hacia fuera.
	# Main no escucha este nodo directamente; Player reemite la señal.
	if is_dead:
		return
	
	is_dead = true
	
	progression_changed.emit()
	player_died.emit()

func add_life_drain(amount: float) -> void:
	# Aumenta el drenaje pasivo de vida.
	life_drain_per_second += amount
	progression_changed.emit()

func add_health_regen(amount: float) -> void:
	# Aumenta la regeneración pasiva.
	health_regen_per_second += amount
	progression_changed.emit()

func multiply_xp_gain(multiplier: float) -> void:
	# Modifica la ganancia de XP.
	xp_gain_multiplier *= multiplier
	progression_changed.emit()

func multiply_damage_taken(multiplier: float) -> void:
	# Modifica el daño recibido.
	damage_taken_multiplier *= multiplier
	progression_changed.emit()
