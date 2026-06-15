extends Control

@onready var p2_panel: VBoxContainer = $HBoxContainer/P2Panel
@onready var p1_ready_label: Label = $HBoxContainer/P1Panel/P1ReadyLabel
@onready var p2_ready_label: Label = $HBoxContainer/P2Panel/P2ReadyLabel

func _ready() -> void:
	# Automatically default selections back to standard when entering the menu
	Global.p1_choice = "standard"
	Global.p2_choice = "standard"
	
	# DYNAMIC SHOW/HIDE LOGIC
	if Global.is_two_player:
		p2_panel.show()
	else:
		p2_panel.hide()

# ===== PLAYER 1 BUTTON SELECTIONS =====

func _on_btn_feather_p_1_pressed() -> void:
	Global.p1_choice = "feather"
	p1_ready_label.text = "Selected: Feather Ball 🟡"

func _on_btn_standard_p_1_pressed() -> void:
	Global.p1_choice = "standard"
	p1_ready_label.text = "Selected: Standard Ball 🔵"

func _on_btn_iron_p_1_pressed() -> void:
	Global.p1_choice = "iron"
	p1_ready_label.text = "Selected: Iron Ball 🔴"


# ===== PLAYER 2 BUTTON SELECTIONS =====

func _on_btn_feather_p_2_pressed() -> void:
	Global.p2_choice = "feather"
	p2_ready_label.text = "Selected: Feather Ball 🟡"

func _on_btn_standard_p_2_pressed() -> void:
	Global.p2_choice = "standard"
	p2_ready_label.text = "Selected: Standard Ball 🔵"

func _on_btn_iron_p_2_pressed() -> void:
	Global.p2_choice = "iron"
	p2_ready_label.text = "Selected: Iron Ball 🔴"


# ===== START THE GAME =====

func _on_button_pressed() -> void:
	# Change this path to whatever your main race track scene file is
	if Global.is_two_player:
		get_tree().change_scene_to_file("res://Tracks/Track01.tscn" )
	else:
		get_tree().change_scene_to_file("res://Tracks/Track02.tscn")
