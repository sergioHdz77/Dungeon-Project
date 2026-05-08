extends Node

# Genera visuales, puertas, bounds y spawns de una sala rectangular.
#
# La sala sigue centrada en (0, 0), igual que DungeonRoom.
# De esta forma:
# - room_size 640x384 -> bordes en x +/-320, y +/-192
# - los TileMapLayer se pintan de -20..19 y -12..11 con tiles de 16 px
#
# Este script NO decide si la sala está limpia.
# Este script NO spawnea enemigos directamente.
# Solo crea los nodos que DungeonRoom y EnemySpawner ya esperan.

const RoomBoundsScript := preload("res://scripts/dungeon/rooms/room_bounds.gd")
const RoomExitScript := preload("res://scripts/dungeon/rooms/room_exit.gd")
const EnemySpawnerScript := preload("res://scripts/dungeon/rooms/enemy_spawner.gd")

@export var tile_set: TileSet

@export var room_size: Vector2 = Vector2(640, 384)
@export var tile_size: int = 16
@export var wall_thickness: float = 16.0

# Ajusta estos atlas coords según tu tilesheet real.
# Por defecto:
# - floor_atlas_coords: primer tile del atlas
# - wall_atlas_coords: segundo tile de la primera fila
@export var floor_source_id: int = 0
@export var floor_atlas_coords: Vector2i = Vector2i(0, 0)

@export var wall_source_id: int = 0
@export var wall_atlas_coords: Vector2i = Vector2i(1, 0)

@export var door_size: Vector2 = Vector2(80, 36)

@export var default_player_spawn: Vector2 = Vector2(0, 120)

@export var enemy_spawn_positions: Array[Vector2] = [
	Vector2(-160, 0),
	Vector2(160, 0),
	Vector2(0, -96)
]


func generate(room_data: Dictionary = {}, difficulty: int = 1) -> void:
	var room := get_parent() as Node2D
	if room == null:
		push_warning("ProceduralRoomBuilder: el padre no es Node2D.")
		return

	# Sin esto, DungeonRoom seguiría pintando su fondo placeholder.
	room.set("room_size", room_size)
	room.set("draw_placeholder_background", false)

	_create_tile_layers(room)
	_create_room_bounds(room)
	_create_player_spawns(room)
	_create_doors(room)
	_create_enemy_system(room)


func _create_tile_layers(room: Node2D) -> void:
	if tile_set == null:
		push_warning("ProceduralRoomBuilder: falta asignar tile_set.")
		return

	var ground_layer := _get_or_create_tile_layer(room, "GroundLayer", 1)
	var wall_layer := _get_or_create_tile_layer(room, "WallLayer", 2)

	ground_layer.tile_set = tile_set
	wall_layer.tile_set = tile_set

	ground_layer.clear()
	wall_layer.clear()

	var tiles_wide: int = int(room_size.x / float(tile_size))
	var tiles_high: int = int(room_size.y / float(tile_size))

	var start_x: int = -tiles_wide / 2
	var end_x: int = start_x + tiles_wide - 1

	var start_y: int = -tiles_high / 2
	var end_y: int = start_y + tiles_high - 1

	for y in range(start_y, end_y + 1):
		for x in range(start_x, end_x + 1):
			ground_layer.set_cell(
				Vector2i(x, y),
				floor_source_id,
				floor_atlas_coords,
				0
			)

	for x in range(start_x, end_x + 1):
		wall_layer.set_cell(
			Vector2i(x, start_y),
			wall_source_id,
			wall_atlas_coords,
			0
		)

		wall_layer.set_cell(
			Vector2i(x, end_y),
			wall_source_id,
			wall_atlas_coords,
			0
		)

	for y in range(start_y, end_y + 1):
		wall_layer.set_cell(
			Vector2i(start_x, y),
			wall_source_id,
			wall_atlas_coords,
			0
		)

		wall_layer.set_cell(
			Vector2i(end_x, y),
			wall_source_id,
			wall_atlas_coords,
			0
		)


func _get_or_create_tile_layer(room: Node2D, layer_name: String, layer_z_index: int) -> TileMapLayer:
	var existing_layer := room.get_node_or_null(layer_name) as TileMapLayer

	if existing_layer != null:
		existing_layer.position = Vector2.ZERO
		existing_layer.scale = Vector2.ONE
		existing_layer.z_index = layer_z_index
		return existing_layer

	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.position = Vector2.ZERO
	layer.scale = Vector2.ONE
	layer.z_index = layer_z_index

	room.add_child(layer)

	return layer


