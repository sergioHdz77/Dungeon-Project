extends CharacterBody2D

# Boss base propio.
#
# No extiende Enemy.gd.
# Mantiene compatibilidad con EnemySpawner mediante:
# - add_to_group("enemies")
# - setup(...)
# - take_damage(...)
# - apply_knockback(...)
# - queue_free() al morir

@onready var movement: Node = get_node_or_null("Movement")
@onready var attack: Node = get_node_or_null("Attack")
@onready var loot_drop: Node = get_node_or_null("LootDrop")

# -------------------------------------------------------------------
# STATS
# -------------------------------------------------------------------

@export var boss_name: String = "Basic Boss"
@export var max_health: float = 280.0
@export var speed: float = 70.0
@export var knockback_resistance: float = 0.85
@export var knockback_friction: float = 1000.0

# -------------------------------------------------------------------
# VISUAL PLACEHOLDER
# -------------------------------------------------------------------

@export var draw_radius: float = 34.0
@export var boss_color: Color = Color(0.55, 0.1, 0.1)
@export var use_placeholder_drawing: bool = true

@export var hit_flash_duration: float = 0.10
@export var hit_flash_color: Color = Color(1.0, 1.0, 1.0)

var hit_flash_timer: float = 0.0

# -------------------------------------------------------------------
# ESTADO
# -------------------------------------------------------------------

var target: Node2D = null
var health: float = 0.0

var visuals: Node2D = null
var animated_sprite: AnimatedSprite2D = null


func _ready() -> void:
	add_to_group("enemies")
	_cache_visual_nodes()

	z_index = 20
	visible = true
	use_placeholder_drawing = true

	if health <= 0.0:
		health = max_health

	print("BOSS READY: ", name, " pos=", global_position, " parent=", get_parent())

	play_animation("idle")
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
	health = max_health

	if movement != null and movement.has_method("setup"):
		movement.setup(
			self,
			target,
			speed,
			knockback_resistance,
			knockback_friction
		)

	if attack != null and attack.has_method("setup"):
		attack.setup(
			self,
			target,
			damage_multiplier
		)

	if loot_drop != null and loot_drop.has_method("setup"):
		loot_drop.setup(self, reward_multiplier)

	queue_redraw()


func _physics_process(delta: float) -> void:
	_update_hit_flash(delta)

	if target == null:
		return

	var should_move := _should_move_towards_target()

	if movement != null and movement.has_method("process_movement"):
		movement.process_movement(delta, should_move)

	if attack != null and attack.has_method("process_attack"):
		attack.process_attack(delta)

	_update_visual_direction()
	_update_idle_or_move_animation(should_move)
	queue_redraw()


func _should_move_towards_target() -> bool:
	if attack == null:
		return true

	if attack.has_method("is_busy") and attack.is_busy():
		return false

	if attack.has_method("is_target_in_move_stop_range"):
		return not attack.is_target_in_move_stop_range()

	return true


func take_damage(amount: float) -> void:
	health -= amount
	_start_hit_flash()

	print(boss_name, " recibe daño: ", amount, " | vida restante: ", health)

	if health <= 0.0:
		die()
	else:
		play_animation("hurt")
		queue_redraw()


func apply_knockback(direction: Vector2, force: float) -> void:
	if movement == null:
		return

	if not movement.has_method("apply_knockback"):
		return

	movement.apply_knockback(direction, force)


func die() -> void:
	print(boss_name, " muere")

	play_animation("death")

	if target != null and target.has_method("register_kill"):
		target.register_kill()

	if loot_drop != null and loot_drop.has_method("drop_rewards"):
		loot_drop.drop_rewards()

	queue_free()


func _cache_visual_nodes() -> void:
	visuals = get_node_or_null("Visuals") as Node2D

	if visuals == null:
		return

	animated_sprite = visuals.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func play_animation(animation_name: String) -> void:
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return

	if animated_sprite.animation == animation_name and animated_sprite.is_playing():
		return

	animated_sprite.play(animation_name)


func _update_idle_or_move_animation(should_move: bool) -> void:
	if attack != null and attack.has_method("is_busy") and attack.is_busy():
		return

	if should_move:
		play_animation("move")
	else:
		play_animation("idle")


func _update_visual_direction() -> void:
	if animated_sprite == null:
		return

	if absf(velocity.x) <= 0.01:
		return

	animated_sprite.flip_h = velocity.x < 0.0


func _start_hit_flash() -> void:
	hit_flash_timer = hit_flash_duration

	if animated_sprite != null:
		animated_sprite.modulate = hit_flash_color


func _update_hit_flash(delta: float) -> void:
	if hit_flash_timer <= 0.0:
		return

	hit_flash_timer -= delta

	if hit_flash_timer <= 0.0:
		hit_flash_timer = 0.0

		if animated_sprite != null:
			animated_sprite.modulate = Color.WHITE


func _draw() -> void:
	if not use_placeholder_drawing:
		return

	_draw_body()
	_draw_health_bar()


func _draw_body() -> void:
	var current_color := boss_color

	if hit_flash_timer > 0.0:
		current_color = hit_flash_color

	draw_circle(Vector2.ZERO, draw_radius, current_color)


func _draw_health_bar() -> void:
	var bar_width := 80.0
	var bar_height := 6.0
	var bar_position := Vector2(-bar_width / 2.0, -draw_radius - 16.0)

	var health_ratio := 0.0

	if max_health > 0.0:
		health_ratio = clampf(health / max_health, 0.0, 1.0)

	draw_rect(
		Rect2(bar_position, Vector2(bar_width, bar_height)),
		Color(0.12, 0.12, 0.12)
	)

	draw_rect(
		Rect2(bar_position, Vector2(bar_width * health_ratio, bar_height)),
		Color(0.85, 0.1, 0.1)
	)
