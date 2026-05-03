extends RefCounted

# Generador procedural de mapa de mazmorra.
#
# Fase 1:
# - genera datos de salas en una grid
# - crea una ruta principal desde Start hasta Boss
# - añade algunas salas laterales opcionales
# - imprime el resultado para debug
#
# Todavía NO carga escenas.
# Todavía NO controla puertas.
# Todavía NO mueve al jugador.
#
# El formato generado será:
#
# {
#   "start_room_id": "room_0",
#   "boss_room_id": "room_4",
#   "rooms": {
#      "room_0": {
#         "id": "room_0",
#         "type": "start",
#         "grid_position": Vector2i(0, 0),
#         "connections": {
#            "east": "room_1"
#         },
#         "is_visited": false,
#         "is_cleared": false
#      }
#   }
# }

const DIRECTIONS: Dictionary = {
	"north": Vector2i(0, -1),
	"south": Vector2i(0, 1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0)
}

const OPPOSITE_DIRECTIONS: Dictionary = {
	"north": "south",
	"south": "north",
	"east": "west",
	"west": "east"
}


static func generate_map(difficulty: int) -> Dictionary:
	# Genera un mapa procedural básico.
	#
	# La dificultad aumenta:
	# - longitud de ruta principal
	# - posibles salas laterales

	var safe_difficulty: int = max(1, difficulty)

	var map_data: Dictionary = {
		"start_room_id": "",
		"boss_room_id": "",
		"rooms": {}
	}

	var occupied_positions: Dictionary = {}
	var next_room_index: int = 0

	# Ruta principal.
	var main_path_length: int = get_main_path_length(safe_difficulty)

	var previous_room_id: String = ""
	var current_position: Vector2i = Vector2i(0, 0)

	for i in range(main_path_length):
		var room_type: String = "combat"

		if i == 0:
			room_type = "start"
		elif i == main_path_length - 1:
			room_type = "boss"

		var room_id: String = "room_%s" % next_room_index
		next_room_index += 1

		var room_data: Dictionary = create_room_data(
			room_id,
			room_type,
			current_position
		)

		map_data["rooms"][room_id] = room_data
		occupied_positions[position_to_key(current_position)] = room_id

		if room_type == "start":
			map_data["start_room_id"] = room_id

		if room_type == "boss":
			map_data["boss_room_id"] = room_id

		if not previous_room_id.is_empty():
			connect_rooms(
				map_data,
				previous_room_id,
				room_id,
				"east"
			)

		previous_room_id = room_id
		current_position += DIRECTIONS["east"]

	# Salas laterales opcionales.
	next_room_index = add_side_rooms(
		map_data,
		occupied_positions,
		next_room_index,
		safe_difficulty
	)

	return map_data


static func get_main_path_length(difficulty: int) -> int:
	# Cantidad total de salas de la ruta principal, incluyendo Start y Boss.
	#
	# Dificultad 1: Start + 2 combates + Boss = 4 salas
	# Dificultad 3: Start + 3 combates + Boss = 5 salas
	# Dificultad 5: Start + 4 combates + Boss = 6 salas

	var base_combat_rooms: int = 2
	var extra_combat_rooms: int = int(floor(float(max(0, difficulty - 1)) / 2.0))
	var combat_rooms: int = clamp(base_combat_rooms + extra_combat_rooms, 2, 6)

	return combat_rooms + 2


static func add_side_rooms(
	map_data: Dictionary,
	occupied_positions: Dictionary,
	next_room_index: int,
	difficulty: int
) -> int:
	# Añade salas laterales desde habitaciones de combate de la ruta principal.
	#
	# De momento todas serán "combat".
	# Más adelante aquí meteremos:
	# - loot
	# - elite
	# - shop
	# - event

	var rooms: Dictionary = map_data["rooms"]

	var side_room_chance: float = get_side_room_chance(difficulty)
	var max_side_rooms: int = get_max_side_rooms(difficulty)
	var side_rooms_created: int = 0

	for room_id in rooms.keys():
		if side_rooms_created >= max_side_rooms:
			break

		var room_data: Dictionary = rooms[room_id]
		var room_type: String = str(room_data.get("type", ""))

		# No generamos ramas desde start ni boss en esta primera versión.
		if room_type != "combat":
			continue

		if randf() > side_room_chance:
			continue

		var base_position: Vector2i = room_data["grid_position"]

		# Intentamos norte o sur.
		var possible_directions: Array[String] = ["north", "south"]
		possible_directions.shuffle()

		for direction in possible_directions:
			var offset: Vector2i = DIRECTIONS[direction]
			var side_position: Vector2i = base_position + offset
			var side_key: String = position_to_key(side_position)

			if occupied_positions.has(side_key):
				continue

			var side_room_id: String = "room_%s" % next_room_index
			next_room_index += 1

			var side_room_data: Dictionary = create_room_data(
				side_room_id,
				"combat",
				side_position
			)

			map_data["rooms"][side_room_id] = side_room_data
			occupied_positions[side_key] = side_room_id

			connect_rooms(
				map_data,
				room_id,
				side_room_id,
				direction
			)

			side_rooms_created += 1
			break

	return next_room_index


static func get_side_room_chance(difficulty: int) -> float:
	# Más dificultad = más posibilidad de salas laterales.
	if difficulty <= 1:
		return 0.25

	if difficulty == 2:
		return 0.35

	if difficulty == 3:
		return 0.45

	return 0.55


static func get_max_side_rooms(difficulty: int) -> int:
	# Límite para no crear demasiadas ramas todavía.
	if difficulty <= 1:
		return 1

	if difficulty <= 3:
		return 2

	return 3


static func create_room_data(
	room_id: String,
	room_type: String,
	grid_position: Vector2i
) -> Dictionary:
	return {
		"id": room_id,
		"type": room_type,
		"grid_position": grid_position,
		"connections": {},
		"is_visited": false,
		"is_cleared": false
	}


static func connect_rooms(
	map_data: Dictionary,
	from_room_id: String,
	to_room_id: String,
	direction: String
) -> void:
	var rooms: Dictionary = map_data["rooms"]

	if not rooms.has(from_room_id):
		return

	if not rooms.has(to_room_id):
		return

	var opposite_direction: String = str(OPPOSITE_DIRECTIONS.get(direction, ""))

	if opposite_direction.is_empty():
		return

	rooms[from_room_id]["connections"][direction] = to_room_id
	rooms[to_room_id]["connections"][opposite_direction] = from_room_id


static func position_to_key(position: Vector2i) -> String:
	return "%s,%s" % [
		position.x,
		position.y
	]


static func print_map(map_data: Dictionary) -> void:
	# Imprime el mapa generado en consola de forma legible.

	print("")
	print("========== DUNGEON MAP DEBUG ==========")

	var start_room_id: String = str(map_data.get("start_room_id", ""))
	var boss_room_id: String = str(map_data.get("boss_room_id", ""))
	var rooms: Dictionary = map_data.get("rooms", {})

	print("Start Room: ", start_room_id)
	print("Boss Room: ", boss_room_id)
	print("Total rooms: ", rooms.size())
	print("---------------------------------------")

	for room_id in rooms.keys():
		var room_data: Dictionary = rooms[room_id]

		var room_type: String = str(room_data.get("type", "unknown"))
		var grid_position: Vector2i = room_data.get("grid_position", Vector2i.ZERO)
		var connections: Dictionary = room_data.get("connections", {})

		print(
			room_id,
			" | type: ",
			room_type,
			" | pos: ",
			grid_position,
			" | connections: ",
			connections
		)

	print("=======================================")
	print("")
