extends Node2D

# Tamaño total del mapa visible.
@export var map_size: Vector2 = Vector2(2400, 1600)

# Separación entre líneas de la cuadrícula.
@export var grid_size: int = 80

func _draw() -> void:
	# Dibujamos el mapa en tres capas:
	# fondo, cuadrícula y borde.
	draw_background()
	draw_grid()
	draw_border()

func draw_background() -> void:
	# Rectángulo oscuro que representa el suelo.
	var top_left := -map_size / 2.0
	var rect := Rect2(top_left, map_size)
	
	draw_rect(rect, Color(0.08, 0.09, 0.12))

func draw_grid() -> void:
	# Cuadrícula suave para que el movimiento se perciba mejor.
	var top_left := -map_size / 2.0
	var bottom_right := map_size / 2.0
	
	var x := top_left.x
	
	while x <= bottom_right.x:
		draw_line(
			Vector2(x, top_left.y),
			Vector2(x, bottom_right.y),
			Color(1, 1, 1, 0.05),
			1.0
		)
		x += grid_size
	
	var y := top_left.y
	
	while y <= bottom_right.y:
		draw_line(
			Vector2(top_left.x, y),
			Vector2(bottom_right.x, y),
			Color(1, 1, 1, 0.05),
			1.0
		)
		y += grid_size

func draw_border() -> void:
	# Borde del mapa.
	# El jugador está limitado a este rectángulo desde player.gd.
	var top_left := -map_size / 2.0
	var rect := Rect2(top_left, map_size)
	
	draw_rect(rect, Color(0.35, 0.45, 0.65, 0.8), false, 4.0)
