extends Node2D

# Sala base de mazmorra.
#
# Responsabilidades:
# - dibujar una sala placeholder
# - bloquear/desbloquear puertas de salida
# - coordinar EnemySpawner
# - detectar cuándo la sala queda limpia
# - soltar loot opcional al limpiarse
#
# Responsabilidades delegadas:
# - generación de enemigos -> EnemySpawner.gd
#
# Fase actual:
# - mantiene exit_requested antiguo sin dirección
# - añade directional_exit_requested(direction) para mapa procedural real

signal room_cleared

# Señal antigua.
# Se mantiene temporalmente para no romper DungeonManager.
signal exit_requested

# Señal nueva.
# Más adelante DungeonManager usará esta para cargar la sala conectada por dirección.
signal directional_exit_requested(direction: String)

signal item_collected(item_id: String, display_name: String)


@onready var enemy_spawner: Node = get_node_or_null("EnemySpawner")

@onready var room_loot_drop: Node = get_node_or_null("RoomLootDrop")

# -------------------------------------------------------------------
# CONFIGURACIÓN VISUAL
# -------------------------------------------------------------------

@export var room_size: Vector2 = Vector2(720, 420)
@export var floor_color: Color = Color(0.18, 0.18, 0.20)
@export var border_color: Color = Color(0.55, 0.55, 0.60)


# -------------------------------------------------------------------
# ENEMIGOS
# -------------------------------------------------------------------

# Fallback: enemigo único de la sala.
# En BossRoom puedes seguir usando esto para boss_enemy.tscn.
@export var enemy_scene: PackedScene

# Pool opcional de enemigos.
# En CombatRoom puedes meter aquí:
# enemy_grunt, enemy_fast, enemy_tank.
#
# Si está vacío, se usa enemy_scene.
@export var enemy_scenes: Array[PackedScene] = []


# -------------------------------------------------------------------
# ESTADO INTERNO
# -------------------------------------------------------------------

var player: Node2D = null
var difficulty: int = 1
var alive_enemies: int = 0
var room_is_cleared: bool = false


# -------------------------------------------------------------------
# SETUP DE SALA
# -------------------------------------------------------------------

func setup_room(
	new_player: Node2D,
	new_difficulty: int,
	already_cleared: bool = false
) -> void:
	player = new_player
	difficulty = new_difficulty
	room_is_cleared = false
	alive_enemies = 0

	setup_exit_doors()
	setup_enemy_spawner()
	setup_room_loot_drop()
	
	# Si esta sala ya estaba limpia, no volvemos a generar enemigos ni loot.
	# Esto es importante al volver hacia atrás o entrar en ramas laterales.
	if already_cleared:
		room_is_cleared = true
		unlock_exit_doors()
		return

	if not room_has_any_enemy_scene():
		# Sala segura sin enemigos, por ejemplo StartRoom.
		mark_room_as_cleared()
		return

	alive_enemies = spawn_room_enemies()

	if alive_enemies <= 0:
		mark_room_as_cleared()
	else:
		lock_exit_doors()


func setup_enemy_spawner() -> void:
	if enemy_spawner == null:
		return

	if enemy_spawner.has_method("setup"):
		enemy_spawner.setup(
			self,
			player,
			difficulty,
			enemy_scene,
			enemy_scenes
		)

	if enemy_spawner.has_signal("enemy_removed"):
		var callback := Callable(self, "_on_enemy_spawner_enemy_removed")

		if not enemy_spawner.is_connected("enemy_removed", callback):
			enemy_spawner.connect("enemy_removed", callback)

func setup_room_loot_drop() -> void:
	if room_loot_drop == null:
		return

	if room_loot_drop.has_method("setup"):
		room_loot_drop.setup(self)

	if room_loot_drop.has_signal("item_collected"):
		var callback := Callable(self, "_on_room_loot_item_collected")

		if not room_loot_drop.is_connected("item_collected", callback):
			room_loot_drop.connect("item_collected", callback)

func room_has_any_enemy_scene() -> bool:
	if enemy_spawner == null:
		return false

	if not enemy_spawner.has_method("has_any_enemy_scene"):
		return false

	return enemy_spawner.has_any_enemy_scene()


func spawn_room_enemies() -> int:
	if enemy_spawner == null:
		return 0

	if not enemy_spawner.has_method("spawn_enemies"):
		return 0

	return enemy_spawner.spawn_enemies()


func _on_enemy_spawner_enemy_removed(remaining_enemies: int) -> void:
	alive_enemies = remaining_enemies

	print("Enemigo eliminado. Quedan: ", alive_enemies)

	if alive_enemies <= 0:
		print("Sala limpiada: ", name)
		mark_room_as_cleared()


# -------------------------------------------------------------------
# PUERTAS DE SALIDA
# -------------------------------------------------------------------

