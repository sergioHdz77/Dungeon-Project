extends RefCounted

# EnemyDatabase centraliza qué enemigos existen y cuándo aparecen.
# El spawner solo pide un enemigo según el progreso de run.

const ENEMY_NORMAL := preload("res://scenes/enemies/enemy.tscn")
const ENEMY_FAST := preload("res://scenes/enemies/enemy_fast.tscn")
const ENEMY_TANK := preload("res://scenes/enemies/enemy_tank.tscn")

static func get_enemy_pool(run_progress: float) -> Array:
	# Devuelve una lista de enemigos posibles con pesos.
	# run_progress va de 0.0 a 1.0.
	# 0.0 = inicio de run.
	# 1.0 = final de run.
	
	if run_progress < 0.25:
		# Primera parte: solo enemigo normal para no saturar al jugador.
		return [
			{
				"scene": ENEMY_NORMAL,
				"weight": 100
			}
		]
	
	if run_progress < 0.60:
		# Parte media: entran rápidos y algún tanque raro.
		return [
			{
				"scene": ENEMY_NORMAL,
				"weight": 75
			},
			{
				"scene": ENEMY_FAST,
				"weight": 20
			},
			{
				"scene": ENEMY_TANK,
				"weight": 5
			}
		]
	
	# Parte final: más variedad y más presión.
	return [
		{
			"scene": ENEMY_NORMAL,
			"weight": 55
		},
		{
			"scene": ENEMY_FAST,
			"weight": 30
		},
		{
			"scene": ENEMY_TANK,
			"weight": 15
		}
	]

static func pick_enemy_scene(run_progress: float) -> PackedScene:
	# Elige un enemigo de forma ponderada.
	# Ejemplo:
	# peso normal 75, rápido 20, tanque 5
	# significa 75%, 20%, 5% aproximadamente.
	var pool: Array = get_enemy_pool(run_progress)
	var total_weight: int = 0
	
	for entry in pool:
		total_weight += int(entry["weight"])
	
	var roll: int = randi_range(1, total_weight)
	var current: int = 0
	
	for entry in pool:
		current += int(entry["weight"])
		
		if roll <= current:
			return entry["scene"]
	
	# Fallback por seguridad.
	return ENEMY_NORMAL
