# RaceHUD.gd
extends CanvasLayer

@onready var countdown_label: Label = $CenterContainer/CountdownLabel
@onready var time_label: Label = $MarginContainerTime/TimeLabel
@onready var p1_lap_label: Label = $MarginContainerP1/P1LapLabel
@onready var p2_lap_label: Label = $MarginContainerP2/P2LapLabel

var time_elapsed := 0.0
var countdown_time := 3

func _ready() -> void:
	Global.race_active = false
	time_label.text = "00:00.00"
	
	# DYNAMIC HUD LAYOUT CONFIGURATION
	if Global.is_two_player:
		p2_lap_label.show()
		p1_lap_label.text = "P1 LAP: 1/" + str(Global.total_laps)
		p2_lap_label.text = "P2 LAP: 1/" + str(Global.total_laps)
	else:
		p2_lap_label.hide() # Hide P2 UI entirely for solo tracks
		p1_lap_label.text = "LAP: 1/" + str(Global.total_laps)
		
	run_countdown()

func run_countdown() -> void:
	while countdown_time > 0:
		countdown_label.text = str(countdown_time)
		await get_tree().create_timer(1.0).timeout
		countdown_time -= 1
	
	countdown_label.text = "GO!"
	Global.race_active = true
	
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = ""

func _process(delta: float) -> void:
	if Global.race_active:
		time_elapsed += delta
		format_and_display_time()
		update_lap_display()

func format_and_display_time() -> void:
	var minutes := int(time_elapsed / 60)
	var seconds := int(time_elapsed) % 60
	var milliseconds := int((time_elapsed - int(time_elapsed)) * 100)
	time_label.text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

func update_lap_display() -> void:
	# Current lap is always: laps completed + 1
	# We use min() to prevent it from showing "Lap 3/2" for a split second right at the finish line
	var p1_display_lap = min(Global.p1_laps + 1, Global.total_laps)
	
	if Global.is_two_player:
		var p2_display_lap = min(Global.p2_laps + 1, Global.total_laps)
		p1_lap_label.text = "P1 LAP: %d/%d" % [p1_display_lap, Global.total_laps]
		p2_lap_label.text = "P2 LAP: %d/%d" % [p2_display_lap, Global.total_laps]
	else:
		p1_lap_label.text = "LAP: %d/%d" % [p1_display_lap, Global.total_laps]
