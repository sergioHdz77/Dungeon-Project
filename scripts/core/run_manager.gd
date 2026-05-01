extends Node

# Señal que avisa cuando empieza una run.
signal run_started

# Señal que avisa cuando termina una run.
# victory será true si el jugador sobrevive hasta el final.
# victory será false si muere antes.
signal run_finished(victory: bool)

# Señal que avisa de cambios en el tiempo.
# La usa Main para actualizar el HUD sin que el HUD calcule nada.
signal time_changed(remaining_time: int, elapsed_time: float)

# Duración total de la run.
# Ahora está en 60 segundos para probar rápido.
# Más adelante podremos subirlo a 600 o 900.
@export var run_duration_seconds: float = 60.0

# Tiempo transcurrido desde que empezó la run.
var run_time: float = 0.0

# Indica si la run ya ha empezado.
var is_started: bool = false

# Indica si la run ya ha terminado.
# Evita terminar la partida dos veces.
var is_finished: bool = false

func _process(delta: float) -> void:
	# Si la run aún no ha empezado, no contamos tiempo.
	if not is_started:
		return
	
	# Si ya terminó, no seguimos procesando.
	if is_finished:
		return
	
	# Sumamos el tiempo del frame actual.
	run_time += delta
	
	# Avisamos a quien esté escuchando, normalmente Main/HUD.
	time_changed.emit(get_remaining_time(), run_time)
	
	# Si se acaba el tiempo, la run termina como victoria.
	if run_time >= run_duration_seconds:
		finish_run(true)

func prepare_run() -> void:
	# Prepara una run nueva pero NO la arranca.
	# Se usa cuando estamos en la pantalla inicial.
	run_time = 0.0
	is_started = false
	is_finished = false
	
	# Emitimos el tiempo inicial para que el HUD pueda mostrar 60s.
	time_changed.emit(get_remaining_time(), run_time)

func start_run() -> void:
	# Arranca una run desde cero.
	run_time = 0.0
	is_started = true
	is_finished = false
	
	# Avisamos de que la run ha empezado.
	run_started.emit()
	
	# Actualizamos el tiempo inicial.
	time_changed.emit(get_remaining_time(), run_time)

func finish_run(victory: bool) -> void:
	# Si ya terminó, no hacemos nada.
	# Esto evita duplicar guardado de ahorro o mostrar dos pantallas finales.
	if is_finished:
		return
	
	is_finished = true
	is_started = false
	
	# Avisamos a Main de que debe cerrar la run.
	run_finished.emit(victory)

func get_remaining_time() -> int:
	# Devuelve el tiempo restante redondeado hacia arriba.
	# Ejemplo: si quedan 3.2 segundos, muestra 4.
	return int(ceil(max(0.0, run_duration_seconds - run_time)))

func get_elapsed_time() -> int:
	# Devuelve el tiempo sobrevivido.
	# Nunca pasa de la duración máxima de la run.
	return int(min(run_time, run_duration_seconds))
