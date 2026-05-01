extends RefCounted

# UpgradeDatabase contiene los datos de las mejoras.
# Aquí NO se aplica la lógica de las mejoras.
# La lógica real está en Player.apply_upgrade(upgrade_id).
#
# Cada mejora tiene:
# id          -> identificador usado por Player.apply_upgrade()
# name        -> texto visible en el menú
# description -> explicación visible
# category    -> útil para ordenar o filtrar mejoras más adelante

static func get_all_upgrades() -> Array:
	return [
		{
			"id": "damage",
			"name": "Contrato indefinido",
			"description": "+6 daño de ataque.",
			"category": "combat"
		},
		{
			"id": "cooldown",
			"name": "Café de máquina",
			"description": "Disparas un 12% más rápido.",
			"category": "combat"
		},
		{
			"id": "speed",
			"name": "Patinete prestado",
			"description": "+25 velocidad de movimiento.",
			"category": "mobility"
		},
		{
			"id": "health",
			"name": "Alquiler compartido",
			"description": "+20 vida máxima y recuperas 20 vida.",
			"category": "defense"
		},
		{
			"id": "projectile",
			"name": "Networking sospechoso",
			"description": "+1 proyectil por ataque.",
			"category": "combat"
		},
		{
			"id": "range",
			"name": "Curso de LinkedIn",
			"description": "+80 rango de ataque.",
			"category": "combat"
		},
		{
			"id": "aura",
			"name": "Reunión que pudo ser email",
			"description": "Desbloquea o mejora un aura que daña enemigos cercanos.",
			"category": "weapon"
		},
		{
			"id": "internship",
			"name": "Becario en cárnica",
			"description": "+1 moneda/s, pero pierdes 0.35 vida/s.",
			"category": "risk"
		},
		{
			"id": "overtime",
			"name": "Horas extra eternas",
			"description": "+10 daño, pero pierdes un 12% de velocidad.",
			"category": "risk"
		},
		{
			"id": "master_humo",
			"name": "Máster del humo",
			"description": "+25% XP, pero recibes un 15% más de daño.",
			"category": "risk"
		},
		{
			"id": "networking_risky",
			"name": "Networking sospechoso premium",
			"description": "+1 proyectil, pero pierdes un 15% de rango.",
			"category": "risk"
		},
		{
			"id": "dental_insurance",
			"name": "Seguro dental premium",
			"description": "+0.8 vida/s, pero disparas un 12% más lento.",
			"category": "risk"
		}
	]
