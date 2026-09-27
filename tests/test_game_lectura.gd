extends Node
## Prueba temporal de Fase 0 (parte 2): Game y el spawner leen el LevelData.

const LevelDataClass = preload("res://resources/level_data.gd")
const GameScript = preload("res://scripts/Game.gd")
const ObstacleSpawnerScript = preload("res://scripts/ObstacleSpawner.gd")

func _ready() -> void:
	print("--- Game lee el nivel segun el capitulo ---")
	var game_scene: PackedScene = load("res://scenes/Game.tscn")
	for ch in [1, 4, 6, 7]:
		Global.set_current_chapter(ch)
		var game: GameScript = game_scene.instantiate()
		add_child(game)
		await get_tree().process_frame
		var spawner: ObstacleSpawnerScript = game.get_node("ObstacleSpawner")
		print("  cap %d -> speed=%.0f inc=%.1f" % [ch, game.speed, game.speed_increase_rate])
		print("       titulo = '%s'" % game.chapter_title_label.text)
		print("       cielo  = %s   suelo = %s   parallax = %s" % [
			str(game.sky_fallback.color), str(game.ground_visual.color),
			str(game.background.visible)])
		print("       spawner tipos=%s pesos=%s min=%s int=%.2f-%.2f" % [
			str(spawner._types), str(spawner._weights), str(spawner._min_scores),
			spawner._spawn_min, spawner._spawn_max])
		game.queue_free()
		await get_tree().process_frame

	print("--- el spawner efectivamente genera los tipos declarados ---")
	Global.set_current_chapter(6)
	var g2: GameScript = game_scene.instantiate()
	add_child(g2)
	await get_tree().process_frame
	var sp2: ObstacleSpawnerScript = g2.get_node("ObstacleSpawner")
	var vistos := {}
	var obst_scene: PackedScene = sp2.obstacle_scene
	for i in 400:
		var o = obst_scene.instantiate()
		var t: int = sp2._pick_type(randi() % 3000)
		vistos[t] = int(vistos.get(t, 0)) + 1
		o.free()
	var orden := vistos.keys()
	orden.sort()
	var salida := ""
	for t in orden:
		salida += "tipo %d x%d  " % [t, vistos[t]]
	print("  cap 6 con puntaje alto -> %s" % salida)
	print("  (solo deben aparecer 0,1,2,3: los 4 implementados)")
	g2.queue_free()
	await get_tree().process_frame

	print("PARTE 2 OK")
	get_tree().quit()
