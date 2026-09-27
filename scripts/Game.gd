extends Node2D
## Controla la partida: puntaje, velocidad creciente, fin del juego
## y el desplazamiento del fondo en parallax.

const DashScript = preload("res://scripts/Dash.gd")
const LevelDataClass = preload("res://resources/level_data.gd")

# Sacudida de cámara al chocar.
const SHAKE_STRENGTH := 9.0
const SHAKE_STEPS := 6
const SHAKE_STEP_TIME := 0.045

# Freeze frame: la partida casi se detiene en el instante del impacto.
const FREEZE_TIME := 0.18
const FREEZE_SCALE := 0.05

# Espera entre el fin del freeze y el cambio a Game Over.
const HIT_TO_OVER_DELAY := 0.25

# Latido del HUD cada N puntos, para que se note que el puntaje avanza.
const SCORE_PULSE_STEP := 100
const SCORE_PULSE_TIME := 0.18
const SCORE_PULSE_SCALE := Vector2(1.25, 1.25)

# El título del capítulo sale del .tres y se desvanece a los 3 segundos.
const TITLE_FADE_DELAY := 3.0
const TITLE_FADE_TIME := 1.0

# Detalle del suelo: se genera por código y se desplaza dando la
# sensación de velocidad. El suelo base es un rect estático.
const GROUND_PERIOD := 200.0
const GROUND_MARK_COUNT := 11
const GROUND_MARK_START := -500.0

var score := 0.0
var speed := 400.0
var speed_increase_rate := 8.0
var is_game_over := false
var current_level_data: LevelDataClass = null
var _next_pulse_score := SCORE_PULSE_STEP

@onready var score_label: Label = $UI/ScoreLabel
@onready var chapter_title_label: Label = $UI/ChapterTitle
@onready var background: ParallaxBackground = $Background
@onready var sky_fallback: ColorRect = $SkyFallbackLayer/SkyFallback
@onready var ground_visual: Polygon2D = $Ground/GroundVisual
@onready var camera: Camera2D = $Camera2D
@onready var dash: DashScript = $Dash
@onready var ground_detail: Node2D = $Ground/GroundScroll

func _ready() -> void:
	_apply_level_data()
	_build_ground_detail()

## Aplica las reglas del capítulo actual. Todo lo que antes estaba hardcodeado
## (velocidad, colores, título) sale de aquí, así Game.tscn sirve para los 7.
func _apply_level_data() -> void:
	current_level_data = Global.get_current_level_data()
	if current_level_data == null:
		push_warning("Sin LevelData para el capítulo %d, se usan valores por defecto" % Global.current_chapter)
		return
	speed = current_level_data.speed_base
	speed_increase_rate = current_level_data.speed_increase_rate
	sky_fallback.color = current_level_data.background_color
	ground_visual.color = current_level_data.ground_color
	# Los capítulos sin arte propio muestran el color plano del cielo en vez
	# de las colinas del capítulo 1, que no les corresponden.
	background.visible = current_level_data.uses_background_art
	_show_chapter_title()

func _show_chapter_title() -> void:
	var data := current_level_data
	if data == null:
		chapter_title_label.text = "Capítulo %d" % Global.current_chapter
	else:
		chapter_title_label.text = "CAPÍTULO %d — %s" % [data.chapter_number, data.chapter_title]
	var tween := create_tween()
	tween.tween_interval(TITLE_FADE_DELAY)
	tween.tween_property(chapter_title_label, "modulate:a", 0.0, TITLE_FADE_TIME)

func _process(delta: float) -> void:
	if is_game_over:
		return
	score += delta * 10.0
	speed += speed_increase_rate * delta
	score_label.text = "Puntos: %d" % int(score)
	_check_score_pulse()

	# Mueve el fondo. Cada ParallaxLayer tiene su propio motion_scale,
	# así que las capas más "lejanas" (sky/clouds) se desplazan mucho
	# menos que las capas cercanas (hills_near), dando sensación de
	# profundidad respecto al suelo y los obstáculos, que se mueven a
	# velocidad completa ("speed").
	background.scroll_offset.x -= speed * delta
	_scroll_ground_detail(delta)

