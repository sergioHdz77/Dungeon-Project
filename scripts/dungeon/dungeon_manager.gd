extends Node

# Gestiona la secuencia de salas de la mazmorra.
#
# De momento usa una secuencia fija:
# StartRoom -> CombatRoom -> CombatRoom -> BossRoom
#
# Más adelante este mismo punto será donde metamos generación procedural.

signal dungeon_completed
signal item_collected(item_id: String, display_name: String)

@export var room_container: Node2D
@export var player: Node2D

@export var start_room_scene: PackedScene
@export var combat_room_scene: PackedScene
@export var boss_room_scene: PackedScene

var current_room: Node2D = null
var current_room_index: int = 0
var room_sequence: Array[PackedScene] = []


# -------------------------------------------------------------------
# CREACIÓN DE MAZMORRA
# -------------------------------------------------------------------

func create_test_dungeon() -> void:
	# Crea la mazmorra mínima actual.
	# Aún no es procedural, pero ya representa el flujo base del MVP.

	clear_rooms()

	room_sequence = [
		start_room_scene,
		combat_room_scene,
		combat_room_scene,
		boss_room_scene
	]

	current_room_index = 0
	load_current_room()


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
	# Más adelante, si hacemos mapa físico conectado, esto cambiará.
	current_room.global_position = Vector2.ZERO

	connect_current_room_signals()
	move_player_to_room_spawn(current_room)
	setup_current_room()


func is_current_room_index_valid() -> bool:
	return current_room_index >= 0 and current_room_index < room_sequence.size()


func setup_current_room() -> void:
	if current_room == null:
		return

	if current_room.has_method("setup_room"):
		current_room.setup_room(player, get_current_difficulty())


func get_current_difficulty() -> int:
	# Dificultad provisional.
	# Más adelante vendrá del selector de mazmorra o del progreso del jugador.
	return 1


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
	# La sala ya está limpia.
	# No avanzamos automáticamente: la puerta se desbloquea y el jugador decide salir.

	print("DungeonManager ha recibido room_cleared de la sala actual.")


func _on_current_room_exit_requested() -> void:
	# El jugador ha entrado en la puerta de salida de una sala limpia.

	go_to_next_room()


func _on_room_item_collected(item_id: String, display_name: String) -> void:
	# Reemitimos el loot hacia Main.

	print("DungeonManager recibe loot: ", display_name)
	item_collected.emit(item_id, display_name)
