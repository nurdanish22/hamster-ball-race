# Global.gd
extends Node

var is_two_player := false # True if 2-player split screen, false if solo

var race_active := false # Controls whether balls are allowed to move

# Global.gd updates
var total_laps := 2 # Change this to 3, 5, etc. depending on your project requirements

# Track progress for each player ID
var p1_laps := 0
var p2_laps := 0
var p1_cleared_midpoint := false
var p2_cleared_midpoint := false

# Call this from your RaceHUD or Track script when the scene loads to wipe previous game data
func reset_race_data():
	p1_laps = 0
	p2_laps = 0
	p1_cleared_midpoint = false
	p2_cleared_midpoint = false

# Maps each choice key to the corresponding ball scene path
const BALL_SCENES = {
	"feather": "res://Balls/ball_speed.tscn",
	"standard": "res://Balls/ball_default.tscn",
	"iron": "res://Balls/ball_heavy.tscn"
}

# Add the ball profiles
# impact_multiplier controls how hard the ball pushes RigidBody3D obstacles on contact.
# feather = light tap, standard = normal push, iron = heavy smash.
const BALL_PROFILES = {
	"feather": {
		"mass_factor": 0.6,
		"size_factor": 0.8,
		"move_force": 40.0,
		"max_speed": 26.0,
		"color": Color.YELLOW,
		"impact_multiplier": 0.05
	},
	"standard": {
		"mass_factor": 1.0,
		"size_factor": 1.0,
		"move_force": 40.0,
		"max_speed": 28.0,
		"color": Color.BLUE,
		"impact_multiplier": 0.5
	},
	"iron": {
		"mass_factor": 1.0,
		"size_factor": 1.2,
		"move_force": 40.0,
		"max_speed": 30.0,
		"color": Color.RED,
		"impact_multiplier": 2.0
	}
}

# Add the selection trackers
var p1_choice := "standard"
var p2_choice := "standard"
