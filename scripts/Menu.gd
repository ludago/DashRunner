extends Control
## Menú principal. "Jugar" abre la selección de capítulo y "Continuar" salta
## directo al último capítulo desbloqueado.

@onready var continue_btn: Button = $CenterContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	# "Continuar" solo tiene sentido si ya se desbloqueó algo más que el cap. 1.
	continue_btn.visible = Global.unlocked_chapter > 1
	$CenterContainer/VBoxContainer/PlayButton.grab_focus()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ChapterSelect.tscn")

func _on_continue_pressed() -> void:
	_start_chapter(Global.unlocked_chapter)

func _start_chapter(chapter: int) -> void:
	Global.set_current_chapter(chapter)
	get_tree().change_scene_to_file("res://scenes/ChapterIntro.tscn")
