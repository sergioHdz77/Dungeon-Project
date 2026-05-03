extends Node

const DungeonMapGenerator = preload("res://scripts/dungeon/dungeon_map_generator.gd")

# Gestiona el mapa procedural de la mazmorra.
#
# Fase actual:
# - genera un mapa procedural como grafo de salas
# - carga salas por room_id
# - todavía solo avanza por la conexión "east"
#
# Siguiente fase:
# - puertas con dirección north/south/east/west
# - poder entrar en salas laterales
# - recordar salas visitadas/limpiadas al volver

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

# Estos valores siguen existiendo para mantener coherencia con la generación actual.
# Ahora el número real de salas viene de DungeonMapGenerator.
@export var base_combat_rooms: int = 2
@export var difficulty_steps_per_extra_room: int = 2
@export var max_combat_rooms: int = 6

var current_room: Node2D = null
var current_room_id: String = ""

var current_difficulty: int = 1
var generated_map_data: Dictionary = {}
var is_changing_room: bool = false

# -------------------------------------------------------------------
# CREACIÓN DE MAZMORRA
# -------------------------------------------------------------------

func create_test_dungeon(difficulty: int = 1) -> void:
	# Mantengo este método por compatibilidad con Main.gd.
	create_dungeon(difficulty)


func create_dungeon(difficulty: int = 1) -> void:
	clear_rooms()
	
	is_changing_room = false
	current_difficulty = max(1, difficulty)

	# Generamos mapa procedural real como datos.
	generated_map_data = DungeonMapGenerator.generate_map(current_difficulty)
	DungeonMapGenerator.print_map(generated_map_data)

	# Asignamos una escena real a cada sala del mapa.
	# Esto evita que una sala de combate cambie de variante si se vuelve a cargar.
	assign_scenes_to_generated_map()

	debug_print_room_scene_mapping(generated_map_data)

	current_room_id = str(generated_map_data.get("start_room_id", ""))

	if current_room_id.is_empty():
		push_warning("DungeonManager: el mapa generado no tiene start_room_id.")
		return

	load_room_by_id(current_room_id)

	print(
		"Mazmorra procedural cargada. Dificultad: ",
		current_difficulty,
		" | Start room: ",
		current_room_id
	)


func assign_scenes_to_generated_map() -> void:
	var rooms: Dictionary = generated_map_data.get("rooms", {})

	for room_id in rooms.keys():
		var room_data: Dictionary = rooms[room_id]
		var scene: PackedScene = get_room_scene_for_room_data(room_data)

		room_data["scene"] = scene
		rooms[room_id] = room_data

	generated_map_data["rooms"] = rooms


func get_room_scene_for_room_data(room_data: Dictionary) -> PackedScene:
	var room_type: String = str(room_data.get("type", ""))

	match room_type:
		"start":
			return start_room_scene

		"combat":
			return pick_combat_room_scene()

		"boss":
			return boss_room_scene

		_:
			push_warning("DungeonManager: tipo de sala desconocido: %s" % room_type)
			return null


func pick_combat_room_scene() -> PackedScene:
	if not combat_room_scenes.is_empty():
		var random_index: int = randi_range(0, combat_room_scenes.size() - 1)
		return combat_room_scenes[random_index]

	return combat_room_scene


func debug_print_room_scene_mapping(map_data: Dictionary) -> void:
	var rooms: Dictionary = map_data.get("rooms", {})

	print("")
	print("========== ROOM SCENE MAPPING DEBUG ==========")

	for room_id in rooms.keys():
		var room_data: Dictionary = rooms[room_id]
		var room_type: String = str(room_data.get("type", "unknown"))
		var scene: PackedScene = room_data.get("scene", null) as PackedScene

		var scene_path: String = "NULL"

		if scene != null:
			if not scene.resource_path.is_empty():
				scene_path = scene.resource_path
			else:
				scene_path = "PackedScene sin resource_path"

		print(
			room_id,
			" | type: ",
			room_type,
			" | scene: ",
			scene_path
		)

	print("==============================================")
	print("")


