extends Node

# SaveManager es Autoload.
# Eso significa que existe globalmente como SaveManager
# y se mantiene accesible desde cualquier escena.

# Archivo donde se guarda el progreso.
# user:// apunta a una carpeta segura de datos del usuario.
const SAVE_PATH := "user://save_game.json"

# Ahorro meta total persistente.
var meta_savings: int = 0

func _ready() -> void:
	# Al arrancar el juego, cargamos el guardado.
	load_game()

func add_savings(amount: int) -> void:
	# Añade ahorro meta y guarda inmediatamente.
	if amount <= 0:
		return
	
	meta_savings += amount
	save_game()

func save_game() -> void:
	# Datos que queremos persistir.
	var data := {
		"meta_savings": meta_savings
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file == null:
		push_error("No se pudo abrir el archivo de guardado para escribir.")
		return
	
	file.store_string(JSON.stringify(data))

func load_game() -> void:
	# Si no existe guardado, empezamos desde cero.
	if not FileAccess.file_exists(SAVE_PATH):
		meta_savings = 0
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	if file == null:
		push_error("No se pudo abrir el archivo de guardado para leer.")
		meta_savings = 0
		return
	
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	
	if typeof(data) == TYPE_DICTIONARY and data.has("meta_savings"):
		meta_savings = int(data["meta_savings"])
	else:
		# Si el archivo está corrupto o no tiene el formato esperado,
		# reiniciamos el progreso para evitar errores.
		meta_savings = 0

func reset_save() -> void:
	# Resetea progreso meta.
	# Más adelante lo llamaremos desde un botón de menú.
	meta_savings = 0
	save_game()
