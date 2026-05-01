extends Node
class_name DungeonRunManager

signal run_started
signal run_won
signal run_lost

@export var dungeon_manager: Node
@export var player: Node

var current_difficulty: int = 1
var run_active: bool = false

func start_run() -> void:
	# Marca que hay una run activa.
	run_active = true
	
	# De momento la dificultad empieza siempre en 1.
	# Más adelante vendrá elegida desde el menú principal.
	current_difficulty = 1
	
	# Genera la mazmorra inicial.
	if dungeon_manager:
		dungeon_manager.generate_dungeon(current_difficulty)
	
	run_started.emit()

func win_run() -> void:
	# El jugador ha matado al boss.
	# Más adelante aquí guardaremos el loot conseguido.
	run_active = false
	run_won.emit()

func lose_run() -> void:
	# El jugador ha muerto.
	# Más adelante aquí eliminaremos equipo equipado y loot temporal.
	run_active = false
	run_lost.emit()