# -------------------------------------------------------------------
# CARGA DE SALAS POR ROOM_ID
# -------------------------------------------------------------------

func load_room_by_id(room_id: String, entered_from_direction: String = "") -> void:
	clear_rooms()

	var room_data: Dictionary = get_room_data(room_id)

	if room_data.is_empty():
		push_warning("DungeonManager: no existe room_id: %s" % room_id)
		call_deferred("_finish_room_transition")
		return

	var room_scene: PackedScene = get_scene_for_room_data(room_data)

	if room_scene == null:
		push_warning("DungeonManager: la sala no tiene escena asignada: %s" % room_id)
		call_deferred("_finish_room_transition")
		return

	current_room = room_scene.instantiate() as Node2D

	if current_room == null:
		push_warning("DungeonManager: la escena de sala no instancia Node2D.")
		call_deferred("_finish_room_transition")
		return

	if room_container == null:
		push_warning("DungeonManager: falta asignar room_container.")
		call_deferred("_finish_room_transition")
		return

	room_container.add_child(current_room)
	current_room.global_position = Vector2.ZERO

	current_room_id = room_id

	mark_room_as_visited(room_id)
	connect_current_room_signals()

	configure_current_room_exits(room_data)

	move_player_to_room_spawn(current_room, entered_from_direction)
	setup_current_room(room_data)

	print_loaded_room_debug(room_id, room_data)

	# Liberamos el bloqueo en diferido para evitar dobles cambios
	# producidos por puertas, áreas o nodos antiguos todavía activos ese frame.
	call_deferred("_finish_room_transition")


func get_room_data(room_id: String) -> Dictionary:
	var rooms: Dictionary = generated_map_data.get("rooms", {})

	if not rooms.has(room_id):
		return {}

	return rooms[room_id]


func get_scene_for_room_data(room_data: Dictionary) -> PackedScene:
	var scene: PackedScene = room_data.get("scene", null) as PackedScene

	if scene != null:
		return scene

	# Fallback por seguridad si alguna sala no tiene scene precalculada.
	return get_room_scene_for_room_data(room_data)


func setup_current_room(room_data: Dictionary) -> void:
	if current_room == null:
		return

	var already_cleared: bool = bool(room_data.get("is_cleared", false))

	if current_room.has_method("setup_room"):
		current_room.setup_room(
			player,
			current_difficulty,
			already_cleared
		)


func move_player_to_room_spawn(room: Node2D, entered_from_direction: String = "") -> void:
	if player == null:
		push_warning("DungeonManager: falta asignar player.")
		return

	# Spawns opcionales para mapa procedural real.
	# Si entras a la sala desde west, busca PlayerSpawnWest.
	# Si no existe, usa PlayerSpawn normal.
	if not entered_from_direction.is_empty():
		var directional_spawn_name: String = "PlayerSpawn%s" % entered_from_direction.capitalize()
		var directional_spawn := room.get_node_or_null(directional_spawn_name) as Marker2D

		if directional_spawn != null:
			player.global_position = directional_spawn.global_position
			return

	# Fallback actual.
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


func print_loaded_room_debug(room_id: String, room_data: Dictionary) -> void:
	var room_type: String = str(room_data.get("type", "unknown"))
	var grid_position: Vector2i = room_data.get("grid_position", Vector2i.ZERO)
	var connections: Dictionary = room_data.get("connections", {})

	print(
		"Sala cargada por room_id: ",
		room_id,
		" | type: ",
		room_type,
		" | pos: ",
		grid_position,
		" | connections: ",
		connections,
		" | dificultad: ",
		current_difficulty
	)


# -------------------------------------------------------------------
# ESTADO DE SALAS
# -------------------------------------------------------------------

func mark_room_as_visited(room_id: String) -> void:
	var rooms: Dictionary = generated_map_data.get("rooms", {})

	if not rooms.has(room_id):
		return

	var room_data: Dictionary = rooms[room_id]
	room_data["is_visited"] = true
	rooms[room_id] = room_data
	generated_map_data["rooms"] = rooms


