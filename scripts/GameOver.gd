extends Control

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var high_score_label: Label = $CenterContainer/VBoxContainer/HighScoreLabel

func _ready() -> void:
	score_label.text = "Puntaje: %d" % Global.last_score
	high_score_label.text = "Récord: %d" % Global.high_score

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
