extends CharacterBody2D

# Velocidad base del enemigo.
@export var speed: float = 120.0

# Vida máxima base.
@export var max_health: float = 60.0

# Daño por segundo cuando está tocando al jugador.
@export var contact_damage: float = 12.0

# XP que suelta al morir.
@export var xp_value: float = 10.0

# Monedas que suelta al morir.
@export var coin_value: int = 1

# Tamaño visual del círculo provisional.
@export var draw_radius: float = 14.0

# Color visual del enemigo.
@export var enemy_color: Color = Color(0.9, 0.15, 0.15)

# Objetivo al que persigue, normalmente Player.
var target: Node2D = null

# Vida actual.
var health: float = 0.0

# Drops que aparecen al morir.
var xp_drop_scene: PackedScene = preload("res://scenes/drops/xp_drop.tscn")
var coin_drop_scene: PackedScene = preload("res://scenes/drops/coin_drop.tscn")

func setup(
	new_target: Node2D,
	health_multiplier: float,
	speed_multiplier: float,
	damage_multiplier: float,
	reward_multiplier: float
) -> void:
	# Configura el enemigo al ser creado por el spawner.
	# Los multiplicadores vienen del escalado de dificultad de la run.
	target = new_target
	
	max_health *= health_multiplier
	speed *= speed_multiplier
	contact_damage *= damage_multiplier
	xp_value *= reward_multiplier
	coin_value = max(1, int(round(float(coin_value) * reward_multiplier)))
	
	health = max_health

func _ready() -> void:
	# Todos los enemigos entran en este grupo.
	# El autoataque y el aura buscan nodos dentro de "enemies".
	add_to_group("enemies")
	
	# Si el enemigo fue colocado manualmente y no pasó por setup(),
	# inicializamos su vida igualmente.
	if health <= 0.0:
		health = max_health

func _physics_process(delta: float) -> void:
	if target == null:
		return

	# Movimiento directo hacia el jugador.
	# Más adelante se puede sustituir por navegación si usamos obstáculos.
	var dir: Vector2 = global_position.direction_to(target.global_position)
	velocity = dir * speed
	move_and_slide()

	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()

		if collider == null:
			continue

		# Solo hacemos daño al jugador.
		# Esto evita que un enemigo intente llamar a take_damage(amount, source)
		# sobre otro enemigo, cuyo take_damage solo acepta amount.
		var collider_node := collider as Node

		if collider_node == null:
			continue

		if not collider_node.is_in_group("player") and collider_node.name != "Player":
			continue

		if collider_node.has_method("take_damage"):
			collider_node.take_damage(contact_damage * delta, self)

	queue_redraw()

func take_damage(amount: float) -> void:
	# Recibe daño del ataque melee.
	health -= amount

	print(name, " recibe daño: ", amount, " | vida restante: ", health)

	if health <= 0.0:
		die()
	else:
		queue_redraw()

func die() -> void:
	print(name, " muere")

	# Si el target sabe registrar kills, le avisamos.
	# En este caso normalmente target será Player.
	if target != null and target.has_method("register_kill"):
		target.register_kill()
	
	drop_xp()
	drop_coin()
	queue_free()

func drop_xp() -> void:
	# Crea el drop de XP en la posición del enemigo.
	var xp_drop = xp_drop_scene.instantiate()
	get_tree().current_scene.add_child(xp_drop)
	xp_drop.setup(global_position + Vector2(-8, 0), xp_value)

func drop_coin() -> void:
	# Crea el drop de moneda en la posición del enemigo.
	var coin_drop = coin_drop_scene.instantiate()
	get_tree().current_scene.add_child(coin_drop)
	coin_drop.setup(global_position + Vector2(8, 0), coin_value)

func _draw() -> void:
	# Placeholder visual del enemigo.
	draw_circle(Vector2.ZERO, draw_radius, enemy_color)
	
	# Barra de vida local encima del enemigo.
	var bar_width: float = 34.0
	var bar_height: float = 4.0
	var bar_position: Vector2 = Vector2(-bar_width / 2.0, -draw_radius - 10.0)
	var health_ratio: float = health / max_health
	
	draw_rect(
		Rect2(bar_position, Vector2(bar_width, bar_height)),
		Color(0.15, 0.15, 0.15)
	)
	
	draw_rect(
		Rect2(bar_position, Vector2(bar_width * health_ratio, bar_height)),
		Color(0.9, 0.25, 0.25)
	)
