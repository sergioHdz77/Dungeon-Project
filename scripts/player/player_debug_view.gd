extends Node2D

# Dibujo temporal/debug del jugador.
# Está separado de Player.gd para que cuando entren sprites definitivos
# podamos eliminar o desactivar este nodo sin tocar gameplay.

@export var use_placeholder_drawing: bool = false

var player: CharacterBody2D = null
var combat: Node = null
var progression: Node = null
var visual_controller: Node = null


func setup(
	owner_player: CharacterBody2D,
	combat_component: Node,
	progression_component: Node,
	visual_component: Node
) -> void:
	player = owner_player
	combat = combat_component
	progression = progression_component
	visual_controller = visual_component


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_melee_attack_debug()
	_draw_block_debug()
	_draw_player_body()
	_draw_health_bar()
	_draw_stamina_bar()


func _draw_melee_attack_debug() -> void:
	if combat == null:
		return
	if not "attack_debug_timer" in combat:
		return
	if combat.attack_debug_timer <= 0.0:
		return

	var attack_direction: Vector2 = combat.last_attack_direction.normalized()
	var base_angle: float = attack_direction.angle()
	var half_arc: float = deg_to_rad(combat.melee_arc_degrees / 2.0)
	var start_angle: float = base_angle - half_arc
	var end_angle: float = base_angle + half_arc
	var radius: float = combat.melee_range

	draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 24, Color(1.0, 0.9, 0.35, 0.9), 4.0)

	var left_dir: Vector2 = Vector2.RIGHT.rotated(start_angle)
	var right_dir: Vector2 = Vector2.RIGHT.rotated(end_angle)
	draw_line(Vector2.ZERO, left_dir * radius, Color(1.0, 0.9, 0.35, 0.55), 2.0)
	draw_line(Vector2.ZERO, right_dir * radius, Color(1.0, 0.9, 0.35, 0.55), 2.0)


func _draw_block_debug() -> void:
	if combat == null:
		return
	if not "is_blocking" in combat:
		return
	if not combat.is_blocking:
		return

	var block_direction: Vector2 = combat.facing_direction.normalized()
	var block_center: Vector2 = block_direction * 22.0

	draw_circle(block_center, 14.0, Color(0.25, 0.55, 1.0, 0.45))
	draw_arc(block_center, 14.0, 0.0, TAU, 24, Color(0.45, 0.75, 1.0, 0.95), 3.0)


func _draw_player_body() -> void:
	var has_real_visuals := false
	if visual_controller != null and visual_controller.has_method("has_animated_visuals"):
		has_real_visuals = visual_controller.has_animated_visuals()

	if has_real_visuals and not use_placeholder_drawing:
		return

	draw_circle(Vector2.ZERO, 12.0, Color(0.85, 0.85, 0.95))


func _draw_health_bar() -> void:
	if progression == null:
		return

	var bar_width: float = 44.0
	var bar_height: float = 6.0
	var bar_position: Vector2 = Vector2(-bar_width / 2.0, -36.0)
	var health_ratio: float = 0.0

	if progression.max_health > 0.0:
		health_ratio = progression.health / progression.max_health

	draw_rect(Rect2(bar_position, Vector2(bar_width, bar_height)), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(bar_position, Vector2(bar_width * health_ratio, bar_height)), Color(0.2, 0.9, 0.3))


func _draw_stamina_bar() -> void:
	if combat == null:
		return
	if not combat.has_method("get_stamina_ratio"):
		return

	var bar_width: float = 44.0
	var bar_height: float = 4.0
	var bar_position: Vector2 = Vector2(-bar_width / 2.0, -27.0)
	var stamina_ratio: float = combat.get_stamina_ratio()

	draw_rect(Rect2(bar_position, Vector2(bar_width, bar_height)), Color(0.10, 0.10, 0.10))
	draw_rect(Rect2(bar_position, Vector2(bar_width * stamina_ratio, bar_height)), Color(0.35, 0.75, 1.0))
