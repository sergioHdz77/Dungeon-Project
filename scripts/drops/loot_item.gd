extends Area2D

# Drop de loot/equipo.
# A diferencia de xp_drop o coin_drop, esto representa un objeto
# que más adelante podrá guardarse en el inventario persistente.

signal collected(item_id: String, display_name: String)

@export var item_id: String = "iron_sword"
@export var display_name: String = "Espada de hierro"

@export var draw_radius: float = 12.0
@export var item_color: Color = Color(0.95, 0.8, 0.25)


func _ready() -> void:
	# Lo dibujamos por encima del suelo.
	z_index = 40

	# Detecta cuándo el jugador entra en el área.
	body_entered.connect(_on_body_entered)

	queue_redraw()


func setup_item(new_item_id: String, new_display_name: String) -> void:
	# Permite que DungeonRoom configure dinámicamente qué item representa este drop.

	item_id = new_item_id
	display_name = new_display_name

	queue_redraw()


func _on_body_entered(body: Node) -> void:
	# Solo el jugador puede recoger este loot.
	if not body.is_in_group("player") and body.name != "Player":
		return

	print("Loot recogido: ", display_name)

	collected.emit(item_id, display_name)
	queue_free()


func _draw() -> void:
	# Visual provisional del loot.
	draw_circle(Vector2.ZERO, draw_radius, item_color)

	draw_arc(
		Vector2.ZERO,
		draw_radius,
		0.0,
		TAU,
		24,
		Color(1.0, 1.0, 1.0, 0.9),
		2.0
	)
