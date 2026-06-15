# Global.gd
extends Node

var is_two_player := false # True if 2-player split screen, false if solo

# Maps each choice key to the corresponding ball scene path
const BALL_SCENES = {
	"feather": "res://Balls/ball_speed.tscn",
	"standard": "res://Balls/ball_default.tscn",
	"iron": "res://Balls/ball_heavy.tscn"
}

# Add the ball profiles
const BALL_PROFILES = {
	"feather": {
		"mass_factor": 0.6,
		"size_factor": 0.8,
		"move_force": 40.0,
		"max_speed": 30.0,
		"color": Color.YELLOW
	},
	"standard": {
		"mass_factor": 1.0,
		"size_factor": 1.0,
		"move_force": 38.0,
		"max_speed": 28.0,
		"color": Color.BLUE
	},
	"iron": {
		"mass_factor": 1.5,
		"size_factor": 1.2,
		"move_force": 35.0,
		"max_speed": 25.0,
		"color": Color.RED
	}
}

# Add the selection trackers
var p1_choice := "standard"
var p2_choice := "standard"
