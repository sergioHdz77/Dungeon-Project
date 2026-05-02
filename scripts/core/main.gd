extends Node2D

const ItemDatabase = preload("res://scripts/data/item_database.gd")

# Main sigue siendo el coordinador principal,
# pero esta versión ya NO coordina el survivor-like antiguo.
#
# De momento solo hace esto:
# - muestra pantalla inicial
# - espera a que el jugador pulse empezar
# - arranca una run de dungeon simple
# - escucha si el jugador muere
# - muestra pantalla final
#
# Todavía NO genera mazmorras.
# Todavía NO gestiona loot.
# Todavía NO guarda inventario.
# Eso vendrá después.

@onready var dungeon_manager: Node = get_node_or_null("DungeonManager")
@onready var dungeon_run_manager: Node = get_node_or_null("DungeonRunManager")
@onready var player: Node = get_node_or_null("Player")
@onready var hud: Node = get_node_or_null("HUD")
@onready var start_screen: Node = get_node_or_null("StartScreen")
@onready var run_end_screen: Node = get_node_or_null("RunEndScreen")

var run_active: bool = false

var run_loot: Array[Dictionary] = []

func _ready() -> void:
	# Inicializa la semilla aleatoria.
	# Más adelante se usará para salas, loot y enemigos.
	randomize()

	# Señales del jugador.
	# De momento solo nos interesa vida/muerte y refrescar HUD.
	if player != null:
		if player.has_signal("stats_changed"):
			player.stats_changed.connect(update_hud)

		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
			
	# Señales del DungeonManager.
	# Cuando la mazmorra termina, Main cierra la run como victoria.
	if dungeon_manager != null:
		if dungeon_manager.has_signal("dungeon_completed"):
			dungeon_manager.dungeon_completed.connect(_on_dungeon_completed)

		if dungeon_manager.has_signal("item_collected"):
			dungeon_manager.item_collected.connect(_on_item_collected)
			
	# Pantalla inicial.
	if start_screen != null:
		if start_screen.has_signal("start_pressed"):
			start_screen.start_pressed.connect(_on_start_button_pressed)

	# Pantalla final.
	if run_end_screen != null:
		if run_end_screen.has_signal("restart_pressed"):
			run_end_screen.restart_pressed.connect(_on_restart_button_pressed)

	update_hud()
	show_start_screen()


func show_start_screen() -> void:
	# Mostramos el menú inicial.
	# Ya no usamos datos antiguos de survivor-like.
	# Ahora mostramos oro, inventario y arma que se equipará automáticamente.

	if start_screen != null:
		if start_screen.has_method("show_screen"):
			var inventory_text: String = SaveManager.get_inventory_text()
			var equipped_weapon_text: String = get_auto_equipped_weapon_text()

			start_screen.show_screen(
				SaveManager.persistent_gold,
				inventory_text,
				equipped_weapon_text
			)
		else:
			start_screen.visible = true

	# El juego queda pausado mientras estamos en el menú.
	get_tree().paused = true

func _on_start_button_pressed() -> void:
	# El jugador pulsa empezar.

	if start_screen != null:
		if start_screen.has_method("hide_screen"):
			start_screen.hide_screen()
		else:
			start_screen.visible = false

	# Activamos la partida.
	get_tree().paused = false
	run_active = true
	
	# Limpiamos el loot temporal de la run anterior.
	# El inventario persistente ya está en SaveManager.
	run_loot.clear()
	
	# Equipamos automáticamente la primera arma disponible.
	# Esto es provisional hasta tener pantalla de equipamiento.
	equip_first_weapon_from_inventory()
	
	# Creamos la primera sala de la mazmorra.
	# De momento solo existe una sala inicial estática.
	if dungeon_manager != null:
		if dungeon_manager.has_method("create_test_dungeon"):
			dungeon_manager.create_test_dungeon()

	# Si DungeonRunManager ya existe y tiene start_run(),
	# lo llamamos. Si aún está vacío, no pasa nada.
	if dungeon_run_manager != null:
		if dungeon_run_manager.has_method("start_run"):
			dungeon_run_manager.start_run()

	update_hud()


func _on_player_died() -> void:
	# El jugador ha muerto.
	# Ya no pasamos por RunManager porque RunManager era de tiempo/survivor-like.

	if not run_active:
		return

	finish_run(false)

func _on_dungeon_completed() -> void:
	# La mazmorra se ha completado.
	# De momento esto significa victoria directa.
	# Más adelante solo se llamará después de matar al boss.

	if not run_active:
		return

	finish_run(true)

