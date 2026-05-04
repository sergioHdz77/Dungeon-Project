extends Node

# Componente responsable SOLO del movimiento físico del jugador.
# No decide animaciones, combate, equipo ni progresión.

@export var speed: float = 220.0
@export var map_half_size: Vector2 = Vector2(1200, 800)
@export var player_radius: float = 12.0

var player: CharacterBody2D = null
var combat: Node = null


func setup(owner_player: CharacterBody2D, combat_component: Node) -> void:
	player = owner_player
	combat = combat_component


func process_movement(input_dir: Vector2) -> void:
	if player == null:
		return

	var final_speed: float = speed

	if combat != null and combat.has_method("get_movement_speed_multiplier"):
		final_speed *= combat.get_movement_speed_multiplier()

	player.velocity = input_dir * final_speed
	player.move_and_slide()
	_clamp_to_map_bounds()


func _clamp_to_map_bounds() -> void:
	if player == null:
		return

	player.global_position.x = clamp(
		player.global_position.x,
		-map_half_size.x + player_radius,
		map_half_size.x - player_radius
	)
	player.global_position.y = clamp(
		player.global_position.y,
		-map_half_size.y + player_radius,
		map_half_size.y - player_radius
	)
