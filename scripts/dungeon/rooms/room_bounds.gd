extends StaticBody2D

# Crea límites físicos para una sala rectangular.
# La sala sigue centrada en (0, 0), como DungeonRoom.
# Importante:
# - No escala CollisionShape2D.
# - Cambia RectangleShape2D.size, que es lo correcto.
# - Deja paredes completas. Las puertas se colocan un poco por dentro.

@export var room_size: Vector2 = Vector2(640, 384)
@export var wall_thickness: float = 16.0

func _ready() -> void:
	_clear_old_collision_shapes()
	_create_room_bounds()


func _clear_old_collision_shapes() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()


func _create_room_bounds() -> void:
	var half_width := room_size.x / 2.0
	var half_height := room_size.y / 2.0

	_create_wall(
		"TopWallCollision",
		Vector2(0, -half_height),
		Vector2(room_size.x, wall_thickness)
	)

	_create_wall(
		"BottomWallCollision",
		Vector2(0, half_height),
		Vector2(room_size.x, wall_thickness)
	)

	_create_wall(
		"LeftWallCollision",
		Vector2(-half_width, 0),
		Vector2(wall_thickness, room_size.y)
	)

	_create_wall(
		"RightWallCollision",
		Vector2(half_width, 0),
		Vector2(wall_thickness, room_size.y)
	)


func _create_wall(wall_name: String, wall_position: Vector2, wall_size: Vector2) -> void:
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = wall_name
	collision_shape.position = wall_position
	collision_shape.scale = Vector2.ONE

	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = wall_size

	collision_shape.shape = rectangle_shape
	add_child(collision_shape)
