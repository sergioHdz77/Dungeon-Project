extends CharacterBody2D

# -------------------------------------------------------------------
# STATS BASE
# -------------------------------------------------------------------

@export var speed: float = 120.0
@export var max_health: float = 60.0
@export var contact_damage: float = 12.0

@export var xp_value: float = 10.0
@export var coin_value: int = 1


# -------------------------------------------------------------------
# VISUAL PLACEHOLDER
# -------------------------------------------------------------------

# Estos valores solo se usan mientras no haya sprite animado.
@export var draw_radius: float = 14.0
@export var enemy_color: Color = Color(0.9, 0.15, 0.15)

# Si más adelante hay AnimatedSprite2D, el círculo placeholder se puede desactivar.
@export var use_placeholder_drawing: bool = true


# -------------------------------------------------------------------
# REFERENCIAS
# -------------------------------------------------------------------

var target: Node2D = null
var health: float = 0.0

var visuals: Node2D = null
var animated_sprite: AnimatedSprite2D = null


# -------------------------------------------------------------------
# DROPS
# -------------------------------------------------------------------

var xp_drop_scene: PackedScene = preload("res://scenes/drops/xp_drop.tscn")
var coin_drop_scene: PackedScene = preload("res://scenes/drops/coin_drop.tscn")


# -------------------------------------------------------------------
# SETUP
# -------------------------------------------------------------------

func _ready() -> void:
	add_to_group("enemies")

	cache_visual_nodes()

	if health <= 0.0:
		health = max_health

	play_animation("move")
	queue_redraw()


func setup(
	new_target: Node2D,
	health_multiplier: float,
	speed_multiplier: float,
	damage_multiplier: float,
	reward_multiplier: float
) -> void:
	target = new_target

	max_health *= health_multiplier
	speed *= speed_multiplier
	contact_damage *= damage_multiplier
	xp_value *= reward_multiplier
	coin_value = max(1, int(round(float(coin_value) * reward_multiplier)))

	health = max_health

	queue_redraw()


func cache_visual_nodes() -> void:
	visuals = get_node_or_null("Visuals") as Node2D

	if visuals == null:
		return

	animated_sprite = visuals.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


# -------------------------------------------------------------------
# UPDATE
# -------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if target == null:
		return

	move_towards_target()
	apply_contact_damage(delta)
	update_visual_direction()

	queue_redraw()


func move_towards_target() -> void:
	var dir: Vector2 = global_position.direction_to(target.global_position)
	velocity = dir * speed
	move_and_slide()


func apply_contact_damage(delta: float) -> void:
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()

		if collider == null:
			continue

		var collider_node := collider as Node

		if collider_node == null:
			continue

		# Los enemigos solo dañan al jugador.
		# Evita que un enemigo intente dañar a otro enemigo.
		if not collider_node.is_in_group("player") and collider_node.name != "Player":
			continue

		if collider_node.has_method("take_damage"):
			collider_node.take_damage(contact_damage * delta, self)


# -------------------------------------------------------------------
# VIDA / DAÑO / MUERTE
# -------------------------------------------------------------------

func take_damage(amount: float) -> void:
	health -= amount

	play_animation("hurt")

	print(name, " recibe daño: ", amount, " | vida restante: ", health)

	if health <= 0.0:
		die()
	else:
		queue_redraw()


func die() -> void:
	print(name, " muere")

	play_animation("death")

	if target != null and target.has_method("register_kill"):
		target.register_kill()

	drop_xp()
	drop_coin()

	# De momento borramos inmediatamente.
	# Más adelante, si hay animación de muerte, esperaremos a que termine.
	queue_free()


func drop_xp() -> void:
	if xp_drop_scene == null:
		return

	var xp_drop = xp_drop_scene.instantiate()
	get_tree().current_scene.add_child(xp_drop)
	xp_drop.setup(global_position + Vector2(-8, 0), xp_value)


func drop_coin() -> void:
	if coin_drop_scene == null:
		return

	var coin_drop = coin_drop_scene.instantiate()
	get_tree().current_scene.add_child(coin_drop)
	coin_drop.setup(global_position + Vector2(8, 0), coin_value)


# -------------------------------------------------------------------
# VISUAL / ANIMACIÓN
# -------------------------------------------------------------------

func update_visual_direction() -> void:
	# Preparado para sprites laterales.
	# Si el enemigo se mueve hacia la izquierda, volteamos el sprite.

	if animated_sprite == null:
		return

	if absf(velocity.x) <= 0.01:
		return

	animated_sprite.flip_h = velocity.x < 0.0


func play_animation(animation_name: String) -> void:
	# Intenta reproducir una animación si existe.
	# Si no hay AnimatedSprite2D o no tiene esa animación, no pasa nada.

	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return

	if animated_sprite.animation == animation_name and animated_sprite.is_playing():
		return

	animated_sprite.play(animation_name)


func has_animated_visuals() -> bool:
	if animated_sprite == null:
		return false

	if animated_sprite.sprite_frames == null:
		return false

	return true


# -------------------------------------------------------------------
# DIBUJO PLACEHOLDER
# -------------------------------------------------------------------

func _draw() -> void:
	# Si ya tenemos sprite animado real, podemos ocultar el placeholder.
	if has_animated_visuals() and not use_placeholder_drawing:
		return

	draw_enemy_body_placeholder()
	draw_health_bar()


func draw_enemy_body_placeholder() -> void:
	draw_circle(Vector2.ZERO, draw_radius, enemy_color)


func draw_health_bar() -> void:
	var bar_width: float = 34.0
	var bar_height: float = 4.0
	var bar_position: Vector2 = Vector2(-bar_width / 2.0, -draw_radius - 10.0)

	var health_ratio: float = 0.0

	if max_health > 0.0:
		health_ratio = clampf(health / max_health, 0.0, 1.0)

	draw_rect(
		Rect2(bar_position, Vector2(bar_width, bar_height)),
		Color(0.15, 0.15, 0.15)
	)

	draw_rect(
		Rect2(bar_position, Vector2(bar_width * health_ratio, bar_height)),
		Color(0.9, 0.25, 0.25)
	)
