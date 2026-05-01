extends Node2D

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
	# Usamos la pantalla que ya tienes, aunque todavía tenga textos antiguos.
	# Más adelante la convertiremos en menú principal con equipamiento.

	if start_screen != null:
		if start_screen.has_method("show_screen"):
			# La firma antigua esperaba:
			# duración, ahorros meta, texto de desbloqueos.
			#
			# Como ya no usamos temporizador ni ahorro de piso,
			# le pasamos valores neutros.
			start_screen.show_screen(
				0,
				0,
				"Nuevo modo: mazmorra roguelite.\nSistema de equipamiento pendiente."
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
	# De momento NO guardamos loot ni inventario.
	# Solo mostramos la pantalla final con el resultado de la mazmorra.

	run_active = false
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

			var player_level := 1
			var enemies_killed := 0
			var xp_collected := 0
			var coins_collected := 0

			if player != null:
				if player.has_method("get_level"):
					player_level = player.get_level()

				if player.has_method("get_enemies_killed"):
					enemies_killed = player.get_enemies_killed()

				if player.has_method("get_total_xp_collected"):
					xp_collected = player.get_total_xp_collected()

				if player.has_method("get_total_coins_collected"):
					coins_collected = player.get_total_coins_collected()

			var result_text := ""

			if victory:
				result_text = "Mazmorra completada.\nLoot e inventario persistente pendientes."
			else:
				result_text = "Has muerto en la mazmorra.\nPérdida de equipo pendiente."

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

func _unhandled_input(event: InputEvent) -> void:
	# Tecla temporal de debug para probar cambio de sala.
	# Más adelante esto se sustituirá por puertas o por limpiar enemigos.
	if not run_active:
		return

	if event.is_action_pressed("debug_next_room"):
		if dungeon_manager != null:
			if dungeon_manager.has_method("go_to_next_room"):
				dungeon_manager.go_to_next_room()
