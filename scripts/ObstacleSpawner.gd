extends Node2D
## Genera obstáculos a intervalos aleatorios y les asigna la velocidad
## actual del juego (tomada de Game.gd) para que la dificultad escale.
##
## Los tipos, pesos, puntajes de desbloqueo y el intervalo salen del
## LevelData del capítulo, así este script no cambia entre capítulos.

const ObstacleScript = preload("res://scripts/Obstacle.gd")
const LevelDataClass = preload("res://resources/level_data.gd")

@export var obstacle_scene: PackedScene

@onready var timer: Timer = $Timer
@onready var game: Node2D = get_parent()

# Fallback por si el capítulo no trae datos: reproduce la progresión del
# capítulo 1 para que el nivel siga siendo jugable.
const FALLBACK_TYPES: Array[int] = [
	ObstacleScript.Type.ROCK_LOW,
	ObstacleScript.Type.ROCK_HIGH,
	ObstacleScript.Type.LOG_TUNNEL,
	ObstacleScript.Type.BUSH,
]
const FALLBACK_WEIGHTS: Array[int] = [100, 30, 20, 15]
const FALLBACK_MIN_SCORES: Array[int] = [0, 500, 1000, 1500]
const FALLBACK_SPAWN_MIN := 1.0
const FALLBACK_SPAWN_MAX := 2.2

# Tabla efectiva del capítulo, ya filtrada a los tipos implementados.
var _types: Array[int] = []
var _weights: Array[int] = []
var _min_scores: Array[int] = []
var _spawn_min := 1.0
var _spawn_max := 2.2

func _ready() -> void:
	randomize()
	_load_chapter_rules()
	timer.timeout.connect(_on_timer_timeout)
	_schedule_next()
	timer.start()

## Copia las reglas del LevelData a los arrays del spawner. Los tipos que el
## juego todavía no sabe construir se descartan acá, así un capítulo puede
## listar los obstáculos que le tocan aunque falten por implementar.
func _load_chapter_rules() -> void:
	var data: LevelDataClass = _read_level_data()
	if data == null:
		_types = FALLBACK_TYPES.duplicate()
		_weights = FALLBACK_WEIGHTS.duplicate()
		_min_scores = FALLBACK_MIN_SCORES.duplicate()
		_spawn_min = FALLBACK_SPAWN_MIN
		_spawn_max = FALLBACK_SPAWN_MAX
		return

	_spawn_min = data.spawn_min
	_spawn_max = data.spawn_max
	_types.clear()
	_weights.clear()
	_min_scores.clear()
	for i in data.obstacle_types.size():
		var type := data.obstacle_types[i]
		if not ObstacleScript.is_implemented(type):
			continue
		_types.append(type)
		_weights.append(_value_or(data.obstacle_weights, i, 1))
		_min_scores.append(_value_or(data.obstacle_min_scores, i, 0))

	if _types.is_empty():
		push_warning("El capítulo %d no tiene obstáculos implementados, se usa ROCK_LOW" % data.chapter_number)
		_types = [ObstacleScript.Type.ROCK_LOW]
		_weights = [1]
		_min_scores = [0]

func _read_level_data() -> LevelDataClass:
	# Se lee del autoload y no de Game.current_level_data a propósito: los
	# nodos hijos ejecutan su _ready() antes que el padre, así que cuando este
	# script corre Game todavía no cargó el LevelData. Global ya lo tiene
	# cacheado, así que no cuesta nada.
	return Global.get_current_level_data()

func _value_or(source: Array[int], index: int, fallback: int) -> int:
	return source[index] if index < source.size() else fallback

func _schedule_next() -> void:
	timer.wait_time = randf_range(_spawn_min, maxf(_spawn_min, _spawn_max))

func _on_timer_timeout() -> void:
	_spawn_obstacle()
	_schedule_next()
	timer.start()

func _spawn_obstacle() -> void:
	if obstacle_scene == null:
		return
	var obstacle = obstacle_scene.instantiate()
	obstacle.position = position
	obstacle.speed = game.speed
	obstacle.obstacle_type = _pick_type(int(game.score))
	obstacle.hit_dash.connect(game.on_dash_hit)
	get_parent().add_child(obstacle)

## Elige tipo por peso entre los que ya superaron su puntaje de desbloqueo.
func _pick_type(current_score: int) -> int:
	var total_weight := 0
	for i in _types.size():
		if current_score >= _min_scores[i]:
			total_weight += _weights[i]
	if total_weight <= 0:
		return _types[0]

	var roll := randi() % total_weight
	var acc := 0
	for i in _types.size():
		if current_score < _min_scores[i]:
			continue
		acc += _weights[i]
		if roll < acc:
			return _types[i]
	return _types[0]
