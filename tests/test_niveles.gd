extends Node
## Test: los 7 .tres de capítulo cargan con los valores esperados, el filtro
## de obstáculos no implementados funciona y el desbloqueo es correcto.
##
## Sale con código 1 si algo falla, para que el CI lo detecte.

const ObstacleScript = preload("res://scripts/Obstacle.gd")
const LevelDataClass = preload("res://resources/level_data.gd")

var _fails := 0

func _ready() -> void:
	_test_los_7_niveles_cargan()
	_test_capitulo_1_sin_regresiones()
	_test_se_filtran_tipos_no_implementados()
	_test_desbloqueo_de_capitulos()

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

func _test_los_7_niveles_cargan() -> void:
	print("--- los 7 niveles cargan ---")
	for ch in range(1, 8):
		var d: LevelDataClass = Global.load_level_data(ch)
		if d == null:
			_check(false, "cap %d carga" % ch)
			continue
		var bien := d.chapter_number == ch and not d.chapter_title.is_empty() and d.speed_base > 0.0
		_check(bien, "cap %d: %-24s vel=%d inc=%.1f spawn=%.2f-%.2f" % [
			ch, d.chapter_title, int(d.speed_base), d.speed_increase_rate,
			d.spawn_min, d.spawn_max])
		_check(d.obstacle_types.size() > 0, "cap %d declara obstaculos" % ch)

func _test_capitulo_1_sin_regresiones() -> void:
	print("--- capitulo 1 mantiene sus valores ---")
	var d: LevelDataClass = Global.load_level_data(1)
	if d == null:
		_check(false, "cap 1 carga")
		return
	_check(is_equal_approx(d.speed_base, 400.0), "velocidad base 400")
	_check(is_equal_approx(d.speed_increase_rate, 8.0), "incremento 8")
	_check(is_equal_approx(d.spawn_min, 1.0), "spawn_min 1.0")
	_check(is_equal_approx(d.spawn_max, 2.2), "spawn_max 2.2")
	_check(d.obstacle_weights == [100, 30, 20, 15], "pesos 100/30/20/15")
	_check(d.obstacle_min_scores == [0, 500, 1000, 1500], "desbloqueos 0/500/1000/1500")
	_check(d.uses_background_art, "usa el arte de fondo propio")

func _test_se_filtran_tipos_no_implementados() -> void:
	print("--- los tipos sin implementar se descartan ---")
	# Ningun capitulo puede terminar con la lista de obstaculos vacia: si se
	# filtran todos, el spawner cae al fallback y el nivel pierde sus reglas.
	for ch in range(1, 8):
		var d: LevelDataClass = Global.load_level_data(ch)
		if d == null:
			continue
		var implementados := 0
		for t in d.obstacle_types:
			if ObstacleScript.is_implemented(t):
				implementados += 1
		_check(implementados > 0, "cap %d deja %d de %d tipos" % [
			ch, implementados, d.obstacle_types.size()])
	# Los 5 tipos futuros todavia no existen, asi que ningun capitulo puede
	# usarlos como si estuvieran listos.
	_check(not ObstacleScript.is_implemented(ObstacleScript.Type.BIRD), "BIRD sigue sin implementar")
	_check(not ObstacleScript.is_implemented(ObstacleScript.Type.ICE_FALL), "ICE_FALL sigue sin implementar")

func _test_desbloqueo_de_capitulos() -> void:
	print("--- desbloqueo de capitulos ---")
	Global.unlocked_chapter = 1
	Global.chapter_cleared = {}
	_check(not Global.is_chapter_unlocked(2), "el cap 2 arranca bloqueado")
	Global.mark_chapter_cleared(1)
	_check(Global.is_chapter_unlocked(2), "superar el 1 abre el 2")
	Global.mark_chapter_cleared(2)
	_check(Global.is_chapter_unlocked(3), "superar el 2 abre el 3")
	Global.mark_chapter_cleared(Global.MAX_CHAPTER)
	_check(Global.unlocked_chapter == Global.MAX_CHAPTER, "no pasa del ultimo capitulo")
	Global.mark_chapter_cleared(999)
	_check(Global.unlocked_chapter == Global.MAX_CHAPTER, "capitulos fuera de rango no rompen nada")
