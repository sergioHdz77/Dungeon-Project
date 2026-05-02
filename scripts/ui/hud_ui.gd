extends CanvasLayer

# HUD principal de la partida.
# Solo muestra datos; no calcula gameplay.
#
# Este HUD ya está adaptado al nuevo roguelite dungeon crawler.
# Mantiene la firma antigua de update_hud(player, remaining_time, meta_savings)
# para no tener que tocar Main todavía, pero ignora remaining_time y meta_savings.

var title_label: Label = null
var difficulty_label: Label = null
var level_label: Label = null
var kills_label: Label = null
var run_gold_label: Label = null
var weapon_label: Label = null
var damage_label: Label = null
var block_label: Label = null

var health_value_label: Label = null
var stamina_value_label: Label = null
var xp_value_label: Label = null

var health_bar: ProgressBar = null
var stamina_bar: ProgressBar = null
var xp_bar: ProgressBar = null


func _ready() -> void:
	# Asegura que el HUD se dibuje por encima del juego.
	layer = 10
	
	# Permite que el HUD siga activo incluso si el árbol está pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	build_ui()


func build_ui() -> void:
	# Contenedor base anclado arriba a la izquierda.
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.offset_left = 16
	root.offset_top = 16
	root.offset_right = 360
	root.offset_bottom = 380
	add_child(root)
	
	# Panel de fondo del HUD.
	var panel := PanelContainer.new()
	root.add_child(panel)
	
	# Margen interno.
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	# Lista vertical de elementos.
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	title_label = Label.new()
	title_label.text = "Dungeon Run"
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)

	difficulty_label = Label.new()
	difficulty_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(difficulty_label)
	
	level_label = Label.new()
	vbox.add_child(level_label)
	
	# Vida.
	health_value_label = Label.new()
	vbox.add_child(health_value_label)
	
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(300, 18)
	health_bar.show_percentage = false
	vbox.add_child(health_bar)
	
	# Stamina.
	stamina_value_label = Label.new()
	vbox.add_child(stamina_value_label)
	
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(300, 14)
	stamina_bar.show_percentage = false
	vbox.add_child(stamina_bar)
	
	# Experiencia.
	xp_value_label = Label.new()
	vbox.add_child(xp_value_label)
	
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(300, 14)
	xp_bar.show_percentage = false
	vbox.add_child(xp_bar)
	
	kills_label = Label.new()
	vbox.add_child(kills_label)
	
	run_gold_label = Label.new()
	vbox.add_child(run_gold_label)
	
	weapon_label = Label.new()
	vbox.add_child(weapon_label)
	
	damage_label = Label.new()
	vbox.add_child(damage_label)
	
	block_label = Label.new()
	vbox.add_child(block_label)


func update_hud(
	player: Node,
	_remaining_time: int,
	_meta_savings: int,
	current_difficulty: int = 1
) -> void:
	# Seguridad: si la UI todavía no se ha construido, no actualizamos.
	if health_bar == null or stamina_bar == null or xp_bar == null:
		return
	
	if player == null:
		return
	
	var level: int = _get_int_from_player(player, "get_level", 1)
	var kills: int = _get_int_from_player(player, "get_enemies_killed", 0)
	var run_gold: int = _get_int_from_player(player, "get_run_coins", 0)
	
	var health: float = _get_float_from_player(player, "get_health", 0.0)
	var max_health: float = _get_float_from_player(player, "get_max_health", 1.0)
	
	var xp: float = _get_float_from_player(player, "get_xp", 0.0)
	var xp_to_next: float = _get_float_from_player(player, "get_xp_to_next_level", 1.0)
	
	var stamina: float = _get_stamina(player)
	var max_stamina: float = _get_max_stamina(player)
	
	var damage: float = _get_float_from_player(player, "get_attack_damage", 0.0)
	var weapon_name: String = _get_string_from_player(player, "get_equipped_weapon_name", "Sin arma")
	var is_blocking: bool = _get_is_blocking(player)

	difficulty_label.text = "Dificultad: %s" % current_difficulty
	
	level_label.text = "Nivel: %s" % level
	kills_label.text = "Enemigos eliminados: %s" % kills
	run_gold_label.text = "Oro run: %s" % run_gold
	
	weapon_label.text = "Arma: %s" % weapon_name
	damage_label.text = "Daño: %s" % int(damage)
	
	if is_blocking:
		block_label.text = "Bloqueo: activo"
	else:
		block_label.text = "Bloqueo: no"
	
	# Vida.
	health_bar.max_value = maxf(max_health, 1.0)
	health_bar.value = clampf(health, 0.0, health_bar.max_value)
	health_value_label.text = "Vida: %s / %s" % [
		int(health),
		int(max_health)
	]
	
	# Stamina.
	stamina_bar.max_value = maxf(max_stamina, 1.0)
	stamina_bar.value = clampf(stamina, 0.0, stamina_bar.max_value)
	stamina_value_label.text = "Stamina: %s / %s" % [
		int(stamina),
		int(max_stamina)
	]
	
	# Experiencia.
	xp_bar.max_value = maxf(xp_to_next, 1.0)
	xp_bar.value = clampf(xp, 0.0, xp_bar.max_value)
	xp_value_label.text = "XP: %s / %s" % [
		int(xp),
		int(xp_to_next)
	]


func _get_int_from_player(player: Node, method_name: String, default_value: int) -> int:
	if player != null and player.has_method(method_name):
		return int(player.call(method_name))
	
	return default_value


func _get_float_from_player(player: Node, method_name: String, default_value: float) -> float:
	if player != null and player.has_method(method_name):
		return float(player.call(method_name))
	
	return default_value


func _get_string_from_player(player: Node, method_name: String, default_value: String) -> String:
	if player != null and player.has_method(method_name):
		return str(player.call(method_name))
	
	return default_value


func _get_player_combat(player: Node) -> Node:
	if player == null:
		return null
	
	return player.get_node_or_null("Combat")


func _get_stamina(player: Node) -> float:
	var combat: Node = _get_player_combat(player)
	
	if combat != null and combat.has_method("get_stamina"):
		return float(combat.call("get_stamina"))
	
	return 0.0


func _get_max_stamina(player: Node) -> float:
	var combat: Node = _get_player_combat(player)
	
	if combat != null and combat.has_method("get_max_stamina"):
		return float(combat.call("get_max_stamina"))
	
	return 1.0


func _get_is_blocking(player: Node) -> bool:
	var combat: Node = _get_player_combat(player)
	
	if combat == null:
		return false
	
	if "is_blocking" in combat:
		return bool(combat.is_blocking)
	
	return false
