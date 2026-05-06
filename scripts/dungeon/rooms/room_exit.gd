extends Area2D

# Puerta/salida de una sala.
#
# Soporta:
# - bloqueo/desbloqueo
# - dirección lógica north/south/east/west
# - activarse/desactivarse según conexiones del mapa procedural
# - evitar cambios de estado de físicas mientras Godot está procesando body_entered

signal exit_requested
signal directional_exit_requested(direction: String)

@export var locked: bool = true
@export_enum("north", "south", "east", "west") var direction: String = "east"

@export var door_size: Vector2 = Vector2(80, 36)

@export var unlocked_color: Color = Color(0.25, 0.65, 1.0, 0.85)
@export var locked_color: Color = Color(0.45, 0.15, 0.15, 0.85)
@export var border_color: Color = Color(0.95, 0.95, 0.95, 0.9)

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var exit_enabled: bool = true
var temporarily_disabled: bool = false
var exit_request_pending: bool = false


func _ready() -> void:
	z_index = 30

	var callback := Callable(self, "_on_body_entered")

	if not body_entered.is_connected(callback):
		body_entered.connect(callback)

	apply_enabled_state()
	queue_redraw()


func set_exit_enabled(value: bool) -> void:
	# Activa o desactiva completamente esta salida.
	# Si está desactivada:
	# - no se ve
	# - no detecta al jugador
	# - no emite señales.

	exit_enabled = value
	apply_enabled_state()
	queue_redraw()


func set_locked(value: bool) -> void:
	locked = value
	apply_enabled_state()
	queue_redraw()


func unlock() -> void:
	set_locked(false)


func lock() -> void:
	set_locked(true)


func set_temporary_disabled(duration: float) -> void:
	temporarily_disabled = true
	apply_enabled_state()
	queue_redraw()

	await get_tree().create_timer(duration).timeout

	if not is_inside_tree():
		return

	temporarily_disabled = false
	exit_request_pending = false

	apply_enabled_state()
	queue_redraw()


func apply_enabled_state() -> void:
	var should_be_active: bool = exit_enabled and not locked and not temporarily_disabled

	visible = exit_enabled

	# Importante:
	# Usamos set_deferred porque esta función puede ejecutarse indirectamente
	# desde señales físicas como body_entered.
	set_deferred("monitoring", should_be_active)
	set_deferred("monitorable", should_be_active)

	if collision_shape != null:
		collision_shape.set_deferred("disabled", not should_be_active)


func _on_body_entered(body: Node) -> void:
	if exit_request_pending:
		return

	if not exit_enabled:
		return

	if locked:
		return

	if temporarily_disabled:
		return

	if not body.is_in_group("player"):
		return

	exit_request_pending = true

	# Diferimos la emisión para no cambiar de sala dentro del flush de físicas.
	call_deferred("emit_exit_requested_deferred")


func emit_exit_requested_deferred() -> void:
	if not exit_enabled:
		exit_request_pending = false
		return

	if locked:
		exit_request_pending = false
		return

	# No comprobamos temporarily_disabled aquí.
	# La puerta podía haberse desactivado temporalmente después de detectar al player.
	# Esta función representa una salida ya aceptada.
	directional_exit_requested.emit(direction)
	exit_requested.emit()

	# Evita dobles disparos mientras se carga/mueve al player a la sala nueva.
	set_temporary_disabled(0.25)


func _draw() -> void:
	if not exit_enabled:
		return

	var current_color: Color = locked_color

	if not locked:
		current_color = unlocked_color

	var rect := Rect2(
		-door_size / 2.0,
		door_size
	)

	draw_rect(rect, current_color, true)
	draw_rect(rect, border_color, false, 2.0)
