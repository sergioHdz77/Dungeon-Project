extends CanvasLayer

# HUD principal de la partida.
# Solo muestra datos; no calcula gameplay.
# Main le pasa el Player, el tiempo restante y el ahorro meta.

var time_label: Label
var level_label: Label
var kills_label: Label
var coins_label: Label
var savings_label: Label
var meta_savings_label: Label
var damage_label: Label
var aura_label: Label

var health_bar: ProgressBar
var xp_bar: ProgressBar

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
	root.offset_right = 340
	root.offset_bottom = 300
	add_child(root)
	
	# Panel de fondo del HUD.
	var panel := PanelContainer.new()
	root.add_child(panel)
	
	# Margen interno para que el texto no toque el borde.
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	# Lista vertical de elementos del HUD.
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(time_label)
	
	level_label = Label.new()
	vbox.add_child(level_label)
	
	var health_text := Label.new()
	health_text.text = "Vida"
	vbox.add_child(health_text)
	
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(280, 18)
	health_bar.show_percentage = false
	vbox.add_child(health_bar)
	
	var xp_text := Label.new()
	xp_text.text = "Experiencia"
	vbox.add_child(xp_text)
	
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(280, 14)
	xp_bar.show_percentage = false
	vbox.add_child(xp_bar)
	
	kills_label = Label.new()
	vbox.add_child(kills_label)
	
	coins_label = Label.new()
	vbox.add_child(coins_label)
	
	savings_label = Label.new()
	vbox.add_child(savings_label)
	
	meta_savings_label = Label.new()
	vbox.add_child(meta_savings_label)
	
	damage_label = Label.new()
	vbox.add_child(damage_label)
	
	aura_label = Label.new()
	vbox.add_child(aura_label)

func update_hud(player: Node, remaining_time: int, meta_savings: int) -> void:
	# Seguridad: si la UI todavía no se ha construido, no actualizamos.
	if health_bar == null or xp_bar == null:
		return
	
	var aura_text: String = "No"
	
	if player.get_aura_level() > 0:
		aura_text = "Nv %s - %s DPS" % [
			player.get_aura_level(),
			int(player.get_aura_damage_per_second())
		]
	
	time_label.text = "Tiempo: %ss" % remaining_time
	level_label.text = "Nivel: %s" % player.get_level()
	kills_label.text = "Kills: %s" % player.get_enemies_killed()
	coins_label.text = "Monedas run: %s" % player.get_run_coins()
	savings_label.text = "Ahorro run: %s" % player.get_run_savings()
	meta_savings_label.text = "Ahorro meta: %s" % meta_savings
	
	damage_label.text = "Daño: %s | Proyectiles: %s" % [
		int(player.get_attack_damage()),
		player.get_projectile_count()
	]
	
	aura_label.text = "Aura: %s" % aura_text
	
	# Barras numéricas.
	health_bar.max_value = player.get_max_health()
	health_bar.value = player.get_health()
	
	xp_bar.max_value = player.get_xp_to_next_level()
	xp_bar.value = player.get_xp()
