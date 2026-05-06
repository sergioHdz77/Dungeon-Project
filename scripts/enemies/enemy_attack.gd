extends Node

# Componente responsable SOLO del ataque del enemigo.
# No mueve al enemigo, no gestiona vida y no suelta loot.
#
# Rework:
# - Antes: el enemigo esperaba attack_windup y aplicaba daño.
# - Ahora: intenta reproducir una animación "attack".
# - El daño se aplica en un frame concreto de la animación.
# - Si no hay animación configurada todavía, mantiene el comportamiento antiguo con attack_windup.

@export var attack_range: float = 34.0
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 1.0

# Mantengo esta variable para no romper tu configuración actual del inspector.
# Se usará como fallback si todavía no existe animación de ataque.
@export var attack_windup: float = 0.25

# Nueva configuración para ataque basado en animación.
@export var attack_animation_name: String = "attack"

# Frame de impacto.
# Si tu animación tiene 4 frames:
# 0 = prepara
# 1 = windup
# 2 = impacto
# 3 = recuperación
# Entonces attack_hit_frame debería ser 2.
@export var attack_hit_frame: int = 2

# Tiempo de recuperación si todavía no hay animación real.
@export var fallback_recovery: float = 0.20

# Seguridad para no dejar al enemigo atascado si la animación está mal configurada.
@export var animation_timeout_margin: float = 0.10

var enemy: Node2D = null
var target: Node2D = null
var animated_sprite: AnimatedSprite2D = null

var cooldown_timer: float = 0.0

var is_attacking: bool = false
var has_applied_hit: bool = false
var using_animation_attack: bool = false

var windup_timer: float = 0.0
var recovery_timer: float = 0.0
var animation_timeout_timer: float = 0.0


func setup(owner_enemy: Node2D, attack_target: Node2D, base_damage: float) -> void:
	enemy = owner_enemy
	target = attack_target
	attack_damage = base_damage

	cache_visual_nodes()
	connect_animation_signals()


func cache_visual_nodes() -> void:
	if enemy == null:
		return

	# Ruta real de tu escena:
	# Enemy
	# └── Visuals
	#     └── AnimatedSprite2D
	animated_sprite = enemy.get_node_or_null("Visuals/AnimatedSprite2D") as AnimatedSprite2D


func connect_animation_signals() -> void:
	if animated_sprite == null:
		return

	if not animated_sprite.frame_changed.is_connected(_on_animation_frame_changed):
		animated_sprite.frame_changed.connect(_on_animation_frame_changed)

	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)


func process_attack(delta: float) -> void:
	if enemy == null:
		return

	if target == null:
		return

	update_cooldown(delta)

	if is_attacking:
		process_current_attack(delta)
		return

	if cooldown_timer > 0.0:
		return

	if is_target_in_range():
		start_attack()


func update_cooldown(delta: float) -> void:
	if cooldown_timer <= 0.0:
		return

	cooldown_timer -= delta

	if cooldown_timer < 0.0:
		cooldown_timer = 0.0


func start_attack() -> void:
	is_attacking = true
	has_applied_hit = false

	# Antes de reproducir la animación de ataque,
	# orientamos visualmente al enemigo hacia el player.
	face_target_before_attack()

	using_animation_attack = try_play_attack_animation()

	if using_animation_attack:
		animation_timeout_timer = get_attack_animation_duration() + animation_timeout_margin
	else:
		# Fallback compatible con el sistema anterior.
		# Si no hay animación "attack", sigue usando attack_windup.
		windup_timer = attack_windup
		recovery_timer = fallback_recovery


func process_current_attack(delta: float) -> void:
	if using_animation_attack:
		process_animation_attack(delta)
	else:
		process_fallback_attack(delta)


