# Global.gd
extends Node

var is_two_player := false # True if 2-player split screen, false if solo

# Add the ball profiles
const BALL_PROFILES = {
	"feather": {
		"mass_factor": 0.6,
		"size_factor": 0.8,
		"move_force": 30.0,
		"max_speed": 20.0,
		"color": Color.YELLOW
	},
	"standard": {
		"mass_factor": 1.0,
		"size_factor": 1.0,
		"move_force": 28.0,
		"max_speed": 18.0,
		"color": Color.BLUE
	},
	"iron": {
		"mass_factor": 1.5,
		"size_factor": 1.2,
		"move_force": 25.0,
		"max_speed": 15.0,
		"color": Color.RED
	}
}

# Add the selection trackers
var p1_choice := "standard"
var p2_choice := "standard"
