extends Control
## Pantalla de introducción del capítulo. El título y el texto salen del
## LevelData del capítulo actual, así no hay que editar la escena por capítulo.

@onready var title_label: Label = $CenterContainer/VBoxContainer/ChapterTitle
@onready var name_label: Label = $CenterContainer/VBoxContainer/ChapterName
@onready var narrative_label: RichTextLabel = $CenterContainer/VBoxContainer/NarrativeText
@onready var continue_btn: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var skip_btn: Button = $CenterContainer/VBoxContainer/SkipButton

func _ready() -> void:
	_apply_level_data()
	continue_btn.grab_focus()

func _apply_level_data() -> void:
	var data := Global.get_current_level_data()
	if data == null:
		title_label.text = "CAPÍTULO %d" % Global.current_chapter
		name_label.text = Global.chapter_title(Global.current_chapter)
		return
	title_label.text = "CAPÍTULO %d" % data.chapter_number
	name_label.text = data.chapter_title.to_upper()
	# El .tres guarda el texto con saltos de línea simples; el RichTextLabel
	# los convierte en párrafos para que no dependa del ancho de la caja.
	narrative_label.text = "[center]%s[/center]" % data.narrative.replace("\n", "\n\n")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
