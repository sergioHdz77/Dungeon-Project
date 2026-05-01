extends Node2D

# Script base para una sala de mazmorra.
#
# Ahora mismo hace 3 cosas:
# - dibuja una sala rectangular provisional
# - guarda si la sala tiene enemigos
# - instancia enemigos en puntos fijos si existen

signal room_cleared

@export var room_size: Vector2 = Vector2(720, 420)
@export var floor_color: Color = Color(0.18, 0.18, 0.20)
@export var border_color: Color = Color(0.55, 0.55, 0.60)

# Escena de enemigo que usará esta sala.
# En StartRoom lo dejamos vacío.
# En CombatRoom asignaremos una escena de enemigo existente.
@export var enemy_scene: PackedScene

var player: Node2D = null
var difficulty: int = 1
var alive_enemies: int = 0


func setup_room(new_player: Node2D, new_difficulty: int) -> void:
	# DungeonManager llama a este método cuando carga la sala.
	player = new_player
	difficulty = new_difficulty

	# Si esta sala no tiene enemy_scene asignada, no genera enemigos.
	# Esto permite que StartRoom use el mismo script sin enemigos.
	if enemy_scene == null:
		return

	spawn_enemies()


func spawn_enemies() -> void:
	# Buscamos un nodo llamado EnemySpawnPoints.
	# Sus hijos serán Marker2D que indican dónde aparece cada enemigo.
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
	var enemy := enemy_scene.instantiate()

	if enemy == null:
		return

	# Añadimos el enemigo dentro de la propia sala.
	# Así, si la sala se borra, sus enemigos también desaparecen.
	var enemies_container := get_node_or_null("Enemies") as Node2D

	if enemies_container == null:
		# Fallback por seguridad.
		# Si la sala no tiene nodo Enemies, el enemigo se añade directamente a la sala.
		enemies_container = self

	enemies_container.add_child(enemy)

	# Usamos global_position para que aparezca exactamente en el Marker2D.
	enemy.global_position = spawn_position

	# Lo metemos en el grupo enemies por si el enemigo antiguo no lo hacía.
	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")

	# El enemigo anterior usa setup así:
	# setup(player, health_multiplier, speed_multiplier, damage_multiplier, reward_multiplier)
	if enemy.has_method("setup"):
		var health_multiplier := 1.0 + float(difficulty - 1) * 0.25
		var speed_multiplier := 1.0 + float(difficulty - 1) * 0.10
		var damage_multiplier := 1.0 + float(difficulty - 1) * 0.15
		var reward_multiplier := 1.0 + float(difficulty - 1) * 0.20

		enemy.setup(
			player,
			health_multiplier,
			speed_multiplier,
			damage_multiplier,
			reward_multiplier
		)

	alive_enemies += 1

	# Detectamos cuándo el enemigo sale de la escena.
	enemy.tree_exited.connect(_on_enemy_removed)

func _on_enemy_removed() -> void:
	# Un enemigo de esta sala ha desaparecido.
	# Normalmente significa que ha muerto.

	alive_enemies -= 1

	print("Enemigo eliminado. Quedan: ", alive_enemies)

	if alive_enemies <= 0:
		print("Sala limpiada: ", name)
		room_cleared.emit()

func _draw() -> void:
	# Dibujamos el suelo de la sala centrado en el origen del nodo.
	var rect := Rect2(
		-room_size / 2.0,
		room_size
	)

	draw_rect(rect, floor_color, true)
	draw_rect(rect, border_color, false, 4.0)