func _create_room_bounds(room: Node2D) -> void:
	var room_bounds := room.get_node_or_null("RoomBounds") as StaticBody2D

	if room_bounds == null:
		room_bounds = StaticBody2D.new()
		room_bounds.name = "RoomBounds"
		room.add_child(room_bounds)

	room_bounds.position = Vector2.ZERO
	room_bounds.scale = Vector2.ONE
	room_bounds.set_script(RoomBoundsScript)
	room_bounds.set("room_size", room_size)
	room_bounds.set("wall_thickness", wall_thickness)


func _create_player_spawns(room: Node2D) -> void:
	_get_or_create_marker(room, "PlayerSpawn", default_player_spawn)

	# Spawns direccionales.
	# Si entras desde una puerta oeste, DungeonManager busca PlayerSpawnWest, etc.
	_get_or_create_marker(room, "PlayerSpawnWest", Vector2(-260, 0))
	_get_or_create_marker(room, "PlayerSpawnEast", Vector2(260, 0))
	_get_or_create_marker(room, "PlayerSpawnNorth", Vector2(0, -140))
	_get_or_create_marker(room, "PlayerSpawnSouth", Vector2(0, 140))


func _get_or_create_marker(parent: Node, marker_name: String, marker_position: Vector2) -> Marker2D:
	var marker := parent.get_node_or_null(marker_name) as Marker2D

	if marker == null:
		marker = Marker2D.new()
		marker.name = marker_name
		parent.add_child(marker)

	marker.position = marker_position
	marker.scale = Vector2.ONE

	return marker


func _create_doors(room: Node2D) -> void:
	var doors := room.get_node_or_null("Doors") as Node2D

	if doors == null:
		doors = Node2D.new()
		doors.name = "Doors"
		room.add_child(doors)

	doors.position = Vector2.ZERO
	doors.scale = Vector2.ONE
	doors.z_index = 30

	_create_door(
		doors,
		"NorthDoor",
		"north",
		Vector2(0, -176)
	)

	_create_door(
		doors,
		"SouthDoor",
		"south",
		Vector2(0, 176)
	)

	_create_door(
		doors,
		"EastDoor",
		"east",
		Vector2(304, 0)
	)

	_create_door(
		doors,
		"WestDoor",
		"west",
		Vector2(-304, 0)
	)


func _create_door(
	doors: Node2D,
	door_name: String,
	door_direction: String,
	door_position: Vector2
) -> void:
	var door := doors.get_node_or_null(door_name) as Area2D

	if door == null:
		door = Area2D.new()
		door.name = door_name
		door.set_script(RoomExitScript)
		doors.add_child(door)

	door.position = door_position
	door.scale = Vector2.ONE
	door.set("direction", door_direction)
	door.set("locked", true)
	door.set("door_size", door_size)

	_ensure_door_collision_shape(door)


func _ensure_door_collision_shape(door: Area2D) -> void:
	var collision_shape := door.get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		door.add_child(collision_shape)

	collision_shape.position = Vector2.ZERO
	collision_shape.scale = Vector2.ONE

	var rectangle_shape := collision_shape.shape as RectangleShape2D

	if rectangle_shape == null:
		rectangle_shape = RectangleShape2D.new()
		collision_shape.shape = rectangle_shape

	rectangle_shape.size = door_size


func _create_enemy_system(room: Node2D) -> void:
	var enemies := room.get_node_or_null("Enemies") as Node2D

	if enemies == null:
		enemies = Node2D.new()
		enemies.name = "Enemies"
		room.add_child(enemies)

	enemies.position = Vector2.ZERO
	enemies.scale = Vector2.ONE
	enemies.z_index = 10

	var spawn_container := room.get_node_or_null("EnemySpawnPoints") as Node2D

	if spawn_container == null:
		spawn_container = Node2D.new()
		spawn_container.name = "EnemySpawnPoints"
		room.add_child(spawn_container)

	spawn_container.position = Vector2.ZERO
	spawn_container.scale = Vector2.ONE

	_clear_children(spawn_container)

	for i in range(enemy_spawn_positions.size()):
		var marker := Marker2D.new()
		marker.name = "EnemySpawnPoint%d" % (i + 1)
		marker.position = enemy_spawn_positions[i]
		spawn_container.add_child(marker)

	var enemy_spawner := room.get_node_or_null("EnemySpawner") as Node

	if enemy_spawner == null:
		enemy_spawner = Node.new()
		enemy_spawner.name = "EnemySpawner"
		room.add_child(enemy_spawner)

	enemy_spawner.set_script(EnemySpawnerScript)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
