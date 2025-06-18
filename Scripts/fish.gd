class_name Fish extends Resource

## This is what the player will see if we ever print the name of this catch on the screen
@export var player_facing_name : String
@export var texture_image : Texture
@export var texture_region : Rect2

@export var mini_game : PackedScene = preload("res://Scenes/MiniGames/mini_game_default_easy.tscn")

enum DistanceFromShore { Shallows, Medium, Far, Anywhere }
@export var distance_from_shore : DistanceFromShore = DistanceFromShore.Shallows

enum RequirementToSpawn { None, Silence, Meditation }
@export var requirement_to_spawn : RequirementToSpawn = RequirementToSpawn.None

@export_range(5.0,120.0) var min_duration_in_seconds : float = 25
@export_range(10.0,240.0) var max_duration_in_seconds : float = 45
