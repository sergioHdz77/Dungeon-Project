extends Node2D

# Tamaño total del mapa visible.
@export var map_size: Vector2 = Vector2(2400, 1600)

func _draw() -> void:
	draw_background()

func draw_background() -> void:
	# Rectángulo oscuro que representa el suelo.
	var top_left := -map_size / 2.0
	var rect := Rect2(top_left, map_size)
	
	draw_rect(rect, Color(0.0, 0.0, 0.0, 1.0))