func finish_run(victory: bool) -> void:
	# Cierra la run actual.
	#
	# Si ganas:
	# - el loot de run pasa al inventario persistente.
	# - las monedas de run pasan al oro persistente.
	#
	# Si mueres:
	# - pierdes el arma equipada.
	# - el loot de run se pierde.
	# - las monedas de run se pierden.
	#
	# Todavía NO gestionamos armadura ni otros slots.

	run_active = false

	var lost_equipment_text: String = ""
	var run_gold: int = 0

	if player != null:
		if player.has_method("get_run_coins"):
			run_gold = player.get_run_coins()

	if victory:
		# Si gana, el loot de run pasa al inventario persistente.
		if not run_loot.is_empty():
			SaveManager.add_inventory_items(run_loot)

			print("Inventario persistente actual:")
			print(SaveManager.get_inventory_text())

		# Si gana, también conserva las monedas recogidas durante la run.
		if run_gold > 0:
			SaveManager.add_gold(run_gold)
	else:
		# Si muere, pierde el equipo que llevaba equipado.
		# El loot de run y las monedas de run no se guardan.
		lost_equipment_text = lose_equipped_items_on_death()

	update_hud()

	if run_end_screen != null:
		if run_end_screen.has_method("show_screen"):
			# Mantenemos la firma antigua de RunEndScreen para no rehacer la UI todavía.
			#
			# Parámetros antiguos:
			# victory,
			# elapsed_time,
			# level,
			# enemies_killed,
			# xp_collected,
			# coins_collected,
			# secured_savings,
			# meta_savings,
			# upgrades_text

			var player_level: int = 1
			var enemies_killed: int = 0
			var xp_collected: int = 0
			var coins_collected: int = 0

			if player != null:
				if player.has_method("get_level"):
					player_level = player.get_level()

				if player.has_method("get_enemies_killed"):
					enemies_killed = player.get_enemies_killed()

				if player.has_method("get_total_xp_collected"):
					xp_collected = player.get_total_xp_collected()

				if player.has_method("get_total_coins_collected"):
					coins_collected = player.get_total_coins_collected()

			var result_text: String = ""

			if victory:
				result_text = "Mazmorra completada.\n\n"

				result_text += "Oro conseguido: %s\n" % run_gold
				result_text += "Oro total: %s\n\n" % SaveManager.persistent_gold

				if run_loot.is_empty():
					result_text += "No has conseguido loot."
				else:
					result_text += "Loot conseguido:\n"

					for item_data: Dictionary in run_loot:
						var item_name: String = str(item_data.get("name", "Objeto desconocido"))
						result_text += "- %s\n" % item_name

					result_text += "\nGuardado en inventario persistente."
			else:
				result_text = "Has muerto en la mazmorra.\n\n"

				result_text += lost_equipment_text
				result_text += "\n\nOro perdido: %s\n" % run_gold

				result_text += "\nLoot perdido:\n"

				if run_loot.is_empty():
					result_text += "- Ninguno"
				else:
					for item_data: Dictionary in run_loot:
						var item_name: String = str(item_data.get("name", "Objeto desconocido"))
						result_text += "- %s\n" % item_name

			run_end_screen.show_screen(
				victory,
				0,
				player_level,
				enemies_killed,
				xp_collected,
				coins_collected,
				0,
				0,
				result_text
			)
		else:
			run_end_screen.visible = true

	# Pausamos en pantalla final.
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	# Reinicia la escena actual.
	# De momento es la forma más simple de empezar otra prueba limpia.

	get_tree().paused = false
	get_tree().reload_current_scene()


func update_hud() -> void:
	# El HUD todavía es el antiguo.
	# No lo reescribimos ahora.
	# Simplemente le pasamos valores neutros donde antes esperaba tiempo y ahorro meta.

	if hud == null:
		return

	if hud.has_method("update_hud") and player != null:
		hud.update_hud(
			player,
			0,
			0
		)
		
func _on_item_collected(item_id: String, display_name: String) -> void:
	# Guardamos el loot conseguido durante esta run.
	# Guardamos id + nombre:
	# - id: sirve para inventario/equipamiento real
	# - name: sirve para mostrar texto al jugador

	var item_data := {
		"id": item_id,
		"name": display_name
	}

	run_loot.append(item_data)

	print("Loot de run añadido: ", display_name, " | id: ", item_id)
	
func get_auto_equipped_weapon_text() -> String:
	# Devuelve el arma que se equipará automáticamente al empezar la run.
	# De momento elegimos la primera arma encontrada en el inventario persistente.

	for item_data: Dictionary in SaveManager.persistent_inventory:
		var item_id: String = str(item_data.get("id", ""))

		if item_id.is_empty():
			continue

		if ItemDatabase.is_weapon(item_id):
			var weapon_name: String = ItemDatabase.get_item_name(item_id)
			return "Arma: %s" % weapon_name

	return "Arma: ninguna"
	
func equip_first_weapon_from_inventory() -> void:
	# Equipamiento automático provisional.
	# Busca la primera arma del inventario persistente y se la equipa al jugador.
	# Más adelante esto lo hará una pantalla de equipamiento real.

	if player == null:
		return

	if not player.has_method("equip_weapon"):
		return

	for item_data: Dictionary in SaveManager.persistent_inventory:
		var item_id: String = str(item_data.get("id", ""))

		if item_id.is_empty():
			continue

		if ItemDatabase.is_weapon(item_id):
			player.equip_weapon(item_id)
			return

	print("No hay armas en el inventario persistente para equipar.")
	
func lose_equipped_items_on_death() -> String:
	# Elimina del inventario persistente el equipo que el jugador llevaba equipado.
	# De momento solo gestionamos arma.
	# Más adelante añadiremos armadura y otros slots.

	if player == null:
		return "No había equipo equipado."

	if not player.has_method("get_equipped_weapon_id"):
		return "No había equipo equipado."

	var weapon_id: String = player.get_equipped_weapon_id()

	if weapon_id.is_empty():
		return "No había arma equipada."

	var weapon_name: String = "Arma desconocida"

	if player.has_method("get_equipped_weapon_name"):
		weapon_name = player.get_equipped_weapon_name()

	var removed: bool = SaveManager.remove_inventory_item_once(weapon_id)

	if removed:
		return "Equipo perdido:\n- %s" % weapon_name

	return "El arma equipada no estaba en el inventario persistente."
