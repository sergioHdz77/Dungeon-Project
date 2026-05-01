extends Node

# Señal que avisa cuando cambia cualquier dato económico.
# Player la escucha para emitir stats_changed y actualizar el HUD.
signal economy_changed

# Monedas temporales de la run actual.
# Se pierden si no se convierten en ahorro.
var run_coins: int = 0

# Ahorro asegurado durante esta run.
# Este valor sí se guarda como meta-progreso al terminar la run.
var run_savings: int = 0

# Total de monedas recogidas durante la run.
# Solo se usa para estadísticas de pantalla final.
var total_coins_collected: int = 0

# Dinero pasivo por segundo.
# Lo usa la mejora "Becario en cárnica".
var passive_coin_per_second: float = 0.0

# Acumulador interno para convertir dinero pasivo decimal en monedas enteras.
var passive_coin_accumulator: float = 0.0

func add_coins(amount: int) -> void:
	# Ignoramos cantidades inválidas.
	if amount <= 0:
		return
	
	run_coins += amount
	total_coins_collected += amount
	
	# Avisamos de que el HUD debe actualizarse.
	economy_changed.emit()

func try_secure_savings(cost: int, amount: int) -> bool:
	# Intenta convertir monedas de run en ahorro asegurado.
	# Devuelve true si se pudo hacer, false si no había suficientes monedas.
	if run_coins < cost:
		return false
	
	run_coins -= cost
	run_savings += amount
	
	economy_changed.emit()
	return true

func apply_passive_income(delta: float) -> void:
	# Si no hay ingreso pasivo, no hacemos nada.
	if passive_coin_per_second <= 0.0:
		return
	
	# Sumamos el dinero generado durante este frame.
	passive_coin_accumulator += passive_coin_per_second * delta
	
	# Solo añadimos monedas cuando el acumulador llega al menos a 1.
	# Así evitamos monedas decimales en el contador.
	if passive_coin_accumulator >= 1.0:
		var coins_to_add: int = int(passive_coin_accumulator)
		
		run_coins += coins_to_add
		total_coins_collected += coins_to_add
		passive_coin_accumulator -= coins_to_add
		
		economy_changed.emit()

func add_passive_coin_rate(amount: float) -> void:
	# Aumenta la cantidad de monedas pasivas por segundo.
	passive_coin_per_second += amount
	economy_changed.emit()

func reset() -> void:
	# Reinicia todos los datos económicos de la run.
	# De momento no se usa mucho porque recargamos la escena al empezar otra run.
	run_coins = 0
	run_savings = 0
	total_coins_collected = 0
	passive_coin_per_second = 0.0
	passive_coin_accumulator = 0.0
	
	economy_changed.emit()
