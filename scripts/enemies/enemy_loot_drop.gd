extends Node

# Componente responsable SOLO de soltar recompensas al morir el enemigo.
# No gestiona vida, movimiento, ataque ni IA.

@export var coin_value: int = 1
@export var coin_drop_scene: PackedScene = preload("res://scenes/drops/coin_drop.tscn")

var enemy: Node2D = null


func setup(owner_enemy: Node2D, reward_multiplier: float = 1.0) -> void:
	enemy = owner_enemy
	apply_reward_multiplier(reward_multiplier)


func apply_reward_multiplier(reward_multiplier: float) -> void:
	coin_value = max(1, int(round(float(coin_value) * reward_multiplier)))


func drop_rewards() -> void:
	drop_coin()


func drop_coin() -> void:
	if enemy == null:
		return

	if coin_drop_scene == null:
		return

	var coin_drop = coin_drop_scene.instantiate()

	get_tree().current_scene.add_child(coin_drop)

	if coin_drop.has_method("setup"):
		coin_drop.setup(enemy.global_position + Vector2(8, 0), coin_value)
