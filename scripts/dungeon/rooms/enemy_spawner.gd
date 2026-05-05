extends Node

# Componente responsable SOLO de generar enemigos dentro de una sala.
#
# No bloquea puertas.
# No decide cuándo una sala está limpia.
# No suelta loot.
# Solo:
# - lee EnemySpawnPoints
# - elige enemigos por dificultad
# - instancia enemigos
# - configura enemigos
# - avisa cuántos quedan vivos

signal enemy_removed(remaining_enemies: int)

var room: Node2D = null
var player: Node2D = null
var difficulty: int = 1

var enemy_scene: PackedScene = null
var enemy_scenes: Array[PackedScene] = []

var alive_enemy_count: int = 0


func setup(
	owner_room: Node2D,
	room_player: Node2D,
	room_difficulty: int,
	fallback_enemy_scene: PackedScene,
	enemy_scene_pool: Array[PackedScene]
) -> void:
	room = owner_room
	player = room_player
	difficulty = room_difficulty
	enemy_scene = fallback_enemy_scene
	enemy_scenes = enemy_scene_pool
	alive_enemy_count = 0


func has_any_enemy_scene() -> bool:
	if enemy_scene != null:
		return true

	for scene: PackedScene in enemy_scenes:
		if scene != null:
			return true

	return false


func spawn_enemies() -> int:
	alive_enemy_count = 0

	if room == null:
		return alive_enemy_count

	var spawn_container := room.get_node_or_null("EnemySpawnPoints")

	if spawn_container == null:
		push_warning("%s: no tiene EnemySpawnPoints." % room.name)
		return alive_enemy_count

	for spawn_point: Node in spawn_container.get_children():
		var marker := spawn_point as Marker2D

		if marker == null:
			continue

		spawn_enemy_at(marker.global_position)

	return alive_enemy_count


func spawn_enemy_at(spawn_position: Vector2) -> void:
	var selected_enemy_scene: PackedScene = pick_enemy_scene()

	if selected_enemy_scene == null:
		if room != null:
			push_warning("%s: no hay enemy_scene válida." % room.name)
		return

	var enemy := selected_enemy_scene.instantiate() as Node2D

	if enemy == null:
		if room != null:
			push_warning("%s: la escena de enemigo no instancia un Node2D." % room.name)
		return

	var enemies_container := get_enemies_container()

	enemies_container.add_child(enemy)
	enemy.global_position = spawn_position

	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")

	setup_enemy(enemy)

	alive_enemy_count += 1

	if not enemy.tree_exited.is_connected(_on_enemy_tree_exited):
		enemy.tree_exited.connect(_on_enemy_tree_exited)


func get_enemies_container() -> Node:
	if room == null:
		return self

	var enemies_container: Node = room.get_node_or_null("Enemies")

	if enemies_container == null:
		return room

	return enemies_container


func pick_enemy_scene() -> PackedScene:
	if enemy_scenes.is_empty():
		return enemy_scene

	var available_scenes: Array[PackedScene] = get_enemy_pool_for_difficulty()

	if available_scenes.is_empty():
		return enemy_scene

	var random_index: int = randi_range(0, available_scenes.size() - 1)

	return available_scenes[random_index]


func get_enemy_pool_for_difficulty() -> Array[PackedScene]:
	var pool: Array[PackedScene] = []

	if enemy_scenes.is_empty():
		return pool

	var max_index_exclusive: int = 1

	if difficulty == 2:
		max_index_exclusive = min(2, enemy_scenes.size())
	elif difficulty >= 3:
		max_index_exclusive = enemy_scenes.size()

	for i in range(max_index_exclusive):
		var scene: PackedScene = enemy_scenes[i]

		if scene != null:
			pool.append(scene)

	return pool


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


func _on_enemy_tree_exited() -> void:
	alive_enemy_count -= 1
	alive_enemy_count = max(0, alive_enemy_count)

	enemy_removed.emit(alive_enemy_count)
