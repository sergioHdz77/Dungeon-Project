extends Resource
class_name EquipmentVisualEntry

# Relaciona un item_id del ItemDatabase con una textura visual.
# Ejemplo:
# item_id = "iron_sword"
# texture = textura PNG de la espada de hierro

@export var item_id: String = ""
@export var texture: Texture2D
