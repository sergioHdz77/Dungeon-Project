extends Area2D

# Puerta/salida de una sala.
# De momento es una Area2D simple:
# - si está bloqueada, no hace nada
# - si está desbloqueada y el jugador entra, pide cambiar de sala

signal exit_requested

@export var locked: bool = true
@export var door_size: Vector2 = Vector2(80, 36)

@export var unlocked_color: Color = Color(0.25, 0.65, 1.0, 0.85)
@export var locked_color: Color = Color(0.45, 0.15, 0.15, 0.85)
@export var border_color: Color = Color(0.95, 0.95, 0.95, 0.9)


func _ready() -> void:
	# La puerta debe estar por encima del suelo de la sala.
	z_index = 30

	# Detectamos cuando entra un cuerpo físico.
	body_entered.connect(_on_body_entered)

	queue_redraw()


func set_locked(value: bool) -> void:
	# Cambia el estado de la puerta.
	# Si locked = true, la puerta se ve bloqueada y no permite salir.
	# Si locked = false, la puerta permite avanzar.

	locked = value
	queue_redraw()


func unlock() -> void:
	set_locked(false)


func lock() -> void:
	set_locked(true)


func _on_body_entered(body: Node) -> void:
	# Si la puerta está bloqueada, no hace nada.
	if locked:
		return

	# Solo el jugador puede activar la puerta.
	if body.is_in_group("player") or body.name == "Player":
		exit_requested.emit()


func _draw() -> void:
	# Dibujo provisional de la puerta.
	# Más adelante lo sustituiremos por sprite o animación.

	var current_color: Color = locked_color

	if not locked:
		current_color = unlocked_color

	var rect := Rect2(
		-door_size / 2.0,
		door_size
	)

	draw_rect(rect, current_color, true)
	draw_rect(rect, border_color, false, 2.0)
