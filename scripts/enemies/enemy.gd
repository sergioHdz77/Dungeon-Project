extends CharacterBody2D



@onready var attack: Node = get_node_or_null("Attack")
# -------------------------------------------------------------------
# STATS BASE
# -------------------------------------------------------------------

@export var speed: float = 120.0
@export var max_health: float = 60.0
@export var contact_damage: float = 12.0

@export var coin_value: int = 1

# -------------------------------------------------------------------
# KNOCKBACK
# -------------------------------------------------------------------

# Cuánta resistencia tiene este enemigo al knockback.
# 0.0 = recibe todo el knockback.
# 0.5 = recibe la mitad.
# 0.8 = recibe muy poco.
@export_range(0.0, 1.0, 0.05) var knockback_resistance: float = 0.0

# Fricción que reduce el knockback con el tiempo.
@export var knockback_friction: float = 900.0

# Mientras hay knockback activo, reducimos temporalmente la persecución.
# Esto evita que enemigos rápidos cancelen el empuje inmediatamente.
@export var chase_control_during_knockback: float = 0.25

var knockback_velocity: Vector2 = Vector2.ZERO

# -------------------------------------------------------------------
# VISUAL PLACEHOLDER
# -------------------------------------------------------------------

# Estos valores solo se usan mientras no haya sprite animado.
@export var draw_radius: float = 14.0
@export var enemy_color: Color = Color(0.9, 0.15, 0.15)

# Si más adelante hay AnimatedSprite2D, el círculo placeholder se puede desactivar.
@export var use_placeholder_drawing: bool = true

# -------------------------------------------------------------------
# HIT FEEDBACK
# -------------------------------------------------------------------

@export var hit_flash_duration: float = 0.10
@export var hit_flash_color: Color = Color(1.0, 1.0, 1.0)

var hit_flash_timer: float = 0.0


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
	coin_value = max(1, int(round(float(coin_value) * reward_multiplier)))

	health = max_health

	queue_redraw()
	
	if attack != null and attack.has_method("setup"):
		attack.setup(self, target, contact_damage)

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

	update_hit_flash(delta)
	update_knockback(delta)

	if attack != null and attack.has_method("process_attack"):
		attack.process_attack(delta)

	if should_chase_target():
		move_towards_target()
	else:
		velocity = knockback_velocity
		move_and_slide()

	update_visual_direction()
	queue_redraw()


func move_towards_target() -> void:
	var dir: Vector2 = global_position.direction_to(target.global_position)
	var chase_velocity: Vector2 = dir * speed

	# Si está siendo empujado, reducimos temporalmente su capacidad
	# de perseguir al jugador. Esto hace que el knockback se note
	# también en enemigos rápidos.
	if knockback_velocity.length() > 5.0:
		chase_velocity *= chase_control_during_knockback

	velocity = chase_velocity + knockback_velocity

	move_and_slide()

func apply_knockback(direction: Vector2, force: float) -> void:
	# Aplica empuje al enemigo.
	# La resistencia se configura en cada escena de enemigo.

	if direction.length() <= 0.01:
		return

	var final_force: float = force * (1.0 - knockback_resistance)

	if final_force <= 0.0:
		return

	knockback_velocity += direction.normalized() * final_force

func update_knockback(delta: float) -> void:
	# Reduce progresivamente el empuje hasta llegar a cero.
	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_friction * delta
	)

# -------------------------------------------------------------------
# VIDA / DAÑO / MUERTE
# -------------------------------------------------------------------

func take_damage(amount: float) -> void:
	health -= amount

	start_hit_flash()
	play_animation("hurt")

	print(name, " recibe daño: ", amount, " | vida restante: ", health)

	if health <= 0.0:
		die()
	else:
		queue_redraw()

func start_hit_flash() -> void:
	hit_flash_timer = hit_flash_duration

	# Si más adelante hay sprite, podemos modularlo.
	# De momento lo dejamos preparado sin depender del sprite.
	if animated_sprite != null:
		animated_sprite.modulate = hit_flash_color

func die() -> void:
	print(name, " muere")

	play_animation("death")

	if target != null and target.has_method("register_kill"):
		target.register_kill()

	drop_coin()

	# De momento borramos inmediatamente.
	# Más adelante, si hay animación de muerte, esperaremos a que termine.
	queue_free()

func update_hit_flash(delta: float) -> void:
	if hit_flash_timer <= 0.0:
		return

	hit_flash_timer -= delta

	if hit_flash_timer <= 0.0:
		hit_flash_timer = 0.0

		if animated_sprite != null:
			animated_sprite.modulate = Color.WHITE


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
	var current_color: Color = enemy_color

	if hit_flash_timer > 0.0:
		current_color = hit_flash_color

	draw_circle(Vector2.ZERO, draw_radius, current_color)


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
	
func should_chase_target() -> bool:
	if attack == null:
		return true

	if attack.has_method("is_busy"):
		if attack.is_busy():
			return false

	if attack.has_method("is_target_in_range"):
		if attack.is_target_in_range():
			return false

	return true
