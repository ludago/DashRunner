extends Node
## Prueba temporal de Fase 0 (parte 1): carga de los .tres y filtro de tipos.

const ObstacleScript = preload("res://scripts/Obstacle.gd")
const LevelDataClass = preload("res://resources/level_data.gd")

func _ready() -> void:
	print("--- carga de los 7 niveles ---")
	var fails := 0
	for ch in range(1, 8):
		var d: LevelDataClass = Global.load_level_data(ch)
		if d == null:
			print("  FALLO cap %d no cargo" % ch)
			fails += 1
			continue
		print("  cap %d: %-24s vel=%d inc=%.1f spawn=%.2f-%.2f arte=%s obst=%s" % [
			d.chapter_number, d.chapter_title, int(d.speed_base), d.speed_increase_rate,
			d.spawn_min, d.spawn_max, str(d.uses_background_art), str(d.obstacle_types)])

	print("--- filtro de tipos no implementados ---")
	for ch in range(1, 8):
		var d: LevelDataClass = Global.load_level_data(ch)
		var decl: int = d.obstacle_types.size()
		var util := 0
		for t in d.obstacle_types:
			if ObstacleScript.is_implemented(t):
				util += 1
		print("  cap %d: declara %d, implementados %d, descartados %d" % [ch, decl, util, decl - util])

	print("--- desbloqueo de capitulos ---")
	Global.unlocked_chapter = 1
	Global.chapter_cleared = {}
	print("  cap 2 al inicio? %s (espera False)" % str(Global.is_chapter_unlocked(2)))
	Global.mark_chapter_cleared(1)
	print("  tras superar 1 -> cap 2? %s (espera True)" % str(Global.is_chapter_unlocked(2)))
	Global.mark_chapter_cleared(99)
	print("  tope al marcar 99 -> unlocked=%d (espera 7)" % Global.unlocked_chapter)

	print("RESULTADO: %s" % ("TODO OK" if fails == 0 else "%d FALLOS" % fails))
	get_tree().quit()
