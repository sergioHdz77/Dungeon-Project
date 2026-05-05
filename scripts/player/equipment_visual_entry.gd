extends Resource
class_name EquipmentVisualEntry

# Relaciona un item_id del ItemDatabase con una textura visual.
# Para armas, grip_offset indica dónde está la empuñadura dentro de la textura.

@export var item_id: String = ""
@export var texture: Texture2D

# De momento lo usamos solo para armas.
# Ejemplos futuros: "sword", "axe", "dagger", "spear".
@export var weapon_type: String = "sword"

# Punto de agarre dentro de la textura.
# Si la empuñadura está en x=8, y=20 dentro del PNG, aquí pones Vector2(8, 20).
@export var grip_offset: Vector2 = Vector2.ZERO

# Ajuste opcional por arma.
@export var idle_rotation_degrees: float = 0.0
@export var visual_scale: Vector2 = Vector2.ONE
