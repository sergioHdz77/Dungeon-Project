extends Area2D

# Cantidad de monedas que da este drop.
@export var coin_amount: int = 1

func _ready() -> void:
	# Detecta cuándo un cuerpo entra en el área.
	body_entered.connect(_on_body_entered)

func setup(start_position: Vector2, amount: int) -> void:
	# Configura posición y valor de la moneda al crearla.
	global_position = start_position
	coin_amount = amount

func _on_body_entered(body: Node) -> void:
	# Si el cuerpo sabe recibir monedas, se las añadimos.
	# Normalmente será Player.
	if body.has_method("add_coins"):
		body.add_coins(coin_amount)
		queue_free()

func _draw() -> void:
	# Placeholder visual amarillo para la moneda.
	draw_circle(Vector2.ZERO, 8, Color(1.0, 0.8, 0.15))
