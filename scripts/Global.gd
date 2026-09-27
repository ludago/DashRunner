extends Node
## Autoload (Singleton). Guarda datos que deben sobrevivir entre escenas:
## puntaje, récord y el estado de progreso de los capítulos.

const LevelDataClass = preload("res://resources/level_data.gd")

const MAX_CHAPTER := 7
const LEVEL_PATH_FORMAT := "res://resources/level_%02d.tres"

var last_score: int = 0
var high_score: int = 0

## Progreso de capítulos.
var unlocked_chapter: int = 1
var chapter_cleared: Dictionary = {}
var current_chapter: int = 1
## Caché de los .tres ya cargados, para no releerlos en cada cambio de escena.
var _level_cache: Dictionary = {}

## Carga (y cachea) el LevelData de un capítulo. Devuelve null si el
## capítulo no existe, así el llamador puede decidir qué hacer.
func load_level_data(chapter: int) -> LevelDataClass:
	var key := clampi(chapter, 1, MAX_CHAPTER)
	if _level_cache.has(key):
		return _level_cache[key]
	var path := LEVEL_PATH_FORMAT % key
	var data: LevelDataClass = load(path) if ResourceLoader.exists(path) else null
	if data == null:
		push_warning("No se pudo cargar el nivel del capítulo %d (%s)" % [chapter, path])
	_level_cache[key] = data
	return data

## Fija el capítulo a jugar y devuelve sus datos. Lo usan ChapterSelect,
## ChapterIntro y Game para que todos lean el mismo.
func set_current_chapter(chapter: int) -> LevelDataClass:
	current_chapter = clampi(chapter, 1, MAX_CHAPTER)
	return load_level_data(current_chapter)

func get_current_level_data() -> LevelDataClass:
	return load_level_data(current_chapter)

func is_chapter_unlocked(chapter: int) -> bool:
	return chapter <= unlocked_chapter

func is_chapter_cleared(chapter: int) -> bool:
	return chapter_cleared.get(chapter, false)

## Título para los botones del menú de capítulos, con fallback si el .tres
## no llegara a cargarse.
func chapter_title(chapter: int) -> String:
	var data := load_level_data(chapter)
	if data == null or data.chapter_title.is_empty():
		return "Capítulo %d" % chapter
	return data.chapter_title

## Marca un capítulo como superado y abre el siguiente. Lo llama GameOver al
## terminar un capítulo de historia.
func mark_chapter_cleared(chapter: int) -> void:
	chapter_cleared[chapter] = true
	unlocked_chapter = maxi(unlocked_chapter, min(chapter + 1, MAX_CHAPTER))
