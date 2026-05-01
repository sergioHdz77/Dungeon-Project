extends Area2D

# Velocidad a la que viaja el proyectil.
@export var speed: float = 420.0

# Daño que aplica al enemigo al impactar.
@export var damage: float = 20.0

# Tiempo máximo de vida del proyectil en segundos.
# Evita que los proyectiles vivan eternamente si no golpean nada.
@export var lifetime: float = 1.5

# Dirección en la que se mueve el proyectil.
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Conectamos la señal de impacto físico.
	# Area2D usa body_entered cuando entra en contacto con cuerpos físicos.
	body_entered.connect(_on_body_entered)

func setup(start_position: Vector2, target_position: Vector2, new_damage: float) -> void:
	# Configura el proyectil justo después de instanciarlo.
	global_position = start_position
	direction = start_position.direction_to(target_position)
	damage = new_damage

func _physics_process(delta: float) -> void:
	# Movimiento simple en línea recta.
	global_position += direction * speed * delta
	
	# Reducimos tiempo de vida.
	lifetime -= delta
	
	# Si se acaba su vida, se elimina.
	if lifetime <= 0:
		queue_free()

func _draw() -> void:
	# Placeholder visual del proyectil.
	draw_circle(Vector2.ZERO, 6, Color.YELLOW)

func _on_body_entered(body: Node) -> void:
	# Si golpea a un enemigo, le aplica daño y desaparece.
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()
		return
	
	# Si más adelante usamos obstáculos, el proyectil también se destruirá.
	if body.is_in_group("obstacles"):
		queue_free()
