extends RefCounted

# Servicio responsable de asignar escenas reales a las salas del mapa.
#
# No genera el mapa.
# No carga salas.
# No mueve al jugador.
# Solo transforma:
#
# room_data["type"] -> room_data["scene"]

var start_room_scene: PackedScene = null
var combat_room_scene: PackedScene = null
var boss_room_scene: PackedScene = null


func setup(
	new_start_room_scene: PackedScene,
	new_combat_room_scene: PackedScene,
	new_boss_room_scene: PackedScene
) -> void:
	start_room_scene = new_start_room_scene
	combat_room_scene = new_combat_room_scene
	boss_room_scene = new_boss_room_scene


func assign_scenes_to_map(map_data: Dictionary) -> Dictionary:
	var rooms: Dictionary = map_data.get("rooms", {})

	for room_id: String in rooms.keys():
		var room_data: Dictionary = rooms[room_id]
		var scene: PackedScene = get_room_scene_for_room_data(room_data)

		room_data["scene"] = scene
		rooms[room_id] = room_data

	map_data["rooms"] = rooms

	return map_data


func get_room_scene_for_room_data(room_data: Dictionary) -> PackedScene:
	var room_type: String = str(room_data.get("type", ""))

	match room_type:
		"start":
			return start_room_scene

		"combat":
			return combat_room_scene

		"boss":
			return boss_room_scene

		_:
			push_warning("DungeonRoomSceneResolver: tipo de sala desconocido: %s" % room_type)
			return null


func debug_print_room_scene_mapping(map_data: Dictionary) -> void:
	var rooms: Dictionary = map_data.get("rooms", {})

	print("")
	print("========== ROOM SCENE MAPPING DEBUG ==========")

	for room_id: String in rooms.keys():
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
