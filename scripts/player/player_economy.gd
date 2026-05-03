extends Node

signal economy_changed

var run_coins: int = 0
var run_savings: int = 0
var total_coins_collected: int = 0

func add_coins(amount: int) -> void:
	if amount <= 0:
		return

	run_coins += amount
	total_coins_collected += amount
	economy_changed.emit()

func try_secure_savings(cost: int, amount: int) -> bool:
	if cost <= 0 or amount <= 0:
		return false

	if run_coins < cost:
		return false

	run_coins -= cost
	run_savings += amount
	SaveManager.add_savings(amount)

	economy_changed.emit()
	return true

func reset() -> void:
	run_coins = 0
	run_savings = 0
	total_coins_collected = 0
	economy_changed.emit()
