extends Node2D

const ItemDatabase = preload("res://scripts/data/item_database.gd")

# Sala base de mazmorra.
#
# Responsabilidades:
# - dibujar una sala placeholder
# - bloquear/desbloquear puerta de salida
# - generar enemigos en puntos fijos
# - detectar cuándo la sala queda limpia
# - soltar loot opcional al limpiarse

signal room_cleared
signal exit_requested
signal item_collected(item_id: String, display_name: String)


# -------------------------------------------------------------------
# CONFIGURACIÓN VISUAL
# -------------------------------------------------------------------

@export var room_size: Vector2 = Vector2(720, 420)
@export var floor_color: Color = Color(0.18, 0.18, 0.20)
@export var border_color: Color = Color(0.55, 0.55, 0.60)


# -------------------------------------------------------------------
# ENEMIGOS
# -------------------------------------------------------------------

# En StartRoom se deja vacío.
# En CombatRoom/BossRoom se asigna una escena de enemigo.
@export var enemy_scene: PackedScene


# -------------------------------------------------------------------
# LOOT
# -------------------------------------------------------------------

# Si está activo, la sala soltará loot al limpiarse.
# De momento lo usamos para BossRoom.
@export var drops_loot_on_clear: bool = false

# Escena del loot que aparecerá al limpiar la sala.
@export var loot_item_scene: PackedScene


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

func setup_room(new_player: Node2D, new_difficulty: int) -> void:
	player = new_player
	difficulty = new_difficulty

	room_is_cleared = false
	alive_enemies = 0

	setup_exit_door()

	if enemy_scene == null:
		# Sala segura sin enemigos, por ejemplo StartRoom.
		mark_room_as_cleared()
		return

	spawn_enemies()

	if alive_enemies <= 0:
		# Si no se generó ningún enemigo, no bloqueamos al jugador.
		mark_room_as_cleared()
	else:
		lock_exit_door()


# -------------------------------------------------------------------
# ENEMIGOS
# -------------------------------------------------------------------

func spawn_enemies() -> void:
	var spawn_container := get_node_or_null("EnemySpawnPoints")

	if spawn_container == null:
		push_warning("%s: no tiene EnemySpawnPoints." % name)
		return

	for spawn_point in spawn_container.get_children():
		var marker := spawn_point as Marker2D

		if marker == null:
			continue

		spawn_enemy_at(marker.global_position)


func spawn_enemy_at(spawn_position: Vector2) -> void:
	var enemy := enemy_scene.instantiate() as Node2D

	if enemy == null:
		push_warning("%s: enemy_scene no instancia un Node2D." % name)
		return

	var enemies_container := get_node_or_null("Enemies") as Node2D

	if enemies_container == null:
		# Fallback para no romper una sala si olvidamos crear el contenedor.
		enemies_container = self

	enemies_container.add_child(enemy)
	enemy.global_position = spawn_position

	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")

	setup_enemy(enemy)

	alive_enemies += 1

	# Cuenta como eliminado cuando sale del árbol.
	# Normalmente ocurre al morir con queue_free().
	enemy.tree_exited.connect(_on_enemy_removed)


func setup_enemy(enemy: Node2D) -> void:
	if not enemy.has_method("setup"):
		return

	var health_multiplier: float = 1.0 + float(difficulty - 1) * 0.25
	var speed_multiplier: float = 1.0 + float(difficulty - 1) * 0.10
	var damage_multiplier: float = 1.0 + float(difficulty - 1) * 0.15
	var reward_multiplier: float = 1.0 + float(difficulty - 1) * 0.20

	enemy.setup(
		player,
		health_multiplier,
		speed_multiplier,
		damage_multiplier,
		reward_multiplier
	)


func _on_enemy_removed() -> void:
	alive_enemies -= 1

	print("Enemigo eliminado. Quedan: ", alive_enemies)

	if alive_enemies <= 0:
		print("Sala limpiada: ", name)
		mark_room_as_cleared()


# -------------------------------------------------------------------
# PUERTA DE SALIDA
# -------------------------------------------------------------------

func setup_exit_door() -> void:
	var exit_door := get_node_or_null("ExitDoor")

	if exit_door == null:
		return

	var callback := Callable(self, "_on_exit_door_requested")

	if exit_door.has_signal("exit_requested"):
		if not exit_door.exit_requested.is_connected(callback):
			exit_door.exit_requested.connect(callback)


func lock_exit_door() -> void:
	var exit_door := get_node_or_null("ExitDoor")

	if exit_door == null:
		return

	if exit_door.has_method("lock"):
		exit_door.lock()


func unlock_exit_door() -> void:
	var exit_door := get_node_or_null("ExitDoor")

	if exit_door == null:
		return

	if exit_door.has_method("unlock"):
		exit_door.unlock()


func _on_exit_door_requested() -> void:
	if not room_is_cleared:
		return

	exit_requested.emit()


# -------------------------------------------------------------------
# LIMPIEZA DE SALA / LOOT
# -------------------------------------------------------------------

func mark_room_as_cleared() -> void:
	if room_is_cleared:
		return

	room_is_cleared = true

	spawn_clear_loot()
	unlock_exit_door()

	room_cleared.emit()


func spawn_clear_loot() -> void:
	if not drops_loot_on_clear:
		return

	if loot_item_scene == null:
		return

	var item_data: Dictionary = ItemDatabase.get_random_loot_item()

	if item_data.is_empty():
		push_warning("%s: ItemDatabase no devolvió loot válido." % name)
		return

	var item_id: String = str(item_data.get("id", ""))
	var display_name: String = str(item_data.get("name", "Objeto desconocido"))

	if item_id.is_empty():
		push_warning("%s: loot generado sin id." % name)
		return

	var loot_item := loot_item_scene.instantiate() as Node2D

	if loot_item == null:
		return

	add_child(loot_item)

	# De momento aparece en el centro de la sala.
	# Más adelante podemos usar un Marker2D llamado LootSpawn.
	loot_item.global_position = global_position

	# Configuramos dinámicamente qué objeto representa este drop.
	if loot_item.has_method("setup_item"):
		loot_item.setup_item(item_id, display_name)

	if loot_item.has_signal("collected"):
		loot_item.collected.connect(_on_loot_item_collected)

	print("Loot generado en ", name, ": ", display_name)


func _on_loot_item_collected(item_id: String, display_name: String) -> void:
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
