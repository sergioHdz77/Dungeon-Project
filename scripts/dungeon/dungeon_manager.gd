extends Node

# Gestiona la secuencia de salas de la mazmorra.
#
# Generación procedural v1:
# - siempre empieza con StartRoom
# - genera un número variable de salas de combate según dificultad
# - siempre termina con BossRoom
#
# Más adelante podremos ampliar esto con:
# - salas de loot
# - salas élite
# - ramificaciones
# - mapa físico procedural

signal dungeon_completed
signal item_collected(item_id: String, display_name: String)

@export var room_container: Node2D
@export var player: Node2D

@export var start_room_scene: PackedScene
@export var combat_room_scene: PackedScene
@export var boss_room_scene: PackedScene

# Variantes opcionales de salas de combate.
# Si está vacío, usa combat_room_scene como fallback.
@export var combat_room_scenes: Array[PackedScene] = []

# Número base de salas de combate.
@export var base_combat_rooms: int = 2

# Cada cuántas dificultades añadimos una sala extra.
# Ejemplo: difficulty 1-2 = 2 salas, difficulty 3-4 = 3 salas.
@export var difficulty_steps_per_extra_room: int = 2

# Límite máximo para que la mazmorra no crezca demasiado.
@export var max_combat_rooms: int = 6

var current_room: Node2D = null
var current_room_index: int = 0
var room_sequence: Array[PackedScene] = []

var current_difficulty: int = 1


# -------------------------------------------------------------------
# CREACIÓN DE MAZMORRA
# -------------------------------------------------------------------

func create_test_dungeon(difficulty: int = 1) -> void:
	# Mantengo este método por compatibilidad con Main.gd.
	# Internamente ya llama al generador procedural.
	create_dungeon(difficulty)


func create_dungeon(difficulty: int = 1) -> void:
	clear_rooms()

	current_difficulty = max(1, difficulty)

	room_sequence = generate_room_sequence(current_difficulty)

	current_room_index = 0
	load_current_room()

	print("Mazmorra generada. Dificultad: ", current_difficulty, " | Salas: ", room_sequence.size())


func generate_room_sequence(difficulty: int) -> Array[PackedScene]:
	var sequence: Array[PackedScene] = []

	if start_room_scene != null:
		sequence.append(start_room_scene)
	else:
		push_warning("DungeonManager: falta start_room_scene.")

	var combat_room_count: int = get_combat_room_count_for_difficulty(difficulty)

	for i in range(combat_room_count):
		var combat_scene: PackedScene = pick_combat_room_scene()

		if combat_scene != null:
			sequence.append(combat_scene)
		else:
			push_warning("DungeonManager: no hay escena de combate disponible.")

	if boss_room_scene != null:
		sequence.append(boss_room_scene)
	else:
		push_warning("DungeonManager: falta boss_room_scene.")

	return sequence


func get_combat_room_count_for_difficulty(difficulty: int) -> int:
	# Dificultad 1-2: base_combat_rooms
	# Dificultad 3-4: base + 1
	# Dificultad 5-6: base + 2
	# etc.

	var safe_step: int = max(1, difficulty_steps_per_extra_room)
	var extra_rooms: int = int(floor(float(max(0, difficulty - 1)) / float(safe_step)))

	var total_rooms: int = base_combat_rooms + extra_rooms

	return clamp(
		total_rooms,
		1,
		max_combat_rooms
	)


func pick_combat_room_scene() -> PackedScene:
	# Si hay variantes, elegimos una aleatoria.
	if not combat_room_scenes.is_empty():
		var random_index: int = randi_range(0, combat_room_scenes.size() - 1)
		return combat_room_scenes[random_index]

	# Fallback: usa la sala de combate única actual.
	return combat_room_scene


func load_current_room() -> void:
	clear_rooms()

	if not is_current_room_index_valid():
		push_warning("DungeonManager: índice de sala fuera de rango.")
		return

	var room_scene: PackedScene = room_sequence[current_room_index]

	if room_scene == null:
		push_warning("DungeonManager: falta asignar una escena de sala.")
		return

	current_room = room_scene.instantiate() as Node2D

	if current_room == null:
		push_warning("DungeonManager: la escena de sala no es Node2D.")
		return

	if room_container == null:
		push_warning("DungeonManager: falta asignar room_container.")
		return

	room_container.add_child(current_room)

	# De momento todas las salas se colocan en el centro.
	current_room.global_position = Vector2.ZERO

	connect_current_room_signals()
	move_player_to_room_spawn(current_room)
	setup_current_room()

	print(
		"Sala cargada: ",
		current_room.name,
		" | Índice: ",
		current_room_index + 1,
		"/",
		room_sequence.size(),
		" | Dificultad: ",
		current_difficulty
	)


func is_current_room_index_valid() -> bool:
	return current_room_index >= 0 and current_room_index < room_sequence.size()


func setup_current_room() -> void:
	if current_room == null:
		return

	if current_room.has_method("setup_room"):
		current_room.setup_room(player, get_current_difficulty())


func get_current_difficulty() -> int:
	return current_difficulty


# -------------------------------------------------------------------
# CAMBIO DE SALA
# -------------------------------------------------------------------

func go_to_next_room() -> void:
	if room_sequence.is_empty():
		return

	current_room_index += 1

	if current_room_index >= room_sequence.size():
		complete_dungeon()
		return

	load_current_room()


func complete_dungeon() -> void:
	print("Mazmorra completada.")
	dungeon_completed.emit()


func move_player_to_room_spawn(room: Node2D) -> void:
	if player == null:
		push_warning("DungeonManager: falta asignar player.")
		return

	var spawn := room.get_node_or_null("PlayerSpawn") as Marker2D

	if spawn == null:
		player.global_position = room.global_position
		return

	player.global_position = spawn.global_position


func clear_rooms() -> void:
	if room_container == null:
		push_warning("DungeonManager: falta asignar room_container.")
		return

	for child in room_container.get_children():
		child.queue_free()

	current_room = null


# -------------------------------------------------------------------
# SEÑALES DE SALA
# -------------------------------------------------------------------

func connect_current_room_signals() -> void:
	if current_room == null:
		return

	if current_room.has_signal("room_cleared"):
		current_room.room_cleared.connect(_on_current_room_cleared)

	if current_room.has_signal("exit_requested"):
		current_room.exit_requested.connect(_on_current_room_exit_requested)

	if current_room.has_signal("item_collected"):
		current_room.item_collected.connect(_on_room_item_collected)


func _on_current_room_cleared() -> void:
	print("DungeonManager ha recibido room_cleared de la sala actual.")


func _on_current_room_exit_requested() -> void:
	go_to_next_room()


func _on_room_item_collected(item_id: String, display_name: String) -> void:
	print("DungeonManager recibe loot: ", display_name)
	item_collected.emit(item_id, display_name)
