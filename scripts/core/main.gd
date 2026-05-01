extends Node2D

# Main es el coordinador principal de la escena.
# No debería contener demasiada lógica propia.
# Su trabajo es conectar señales entre sistemas:
# RunManager, Player, HUD, pantallas y managers.

@onready var run_manager = $RunManager
@onready var upgrade_manager = $UpgradeManager
@onready var player = $Player
@onready var hud = $HUD
@onready var start_screen = $StartScreen
@onready var level_up_screen = $LevelUpScreen
@onready var run_end_screen = $RunEndScreen

func _ready() -> void:
	# Inicializa la semilla aleatoria.
	# Esto afecta a upgrades aleatorios y enemigos aleatorios.
	randomize()
	
	# Señales del RunManager.
	# RunManager controla tiempo, inicio y final de run.
	run_manager.run_finished.connect(_on_run_manager_finished)
	run_manager.time_changed.connect(_on_run_manager_time_changed)
	
	# Señales del jugador.
	# Player reemite señales de sus componentes internos.
	player.level_up_requested.connect(_on_player_level_up_requested)
	player.stats_changed.connect(update_hud)
	player.player_died.connect(_on_player_died)
	
	# Señales de las pantallas UI.
	start_screen.start_pressed.connect(_on_start_button_pressed)
	level_up_screen.upgrade_selected.connect(_on_level_up_upgrade_selected)
	run_end_screen.restart_pressed.connect(_on_restart_button_pressed)
	
	# Pintamos el HUD inicial y mostramos pantalla de inicio.
	update_hud()
	show_start_screen()

func _on_run_manager_finished(victory: bool) -> void:
	# RunManager avisa de que la run ha terminado.
	# Main se encarga de guardar ahorro y mostrar pantalla final.
	finish_run(victory)

func _on_run_manager_time_changed(_remaining_time: int, _elapsed_time: float) -> void:
	# El tiempo cambió, así que refrescamos HUD.
	update_hud()

func show_start_screen() -> void:
	# Prepara una run nueva pero no la arranca todavía.
	run_manager.prepare_run()
	
	# Mostramos la pantalla inicial con datos de meta-progresión.
	start_screen.show_screen(
		run_manager.run_duration_seconds,
		SaveManager.meta_savings,
		get_meta_unlock_text()
	)
	
	# Pausamos el árbol para que no aparezcan enemigos ni avance el juego.
	get_tree().paused = true

func _on_start_button_pressed() -> void:
	# El jugador pulsa "Empezar run".
	start_screen.hide_screen()
	
	# Reanudamos el árbol antes de arrancar la run.
	get_tree().paused = false
	
	# Ahora sí empieza el temporizador.
	run_manager.start_run()
	update_hud()

func _on_player_level_up_requested(_new_level: int) -> void:
	# El jugador subió de nivel.
	# Pedimos 3 mejoras aleatorias al UpgradeManager.
	var choices: Array = upgrade_manager.get_random_upgrades(3)
	
	# Mostramos el menú de mejoras.
	level_up_screen.show_screen(choices)
	
	# Pausamos el juego mientras el jugador decide.
	get_tree().paused = true

func _on_level_up_upgrade_selected(upgrade) -> void:
	# El jugador ha elegido una mejora.
	# Primero la registramos para mostrarla luego en pantalla final.
	upgrade_manager.register_upgrade(upgrade)
	
	# Después aplicamos su efecto al jugador.
	player.apply_upgrade(upgrade["id"])
	
	# Reanudamos la partida.
	get_tree().paused = false
	update_hud()

func _on_player_died() -> void:
	# El jugador murió.
	# No cerramos la run directamente desde Player.
	# Lo hacemos pasar por RunManager para mantener un único flujo de finalización.
	run_manager.finish_run(false)

func finish_run(victory: bool) -> void:
	# Al terminar una run, convertimos el ahorro asegurado de la run
	# en ahorro meta persistente.
	var secured_savings: int = player.get_run_savings()
	SaveManager.add_savings(secured_savings)
	
	update_hud()
	
	# Pedimos el resumen de mejoras elegidas.
	var upgrades_text: String = upgrade_manager.get_chosen_upgrades_text()
	
	# Mostramos pantalla final con estadísticas de la run.
	run_end_screen.show_screen(
		victory,
		run_manager.get_elapsed_time(),
		player.get_level(),
		player.get_enemies_killed(),
		player.get_total_xp_collected(),
		player.get_total_coins_collected(),
		secured_savings,
		SaveManager.meta_savings,
		upgrades_text
	)
	
	# Pausamos el juego en pantalla final.
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	# Reinicia la escena actual para empezar otra run desde cero.
	# El ahorro meta se mantiene porque está en SaveManager.
	get_tree().paused = false
	get_tree().reload_current_scene()

func update_hud() -> void:
	# Main no dibuja el HUD.
	# Solo pasa datos al nodo HUD.
	if hud == null:
		return
	
	hud.update_hud(
		player,
		run_manager.get_remaining_time(),
		SaveManager.meta_savings
	)

func get_meta_unlock_text() -> String:
	# Devuelve texto legible con los desbloqueos meta actuales.
	var meta_savings: int = SaveManager.meta_savings
	var text := ""
	
	text += get_unlock_line(meta_savings, 30, "+10 vida inicial")
	text += get_unlock_line(meta_savings, 75, "+4 daño inicial")
	text += get_unlock_line(meta_savings, 150, "+20 velocidad inicial")
	text += get_unlock_line(meta_savings, 300, "+1 proyectil inicial")
	
	return text

func get_unlock_line(meta_savings: int, required: int, description: String) -> String:
	# Genera una línea de texto para un desbloqueo meta.
	if meta_savings >= required:
		return "✓ %s\n" % description
	
	return "✗ %s ahorro: %s\n" % [required, description]