func process_animation_attack(delta: float) -> void:
	animation_timeout_timer -= delta

	if animation_timeout_timer > 0.0:
		return

	# Seguridad:
	# Si la animación no ha emitido animation_finished o el frame no ha llegado,
	# cerramos el ataque para evitar que el enemigo se quede bloqueado.
	if not has_applied_hit:
		trigger_attack_hit_frame()

	finish_attack()


func process_fallback_attack(delta: float) -> void:
	if not has_applied_hit:
		windup_timer -= delta

		if windup_timer > 0.0:
			return

		trigger_attack_hit_frame()
		return

	recovery_timer -= delta

	if recovery_timer <= 0.0:
		finish_attack()


func try_play_attack_animation() -> bool:
	if animated_sprite == null:
		return false

	if animated_sprite.sprite_frames == null:
		return false

	if not animated_sprite.sprite_frames.has_animation(attack_animation_name):
		return false

	animated_sprite.play(attack_animation_name)
	return true

func face_target_before_attack() -> void:
	if enemy == null:
		return

	if target == null:
		return

	if animated_sprite == null:
		return

	var direction: Vector2 = enemy.global_position.direction_to(target.global_position)

	if direction.length() <= 0.01:
		return

	# De momento solo tenemos flip horizontal.
	# Si el player está más a la izquierda que el enemigo, miramos a izquierda.
	# Si está más a la derecha, miramos a derecha.
	if absf(direction.x) >= absf(direction.y):
		animated_sprite.flip_h = direction.x < 0.0

func get_attack_animation_duration() -> float:
	if animated_sprite == null:
		return attack_windup + fallback_recovery

	if animated_sprite.sprite_frames == null:
		return attack_windup + fallback_recovery

	if not animated_sprite.sprite_frames.has_animation(attack_animation_name):
		return attack_windup + fallback_recovery

	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(attack_animation_name)
	var animation_speed: float = animated_sprite.sprite_frames.get_animation_speed(attack_animation_name)

	if frame_count <= 0:
		return attack_windup + fallback_recovery

	if animation_speed <= 0.0:
		return attack_windup + fallback_recovery

	return float(frame_count) / animation_speed


func _on_animation_frame_changed() -> void:
	if not is_attacking:
		return

	if has_applied_hit:
		return

	if animated_sprite == null:
		return

	if animated_sprite.animation != attack_animation_name:
		return

	if animated_sprite.frame >= attack_hit_frame:
		trigger_attack_hit_frame()


func _on_animation_finished() -> void:
	if not is_attacking:
		return

	if animated_sprite == null:
		return

	if animated_sprite.animation != attack_animation_name:
		return

	if not has_applied_hit:
		trigger_attack_hit_frame()

	finish_attack()


func trigger_attack_hit_frame() -> void:
	if has_applied_hit:
		return

	has_applied_hit = true
	apply_attack_damage()


func apply_attack_damage() -> void:
	if target == null:
		return

	# Igual que antes: si el player se ha apartado antes del golpe,
	# no recibe daño.
	if not is_target_in_range():
		return

	if target.has_method("take_damage"):
		target.take_damage(attack_damage, enemy)


func finish_attack() -> void:
	is_attacking = false
	has_applied_hit = false
	using_animation_attack = false

	windup_timer = 0.0
	recovery_timer = 0.0
	animation_timeout_timer = 0.0

	cooldown_timer = attack_cooldown

	update_animation_after_attack()


func update_animation_after_attack() -> void:
	if enemy == null:
		return

	if not enemy.has_method("play_animation"):
		return

	# Si el player sigue en rango, el enemigo se queda quieto esperando cooldown.
	# Visualmente debería estar en idle, no andando.
	if is_target_in_range():
		enemy.play_animation("idle")
	else:
		enemy.play_animation("move")


func is_target_in_range() -> bool:
	if enemy == null:
		return false

	if target == null:
		return false

	var distance: float = enemy.global_position.distance_to(target.global_position)

	return distance <= attack_range


func is_busy() -> bool:
	return is_attacking
