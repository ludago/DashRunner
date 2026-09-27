class_name LevelData
extends Resource
## Reglas de un capítulo. Cada capítulo es un `.tres` con estos valores,
## así `Game.tscn` es uno solo genérico y no hay que duplicar la escena
## por cada capítulo.
##
## Los tres arrays de obstáculos van alineados por índice:
##   obstacle_types[i]        → qué tipo es
##   obstacle_weights[i]      → probabilidad relativa (opcional)
##   obstacle_min_scores[i]   → puntaje mínimo para aparecer (opcional)
## Si faltan pesos o mínimos, el spawner usa peso 1 y mínimo 0.

@export var chapter_number: int = 1
@export var chapter_title: String = ""
@export var narrative: String = ""

@export_group("Dificultad")
@export var speed_base: float = 400.0
@export var speed_increase_rate: float = 8.0
@export var spawn_min: float = 1.0
@export var spawn_max: float = 2.2

@export_group("Ambiente")
## Color de cielo de respaldo, se ve cuando el capítulo todavía no tiene
## arte de fondo propio (uses_background_art = false).
@export var background_color: Color = Color(0.53, 0.81, 0.92)
@export var ground_color: Color = Color(0.55, 0.35, 0.2)
## false = oculta las capas de parallax y queda solo el color plano,
## para los capítulos cuyo arte de fondo todavía no se produjo.
@export var uses_background_art: bool = true

@export_group("Obstáculos")
@export var obstacle_types: Array[int] = []
@export var obstacle_weights: Array[int] = []
@export var obstacle_min_scores: Array[int] = []

@export_group("Final")
## Cap. 7 = tramo con final definido en vez de runner infinito.
@export var is_story_chapter: bool = false
@export var target_score: int = 0
