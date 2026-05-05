extends Line2D

# Estela pixelada simple para el arma.
# Sigue la posición global de un Marker2D colocado en la punta del arma.

@export var max_points: int = 9
@export var sample_interval: float = 0.012
@export var fade_speed: float = 28.0

var target_tip: Marker2D = null
var is_active: bool = false
var sample_timer: float = 0.0


func setup(tip: Marker2D) -> void:
	target_tip = tip


func start_trail() -> void:
	if target_tip == null:
		return

	is_active = true
	visible = true
	clear_points()
	sample_timer = 0.0
	add_tip_point()


func stop_trail() -> void:
	is_active = false


func clear_trail() -> void:
	clear_points()
	visible = false
	is_active = false
	sample_timer = 0.0


func _process(delta: float) -> void:
	if is_active:
		update_active_trail(delta)
	else:
		fade_trail(delta)


func update_active_trail(delta: float) -> void:
	if target_tip == null:
		return

	sample_timer -= delta

	if sample_timer > 0.0:
		return

	sample_timer = sample_interval

	var local_tip_position: Vector2 = to_local(target_tip.global_position)

	# Redondeo para que el rastro quede más pixelado.
	local_tip_position.x = round(local_tip_position.x)
	local_tip_position.y = round(local_tip_position.y)

	add_point(local_tip_position)

	while get_point_count() > max_points:
		remove_point(0)


func add_tip_point() -> void:
	if target_tip == null:
		return

	var local_tip_position: Vector2 = to_local(target_tip.global_position)

	# Redondeo para que el rastro quede mas pixelado.
	local_tip_position.x = round(local_tip_position.x)
	local_tip_position.y = round(local_tip_position.y)

	add_point(local_tip_position)


func fade_trail(delta: float) -> void:
	if get_point_count() <= 0:
		visible = false
		return

	var remove_count: int = int(ceil(fade_speed * delta))

	for i in range(remove_count):
		if get_point_count() > 0:
			remove_point(0)

	if get_point_count() <= 0:
		visible = false
