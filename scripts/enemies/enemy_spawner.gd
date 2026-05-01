extends Node2D

# Base de datos que decide qué tipo de enemigo toca según el progreso de la run.
const EnemyDatabase = preload("res://scripts/data/enemy_database.gd")

# Tiempo entre oleadas al principio de la run.
@export var initial_spawn_interval: float = 1.5

# Tiempo mínimo entre oleadas al final de la run.
# Cuanto menor sea, más presión habrá.
@export var minimum_spawn_interval: float = 0.35

# Distancia aproximada a la que aparecen los enemigos respecto al jugador.
@export var spawn_distance: float = 520.0

# Distancia mínima para que no aparezcan encima del jugador.
@export var minimum_distance_from_player: float = 280.0

# Límite máximo de enemigos vivos.
# Evita saturar el juego si el jugador no mata suficiente.
@export var max_alive_enemies: int = 80

# Duración usada para calcular el escalado.
# Debe coincidir con la duración de la run de prueba.
@export var run_duration_for_scaling: float = 60.0

# Mitad del tamaño del mapa.
# Si el mapa mide 2400x1600, la mitad es 1200x800.
@export var map_half_size: Vector2 = Vector2(1200, 800)

# Margen para que los enemigos no aparezcan justo pegados al borde.
@export var spawn_margin: float = 40.0

# Referencia al jugador.
var player: Node2D

# Temporizador interno para saber cuándo generar la siguiente oleada.
var spawn_timer: float = 0.0

# Tiempo transcurrido para escalar dificultad.
var elapsed_time: float = 0.0

func _ready() -> void:
	# Buscamos al jugador en la escena principal.
	# Esto asume que el nodo se llama exactamente "Player".
	player = get_tree().current_scene.get_node("Player")

func _process(delta: float) -> void:
	# Si no hay jugador, no podemos spawnear enemigos.
	if player == null:
		return
	
	# Avanzamos el tiempo interno del spawner.
	elapsed_time += delta
	
	# Reducimos el temporizador de spawn.
	spawn_timer -= delta
	
	# Cuando el temporizador llega a 0, generamos una oleada.
	if spawn_timer <= 0.0:
		spawn_wave()
		spawn_timer = get_current_spawn_interval()

func spawn_wave() -> void:
	# Contamos cuántos enemigos vivos hay ahora mismo.
	var alive_enemies: int = get_tree().get_nodes_in_group("enemies").size()
	
	# Si ya hay demasiados, no generamos más.
	if alive_enemies >= max_alive_enemies:
		return
	
	# Calculamos cuántos enemigos toca generar en esta oleada.
	var spawn_count: int = get_current_spawn_count()
	
	for i in range(spawn_count):
		# Volvemos a comprobar el límite por si estamos generando varios.
		if get_tree().get_nodes_in_group("enemies").size() >= max_alive_enemies:
			return
		
		spawn_enemy()

func spawn_enemy() -> void:
	# Calculamos el progreso de la run entre 0.0 y 1.0.
	var progress: float = get_run_progress()
	
	# Pedimos a EnemyDatabase qué enemigo toca instanciar.
	var enemy_scene: PackedScene = EnemyDatabase.pick_enemy_scene(progress)
	var enemy = enemy_scene.instantiate()
	
	# Calculamos una posición válida dentro del mapa.
	enemy.global_position = get_valid_spawn_position()
	
	# Escalado de dificultad.
	# Al principio los multiplicadores valen 1.0.
	# Al final de la run llegan a los valores máximos indicados.
	var health_multiplier: float = lerp(1.0, 2.6, progress)
	var speed_multiplier: float = lerp(1.0, 1.35, progress)
	var damage_multiplier: float = lerp(1.0, 1.6, progress)
	var reward_multiplier: float = lerp(1.0, 1.8, progress)
	
	# Configuramos el enemigo antes de añadirlo a la escena.
	# Le pasamos el jugador como objetivo y los multiplicadores de dificultad.
	enemy.setup(
		player,
		health_multiplier,
		speed_multiplier,
		damage_multiplier,
		reward_multiplier
	)
	
	# Añadimos el enemigo a la escena actual.
	get_tree().current_scene.add_child(enemy)

func get_valid_spawn_position() -> Vector2:
	# Intentamos encontrar una posición válida varias veces.
	# Esto evita que el enemigo aparezca demasiado cerca del jugador.
	for i in range(12):
		var angle: float = randf() * TAU
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * spawn_distance
		var candidate_position: Vector2 = player.global_position + offset
		
		# Forzamos que la posición esté dentro del mapa.
		candidate_position = clamp_position_to_map(candidate_position)
		
		# Si está suficientemente lejos del jugador, la usamos.
		if candidate_position.distance_to(player.global_position) >= minimum_distance_from_player:
			return candidate_position
	
	# Si no encontramos una posición ideal, usamos una alternativa.
	# Sigue estando dentro del mapa, aunque quizá no respete perfectamente la distancia mínima.
	var fallback_angle: float = randf() * TAU
	var fallback_offset: Vector2 = Vector2(cos(fallback_angle), sin(fallback_angle)) * spawn_distance
	return clamp_position_to_map(player.global_position + fallback_offset)

func clamp_position_to_map(position: Vector2) -> Vector2:
	# Limita la posición para que no salga del rectángulo del mapa.
	position.x = clamp(
		position.x,
		-map_half_size.x + spawn_margin,
		map_half_size.x - spawn_margin
	)
	
	position.y = clamp(
		position.y,
		-map_half_size.y + spawn_margin,
		map_half_size.y - spawn_margin
	)
	
	return position

func get_run_progress() -> float:
	# Devuelve un valor entre 0.0 y 1.0.
	# 0.0 = inicio de run.
	# 1.0 = final de run.
	return clamp(elapsed_time / run_duration_for_scaling, 0.0, 1.0)

func get_current_spawn_interval() -> float:
	# Reduce progresivamente el tiempo entre oleadas.
	var progress: float = get_run_progress()
	return lerp(initial_spawn_interval, minimum_spawn_interval, progress)

func get_current_spawn_count() -> int:
	# Aumenta la cantidad de enemigos por oleada según avanza la run.
	var progress: float = get_run_progress()
	
	if progress >= 0.8:
		return 4
	
	if progress >= 0.55:
		return 3
	
	if progress >= 0.3:
		return 2
	
	return 1
