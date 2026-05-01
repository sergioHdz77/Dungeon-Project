extends Area2D

# Coste en monedas de run para convertirlas en ahorro.
@export var conversion_cost: int = 10

# Ahorro asegurado que se gana al pagar el coste.
@export var savings_amount: int = 6

# Referencia al jugador cuando está dentro de la zona.
var player_inside: Node = null

# Texto que aparece cuando el jugador puede interactuar.
var prompt_label: Label

func _ready() -> void:
	# Detectamos entrada y salida del jugador en la zona.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	create_prompt_label()

func _process(_delta: float) -> void:
	# Si no hay jugador dentro, no hacemos nada.
	if player_inside == null:
		return
	
	# Al pulsar E, intentamos convertir monedas en ahorro.
	if Input.is_action_just_pressed("interact"):
		if player_inside.has_method("try_secure_savings"):
			var success: bool = player_inside.try_secure_savings(conversion_cost, savings_amount)
			
			if success:
				print("Ahorro asegurado: +", savings_amount)
			else:
				print("No tienes monedas suficientes para ahorrar.")

func create_prompt_label() -> void:
	# Texto flotante dentro de la zona de ahorro.
	prompt_label = Label.new()
	prompt_label.text = "E: asegurar 10 monedas -> 6 ahorro"
	prompt_label.position = Vector2(-105, -82)
	prompt_label.visible = false
	add_child(prompt_label)

func _on_body_entered(body: Node) -> void:
	# Si el cuerpo puede asegurar ahorro, lo consideramos jugador válido.
	if body.has_method("try_secure_savings"):
		player_inside = body
		prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	# Si sale el jugador que teníamos registrado, limpiamos referencia.
	if body == player_inside:
		player_inside = null
		prompt_label.visible = false

func _draw() -> void:
	# Zona azul semitransparente.
	draw_circle(Vector2.ZERO, 60, Color(0.1, 0.45, 1.0, 0.25))
	
	# Borde de la zona para que se lea mejor.
	draw_arc(Vector2.ZERO, 60, 0, TAU, 64, Color(0.25, 0.65, 1.0), 3.0)
