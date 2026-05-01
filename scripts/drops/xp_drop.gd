extends Area2D

# Cantidad de XP que da este drop.
@export var xp_amount: float = 10.0

func _ready() -> void:
	# Detecta cuándo un cuerpo entra en el área.
	body_entered.connect(_on_body_entered)

func setup(start_position: Vector2, amount: float) -> void:
	# Configura posición y valor del drop al crearlo.
	global_position = start_position
	xp_amount = amount

func _on_body_entered(body: Node) -> void:
	# Si el cuerpo tiene método add_xp, asumimos que puede recoger XP.
	# Normalmente será Player.
	if body.has_method("add_xp"):
		body.add_xp(xp_amount)
		queue_free()

func _draw() -> void:
	# Placeholder visual azul para la XP.
	draw_circle(Vector2.ZERO, 8, Color(0.2, 0.7, 1.0))
