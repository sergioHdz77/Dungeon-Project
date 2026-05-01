extends Node

# Daño base de cada proyectil.
@export var attack_damage: float = 20.0

# Tiempo entre ataques automáticos.
# Menor valor = dispara más rápido.
@export var attack_cooldown: float = 0.8

# Distancia máxima a la que el jugador puede detectar enemigos para disparar.
@export var attack_range: float = 450.0

# Cantidad de proyectiles por ataque.
@export var projectile_count: int = 1

# Separación angular entre proyectiles cuando hay más de uno.
@export var projectile_spread_degrees: float = 12.0

# Nivel del aura.
# 0 significa que el aura está desactivada.
@export var aura_level: int = 0

# Daño por segundo del aura.
@export var aura_damage_per_second: float = 0.0

# Radio del aura alrededor del jugador.
@export var aura_radius: float = 85.0

# Escena del proyectil que se instancia al atacar.
var projectile_scene: PackedScene = preload("res://scenes/combat/projectile.tscn")

# Temporizador interno del ataque automático.
var attack_timer: float = 0.0

# Referencia al Player.
# Se obtiene con get_parent() porque Combat es hijo directo de Player.
var player: Node2D = null

func _ready() -> void:
	# Guardamos referencia al jugador para consultar su posición.
	player = get_parent() as Node2D

func process_combat(delta: float) -> void:
	# Este método lo llama Player cada frame.
	# Aquí centralizamos todo el combate.
	if player == null:
		return
	
	# Bajamos el temporizador del disparo automático.
	attack_timer -= delta
	
	# Si el cooldown terminó, intentamos atacar.
	if attack_timer <= 0.0:
		try_attack()
		attack_timer = attack_cooldown
	
	# El aura, si está activa, hace daño continuamente.
	apply_aura_damage(delta)

func try_attack() -> void:
	# Busca el enemigo más cercano dentro del rango.
	var target := get_closest_enemy()
	
	if target == null:
		return
	
	# Calculamos el ángulo base hacia el enemigo.
	var base_angle: float = (target.global_position - player.global_position).angle()
	
	# Convertimos el spread de grados a radianes.
	var spread: float = deg_to_rad(projectile_spread_degrees)
	
	# Se usa para centrar los proyectiles.
	# Ejemplo: con 3 proyectiles, los offsets serán -1, 0, +1.
	var middle: float = float(projectile_count - 1) / 2.0
	
	for i in range(projectile_count):
		var angle: float = base_angle + spread * (float(i) - middle)
		
		# Creamos una posición ficticia hacia la que apuntará el proyectil.
		# Projectile solo necesita una posición inicial y una posición objetivo para calcular dirección.
		var fake_target_position: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * 100.0
		
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		
		projectile.setup(player.global_position, fake_target_position, attack_damage)

func get_closest_enemy() -> Node2D:
	# Obtenemos todos los enemigos registrados en el grupo "enemies".
	var enemies := get_tree().get_nodes_in_group("enemies")
	
	var closest_enemy: Node2D = null
	var closest_distance: float = attack_range
	
	for enemy in enemies:
		# Ignoramos referencias inválidas por seguridad.
		if not is_instance_valid(enemy):
			continue
		
		var enemy_2d := enemy as Node2D
		
		if enemy_2d == null:
			continue
		
		var distance: float = player.global_position.distance_to(enemy_2d.global_position)
		
		# Nos quedamos con el enemigo más cercano dentro del rango.
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy_2d
	
	return closest_enemy

func apply_aura_damage(delta: float) -> void:
	# Si el aura no está desbloqueada, no hace nada.
	if aura_level <= 0:
		return
	
	var enemies := get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var enemy_2d := enemy as Node2D
		
		if enemy_2d == null:
			continue
		
		var distance: float = player.global_position.distance_to(enemy_2d.global_position)
		
		# Si el enemigo está dentro del radio del aura, recibe daño por segundo.
		if distance <= aura_radius:
			if enemy_2d.has_method("take_damage"):
				enemy_2d.call("take_damage", aura_damage_per_second * delta)

func add_damage(amount: float) -> void:
	# Mejora directa de daño.
	attack_damage += amount

func multiply_cooldown(multiplier: float) -> void:
	# Multiplica el cooldown.
	# 0.88 = dispara más rápido.
	# 1.12 = dispara más lento.
	attack_cooldown *= multiplier

func add_projectiles(amount: int) -> void:
	# Añade proyectiles por ataque.
	projectile_count += amount

func add_range(amount: float) -> void:
	# Añade rango plano.
	attack_range += amount

func multiply_range(multiplier: float) -> void:
	# Modifica el rango por porcentaje.
	# 0.85 = pierde 15% de rango.
	attack_range *= multiplier

func upgrade_aura() -> void:
	# Primera vez: desbloquea aura.
	# Siguientes veces: mejora daño y radio.
	if aura_level <= 0:
		aura_level = 1
		aura_damage_per_second = 8.0
	else:
		aura_level += 1
		aura_damage_per_second += 5.0
		aura_radius += 8.0
