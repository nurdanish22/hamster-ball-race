extends Node3D

@export var player_ball_scene: PackedScene
@export var track_scenes: Dictionary

func _ready():

	load_track()
	spawn_players()

func load_track():

	var track_path = "res://scenes/tracks/%s.tscn" % Global.selected_track
	var track = load(track_path).instantiate()

	$TrackRoot.add_child(track)

func spawn_players():

	var player_count = Global.player_count

	for i in range(player_count):

		var player = player_ball_scene.instantiate()

		player.global_position = Vector3(i * 2, 2, 0)

		$PlayersRoot.add_child(player)
