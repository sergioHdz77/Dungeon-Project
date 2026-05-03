extends Area2D

# Puerta/salida de una sala.
#
# Soporta:
# - bloqueo/desbloqueo
# - dirección lógica north/south/east/west
# - activarse/desactivarse según conexiones del mapa procedural

signal exit_requested
signal directional_exit_requested(direction: String)

@export var locked: bool = true

@export_enum("north", "south", "east", "west") var direction: String = "east"

@export var door_size: Vector2 = Vector2(80, 36)

@export var unlocked_color: Color = Color(0.25, 0.65, 1.0, 0.85)
@export var locked_color: Color = Color(0.45, 0.15, 0.15, 0.85)
@export var border_color: Color = Color(0.95, 0.95, 0.95, 0.9)

var exit_enabled: bool = true

var temporary_disabled_timer: float = 0.0

func _ready() -> void:
	z_index = 30

	body_entered.connect(_on_body_entered)

	apply_enabled_state()
	queue_redraw()

func _process(delta: float) -> void:
	if temporary_disabled_timer <= 0.0:
		return

	temporary_disabled_timer -= delta

	if temporary_disabled_timer < 0.0:
		temporary_disabled_timer = 0.0
		
func set_exit_enabled(value: bool) -> void:
	# Activa o desactiva completamente esta salida.
	# Si está desactivada:
	# - no se ve
	# - no detecta al jugador
	# - no emite señales

	exit_enabled = value
	apply_enabled_state()
	queue_redraw()
	
func set_temporary_disabled(duration: float) -> void:
	# Evita que la puerta se active justo al cargar una sala
	# si el jugador aparece dentro o demasiado cerca del área.
	temporary_disabled_timer = max(temporary_disabled_timer, duration)

func apply_enabled_state() -> void:
	visible = exit_enabled
	monitoring = exit_enabled
	monitorable = exit_enabled

	for child in get_children():
		var collision_shape := child as CollisionShape2D

		if collision_shape == null:
			continue

		collision_shape.disabled = not exit_enabled


func set_locked(value: bool) -> void:
	locked = value
	queue_redraw()


func unlock() -> void:
	set_locked(false)


func lock() -> void:
	set_locked(true)


func _on_body_entered(body: Node) -> void:
	if temporary_disabled_timer > 0.0:
		return

	if not exit_enabled:
		return

	if locked:
		return

	if not body.is_in_group("player") and body.name != "Player":
		return

	exit_requested.emit()
	directional_exit_requested.emit(direction)


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
