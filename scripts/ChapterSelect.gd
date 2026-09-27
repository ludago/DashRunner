extends Control
## Selección de capítulo. Muestra los 7 capítulos; los que todavía no se
## desbloquearon aparecen con candado y no se pueden entrar.

@onready var grid: GridContainer = $Margin/VBox/Scroll/Grid
@onready var back_btn: Button = $Margin/VBox/BackButton

func _ready() -> void:
	for chapter in range(1, Global.MAX_CHAPTER + 1):
		grid.add_child(_make_chapter_button(chapter))
	back_btn.grab_focus()

func _make_chapter_button(chapter: int) -> Button:
	var unlocked := Global.is_chapter_unlocked(chapter)
	var cleared := Global.is_chapter_cleared(chapter)
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 74)
	button.disabled = not unlocked
	button.text = _button_text(chapter, unlocked, cleared)
	button.tooltip_text = Global.chapter_title(chapter)
	if unlocked:
		button.pressed.connect(_on_chapter_pressed.bind(chapter))
	return button

func _button_text(chapter: int, unlocked: bool, cleared: bool) -> String:
	if not unlocked:
		return "Capítulo %d — Bloqueado" % chapter
	var status := "✓ Completado" if cleared else "Jugar"
	return "Capítulo %d — %s\n%s" % [chapter, Global.chapter_title(chapter), status]

func _on_chapter_pressed(chapter: int) -> void:
	Global.set_current_chapter(chapter)
	get_tree().change_scene_to_file("res://scenes/ChapterIntro.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