func mark_current_room_as_cleared() -> void:
	if current_room_id.is_empty():
		return

	var rooms: Dictionary = generated_map_data.get("rooms", {})

	if not rooms.has(current_room_id):
		return

	var room_data: Dictionary = rooms[current_room_id]
	room_data["is_cleared"] = true
	rooms[current_room_id] = room_data
	generated_map_data["rooms"] = rooms

func configure_current_room_exits(room_data: Dictionary) -> void:
	if current_room == null:
		return

	var connections: Dictionary = room_data.get("connections", {})
	var room_type: String = str(room_data.get("type", ""))

	if current_room.has_method("configure_exit_doors_for_connections"):
		current_room.configure_exit_doors_for_connections(connections, room_type)

# -------------------------------------------------------------------
# CAMBIO DE SALA
# -------------------------------------------------------------------

func go_to_next_room() -> void:
	# Fallback antiguo.
	# Mientras algunas puertas no tengan dirección, asumimos que avanzar significa ir al este.

	go_to_connected_room("east")

func go_to_connected_room(direction: String) -> void:
	if is_changing_room:
		print("DungeonManager: cambio de sala ignorado porque ya hay una transición activa.")
		return

	is_changing_room = true

	if current_room_id.is_empty():
		push_warning("DungeonManager: current_room_id está vacío.")
		is_changing_room = false
		return

	var next_room_id: String = get_connected_room_id(current_room_id, direction)

	if next_room_id.is_empty():
		if direction == "east":
			is_changing_room = false
			complete_dungeon()
		else:
			push_warning(
				"DungeonManager: no hay conexión desde %s hacia %s" % [
					current_room_id,
					direction
				]
			)

			is_changing_room = false

		return

	var entered_from_direction: String = get_opposite_direction(direction)

	load_room_by_id(next_room_id, entered_from_direction)
	
func get_opposite_direction(direction: String) -> String:
	match direction:
		"north":
			return "south"

		"south":
			return "north"

		"east":
			return "west"

		"west":
			return "east"

		_:
			return ""
	
func get_connected_room_id(room_id: String, direction: String) -> String:
	var room_data: Dictionary = get_room_data(room_id)

	if room_data.is_empty():
		return ""

	var connections: Dictionary = room_data.get("connections", {})

	if not connections.has(direction):
		return ""

	return str(connections[direction])


func complete_dungeon() -> void:
	print("Mazmorra completada.")
	dungeon_completed.emit()

func _finish_room_transition() -> void:
	is_changing_room = false
	
# -------------------------------------------------------------------
# SEÑALES DE SALA
# -------------------------------------------------------------------

func connect_current_room_signals() -> void:
	if current_room == null:
		return

	if current_room.has_signal("room_cleared"):
		current_room.room_cleared.connect(_on_current_room_cleared)

	# Preferimos la señal nueva con dirección.
	# Si la sala tiene directional_exit_requested, NO conectamos exit_requested
	# para evitar doble cambio de sala.
	if current_room.has_signal("directional_exit_requested"):
		current_room.directional_exit_requested.connect(_on_current_room_directional_exit_requested)
	elif current_room.has_signal("exit_requested"):
		# Fallback para salas antiguas.
		current_room.exit_requested.connect(_on_current_room_exit_requested)

	if current_room.has_signal("item_collected"):
		current_room.item_collected.connect(_on_room_item_collected)


func _on_current_room_cleared() -> void:
	print("DungeonManager ha recibido room_cleared de la sala actual: ", current_room_id)
	mark_current_room_as_cleared()


func _on_current_room_exit_requested() -> void:
	# Fallback antiguo para salas que todavía no tengan salida direccional.
	go_to_next_room()

func _on_current_room_directional_exit_requested(direction: String) -> void:
	print(
		"DungeonManager recibe salida direccional: ",
		direction,
		" desde sala: ",
		current_room_id
	)

	go_to_connected_room(direction)

func _on_room_item_collected(item_id: String, display_name: String) -> void:
	print("DungeonManager recibe loot: ", display_name)
	item_collected.emit(item_id, display_name)
