extends Node

signal dungeon_completed

# DungeonManager será el encargado de construir y cambiar salas.
#
# De momento NO hay generación procedural real.
# De momento solo tenemos una secuencia fija:
#
# StartRoom -> CombatRoom
#
# Más adelante será:
# StartRoom -> CombatRoom -> CombatRoom -> BossRoom

@export var room_container: Node2D
@export var player: Node2D

@export var start_room_scene: PackedScene
@export var combat_room_scene: PackedScene
@export var boss_room_scene: PackedScene

var current_room: Node2D = null
var current_room_index: int = 0

var room_sequence: Array[PackedScene] = []


func create_test_dungeon() -> void:
	# Crea una mazmorra mínima de prueba.
	# Por ahora solo tiene 2 salas.

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
	# Borra la sala actual antes de cargar la nueva.
	clear_rooms()

	# Validación por seguridad.
	if current_room_index < 0 or current_room_index >= room_sequence.size():
		push_warning("DungeonManager: índice de sala fuera de rango.")
		return

	var room_scene := room_sequence[current_room_index]

	if room_scene == null:
		push_warning("DungeonManager: falta asignar una escena de sala.")
		return

	# Instanciamos la sala correspondiente.
	current_room = room_scene.instantiate() as Node2D

	if current_room == null:
		push_warning("DungeonManager: la escena no es Node2D.")
		return

	# Añadimos la sala al contenedor.
	room_container.add_child(current_room)

	# De momento todas las salas se colocan en el centro.
	# No estamos haciendo un mapa físico conectado todavía.
	current_room.global_position = Vector2.ZERO

	# Movemos al jugador al punto de aparición de esta sala.
	move_player_to_room_spawn(current_room)
	
	# Configuramos la sala.
	# Aquí la sala puede generar enemigos, preparar puertas, loot, etc.
	if current_room.has_method("setup_room"):
		current_room.setup_room(player, 1)

	# Escuchamos cuándo la sala queda limpia.
	if current_room.has_signal("room_cleared"):
		current_room.room_cleared.connect(_on_current_room_cleared)

func go_to_next_room() -> void:
	# Avanza a la siguiente sala de la secuencia.

	if room_sequence.is_empty():
		return

	current_room_index += 1

	if current_room_index >= room_sequence.size():
		# Ya no quedan más salas.
		# En este MVP provisional, eso significa victoria.
		print("Mazmorra completada.")
		dungeon_completed.emit()
		return

	load_current_room()

func move_player_to_room_spawn(room: Node2D) -> void:
	if player == null:
		push_warning("DungeonManager: falta asignar player.")
		return

	# Buscamos un Marker2D llamado PlayerSpawn dentro de la sala.
	var spawn := room.get_node_or_null("PlayerSpawn") as Marker2D

	if spawn == null:
		# Si no existe PlayerSpawn, usamos el centro de la sala.
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
	
func _on_current_room_cleared() -> void:
	# La sala actual ha sido limpiada.
	# De momento avanzamos automáticamente a la siguiente sala.
	# Más adelante aquí abriremos una puerta o mostraremos loot.

	print("DungeonManager ha recibido room_cleared de la sala actual.")

	await get_tree().create_timer(0.6).timeout

	go_to_next_room()