func configure_exit_doors_for_connections(
	connections: Dictionary,
	room_type: String = ""
) -> void:
	# Activa solo las puertas que tienen conexión en el mapa procedural.
	#
	# Excepción:
	# - En BossRoom, permitimos siempre la salida east.
	# - Esa puerta no conecta con otra sala.
	# - DungeonManager interpreta east sin conexión como mazmorra completada.

	var exit_doors: Array[Node] = get_exit_doors()

	for exit_door: Node in exit_doors:
		if exit_door == null:
			continue

		var door_direction: String = get_exit_door_direction(exit_door)
		var should_enable: bool = connections.has(door_direction)

		# Salida final de BossRoom.
		if room_type == "boss" and door_direction == "east":
			should_enable = true

		if exit_door.has_method("set_exit_enabled"):
			exit_door.set_exit_enabled(should_enable)
		else:
			exit_door.visible = should_enable


func setup_exit_doors() -> void:
	var exit_doors: Array[Node] = get_exit_doors()

	for exit_door: Node in exit_doors:
		setup_single_exit_door(exit_door)


func setup_single_exit_door(exit_door: Node) -> void:
	if exit_door == null:
		return

	# Si la puerta ya tiene señal direccional, usamos esa.
	# Esto evita duplicar eventos, porque room_exit.gd emite señal antigua y nueva.
	if exit_door.has_signal("directional_exit_requested"):
		var callback := Callable(self, "_on_directional_exit_door_requested")

		if not exit_door.is_connected("directional_exit_requested", callback):
			exit_door.connect("directional_exit_requested", callback)

		return

	# Fallback para puertas antiguas sin dirección.
	if exit_door.has_signal("exit_requested"):
		var legacy_callback := Callable(self, "_on_exit_door_requested")

		if not exit_door.is_connected("exit_requested", legacy_callback):
			exit_door.connect("exit_requested", legacy_callback)


func get_exit_doors() -> Array[Node]:
	var exit_doors: Array[Node] = []

	# Compatibilidad con la estructura antigua:
	# DungeonRoom/ExitDoor
	var single_exit := get_node_or_null("ExitDoor")

	if single_exit != null:
		exit_doors.append(single_exit)

	# Estructura nueva:
	# DungeonRoom/Doors/NorthDoor
	# DungeonRoom/Doors/SouthDoor
	# DungeonRoom/Doors/EastDoor
	# DungeonRoom/Doors/WestDoor
	var doors_container := get_node_or_null("Doors")

	if doors_container != null:
		for child: Node in doors_container.get_children():
			if child == null:
				continue

			if not exit_doors.has(child):
				exit_doors.append(child)

	return exit_doors


func get_exit_door_direction(exit_door: Node) -> String:
	# Lee la dirección exportada del RoomExit.
	# Si no existe, usa "east" como fallback para compatibilidad.

	if exit_door == null:
		return "east"

	if "direction" in exit_door:
		return str(exit_door.direction)

	return "east"


func lock_exit_doors() -> void:
	var exit_doors: Array[Node] = get_exit_doors()

	for exit_door: Node in exit_doors:
		if exit_door.has_method("lock"):
			exit_door.lock()


func unlock_exit_doors() -> void:
	var exit_doors: Array[Node] = get_exit_doors()

	for exit_door: Node in exit_doors:
		if exit_door.has_method("unlock"):
			exit_door.unlock()


func set_exit_doors_temporarily_disabled(duration: float) -> void:
	var exit_doors: Array[Node] = get_exit_doors()

	for exit_door: Node in exit_doors:
		if exit_door.has_method("set_temporary_disabled"):
			exit_door.set_temporary_disabled(duration)


func _on_directional_exit_door_requested(direction: String) -> void:
	if not room_is_cleared:
		return

	print("Salida direccional solicitada: ", direction)

	# Señal nueva para el futuro sistema de grafo.
	directional_exit_requested.emit(direction)

	# Señal antigua para que DungeonManager siga funcionando ahora mismo.
	exit_requested.emit()


func _on_exit_door_requested() -> void:
	if not room_is_cleared:
		return

	print("Salida antigua solicitada sin dirección.")

	exit_requested.emit()


# -------------------------------------------------------------------
# LIMPIEZA DE SALA / LOOT
# -------------------------------------------------------------------

func mark_room_as_cleared() -> void:
	if room_is_cleared:
		return

	room_is_cleared = true

	drop_clear_loot()
	unlock_exit_doors()

	room_cleared.emit()

func drop_clear_loot() -> void:
	if room_loot_drop == null:
		return

	if not room_loot_drop.has_method("drop_clear_loot"):
		return

	room_loot_drop.drop_clear_loot(difficulty)


func _on_room_loot_item_collected(item_id: String, display_name: String) -> void:
	item_collected.emit(item_id, display_name)


# -------------------------------------------------------------------
# DIBUJO PLACEHOLDER
# -------------------------------------------------------------------

func _draw() -> void:
	var rect := Rect2(
		-room_size / 2.0,
		room_size
	)

	draw_rect(rect, floor_color, true)
	draw_rect(rect, border_color, false, 4.0)
