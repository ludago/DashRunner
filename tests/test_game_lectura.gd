extends Node
## Test: Game.gd y ObstacleSpawner.gd toman sus valores del LevelData del
## capítulo, y Game.tscn sirve para los 7 sin tocar código.
##
## Sale con código 1 si algo falla, para que el CI lo detecte.

const LevelDataClass = preload("res://resources/level_data.gd")
const GameScript = preload("res://scripts/Game.gd")
const ObstacleScript = preload("res://scripts/Obstacle.gd")
const ObstacleSpawnerScript = preload("res://scripts/ObstacleSpawner.gd")

var _fails := 0

func _ready() -> void:
	_test_game_toma_el_level_data()
	_test_spawner_toma_el_level_data()
	_test_el_spawner_solo_genera_tipos_implementados()

	print("--- resultado ---")
	if _fails == 0:
		print("RESULTADO: TODO OK")
		get_tree().quit(0)
	else:
		printerr("RESULTADO: %d FALLO(S)" % _fails)
		get_tree().quit(1)

func _check(ok: bool, mensaje: String) -> void:
	if ok:
		print("  ok   %s" % mensaje)
	else:
		_fails += 1
		printerr("  FALLO %s" % mensaje)

func _test_game_toma_el_level_data() -> void:
	print("--- Game lee velocidad, titulo y paleta del .tres ---")
	var escena: PackedScene = load("res://scenes/Game.tscn")
	for ch in [1, 4, 6, 7]:
		var datos: LevelDataClass = Global.load_level_data(ch)
		Global.set_current_chapter(ch)
		var game: GameScript = escena.instantiate()
		add_child(game)
		await get_tree().process_frame

		_check(is_equal_approx(game.speed, datos.speed_base), "cap %d velocidad %.0f" % [ch, datos.speed_base])
		_check(is_equal_approx(game.speed_increase_rate, datos.speed_increase_rate), "cap %d incremento %.1f" % [ch, datos.speed_increase_rate])
		_check(game.chapter_title_label.text.contains(datos.chapter_title), "cap %d titulo en el HUD" % ch)
		_check(game.sky_fallback.color.is_equal_approx(datos.background_color), "cap %d color de cielo" % ch)
		_check(game.ground_visual.color.is_equal_approx(datos.ground_color), "cap %d color de suelo" % ch)
		_check(game.background.visible == datos.uses_background_art, "cap %d visibilidad del parallax" % ch)

		game.queue_free()
		await get_tree().process_frame

func _test_spawner_toma_el_level_data() -> void:
	print("--- El spawner toma tipos, pesos e intervalo del .tres ---")
	var escena: PackedScene = load("res://scenes/Game.tscn")
	for ch in [1, 4, 6, 7]:
		var datos: LevelDataClass = Global.load_level_data(ch)
		Global.set_current_chapter(ch)
		var game: GameScript = escena.instantiate()
		add_child(game)
		await get_tree().process_frame
		var spawner: ObstacleSpawnerScript = game.get_node("ObstacleSpawner")

		_check(is_equal_approx(spawner._spawn_min, datos.spawn_min), "cap %d spawn_min %.2f" % [ch, datos.spawn_min])
		_check(is_equal_approx(spawner._spawn_max, datos.spawn_max), "cap %d spawn_max %.2f" % [ch, datos.spawn_max])
		# El cap. 1 tiene que conservar sus 4 obstaculos con el gating por
		# puntaje original; es el que el jugador ya conoce.
		if ch == 1:
			_check(spawner._types == [0, 1, 2, 3], "cap 1 conserva los 4 tipos")
			_check(spawner._min_scores == [0, 500, 1000, 1500], "cap 1 conserva los desbloqueos")
		_check(spawner._types.size() > 0, "cap %d tiene al menos un tipo" % ch)
		_check(spawner._types.size() == spawner._weights.size(), "cap %d tipos y pesos alineados" % ch)
		_check(spawner._types.size() == spawner._min_scores.size(), "cap %d tipos y minimos alineados" % ch)

		game.queue_free()
		await get_tree().process_frame

func _test_el_spawner_solo_genera_tipos_implementados() -> void:
	print("--- Con puntaje alto solo aparecen tipos implementados ---")
	Global.set_current_chapter(6)
	var escena: PackedScene = load("res://scenes/Game.tscn")
	var game: GameScript = escena.instantiate()
	add_child(game)
	await get_tree().process_frame
	var spawner: ObstacleSpawnerScript = game.get_node("ObstacleSpawner")

	var vistos := {}
	for i in 500:
		vistos[spawner._pick_type(randi() % 3000)] = true
	_check(vistos.size() > 1, "el cap 6 genera mas de un tipo (%d)" % vistos.size())
	for tipo in vistos.keys():
		_check(ObstacleScript.is_implemented(tipo), "el tipo %d esta implementado" % tipo)

	game.queue_free()
	await get_tree().process_frame