func on_dash_hit() -> void:
	if is_game_over:
		return
	is_game_over = true
	Global.last_score = int(score)
	if Global.last_score > Global.high_score:
		Global.high_score = Global.last_score
	_play_hit_sequence()

## Secuencia de impacto: parpadeo en Dash, freeze frame y sacudida de
## cámara antes de pasar a Game Over. Las esperas ignoran
## Engine.time_scale para que el efecto dure lo mismo con el juego congelado.
func _play_hit_sequence() -> void:
	dash.flash_hit()
	Engine.time_scale = FREEZE_SCALE
	_shake_camera()
	await get_tree().create_timer(FREEZE_TIME, true, false, true).timeout
	Engine.time_scale = 1.0
	await get_tree().create_timer(HIT_TO_OVER_DELAY, true, false, true).timeout
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

## Sacudida aleatoria de la cámara. Se dispara sin esperar: corre en
## paralelo mientras la partida está congelada.
func _shake_camera() -> void:
	for i in SHAKE_STEPS:
		camera.offset = Vector2(
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH),
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH)
		)
		await get_tree().create_timer(SHAKE_STEP_TIME, true, false, true).timeout
	camera.offset = Vector2.ZERO

## Dispara el latido del HUD al cruzar cada múltiplo de SCORE_PULSE_STEP.
func _check_score_pulse() -> void:
	if int(score) < _next_pulse_score:
		return
	_next_pulse_score += SCORE_PULSE_STEP
	_pulse_score_label()

func _pulse_score_label() -> void:
	score_label.pivot_offset = score_label.size / 2.0
	score_label.scale = SCORE_PULSE_SCALE
	var tween := create_tween()
	tween.tween_property(score_label, "scale", Vector2.ONE, SCORE_PULSE_TIME)

## Genera piedras y matas de pasto repetidas a lo largo del suelo.
## Se hace por código en vez de editar la escena a mano para no
## depender de sub-recursos embebidos en el .tscn.
func _build_ground_detail() -> void:
	for i in GROUND_MARK_COUNT:
		var marca := Polygon2D.new()
		var alto := randf_range(7.0, 13.0)
		var ancho := randf_range(12.0, 24.0)
		if randf() < 0.4:
			# Mata de pasto: triángulo verde pegado al suelo.
			marca.polygon = PackedVector2Array([
				Vector2(-ancho / 2.0, 0), Vector2(ancho / 2.0, 0), Vector2(0, -alto * 2.2),
			])
			marca.color = Color(0.29, 0.52, 0.22, 1.0)
			marca.position = Vector2(
				GROUND_MARK_START + i * GROUND_PERIOD, randf_range(-18.0, -14.0)
			)
		else:
			# Piedra: rectángulo marrón oscuro apenas asomando.
			marca.polygon = PackedVector2Array([
				Vector2(-ancho / 2.0, 0),
				Vector2(ancho / 2.0, 0),
				Vector2(ancho / 2.0 - 2.0, -alto),
				Vector2(-ancho / 2.0 + 2.0, -alto),
			])
			marca.color = Color(0.42, 0.26, 0.15, 1.0)
			marca.position = Vector2(
				GROUND_MARK_START + i * GROUND_PERIOD, randf_range(-8.0, -1.0)
			)
		ground_detail.add_child(marca)

## Desplaza el detalle del suelo a velocidad completa. Como las marcas
## están separadas exactamente GROUND_PERIOD, al sumar un periodo el
## patrón se repite sin costura visible.
func _scroll_ground_detail(delta: float) -> void:
	ground_detail.position.x -= speed * delta
	if ground_detail.position.x <= -GROUND_PERIOD:
		ground_detail.position.x += GROUND_PERIOD
