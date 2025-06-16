class_name Fish extends Resource

@export var player_facing_name : String
@export var texture_image : Texture
@export var texture_region : Rect2

enum MiniGame { Default }
@export var mini_game : MiniGame = MiniGame.Default

enum DistanceFromShore { Shallows, Anywhere, Far }
@export var distance_from_shore : DistanceFromShore = DistanceFromShore.Anywhere

enum RequirementToSpawn { None, Silence, Meditation }
@export var requirement_to_spawn : RequirementToSpawn = RequirementToSpawn.None

@export_range(5.0,120.0) var min_duration_in_seconds : float = 25
@export_range(10.0,240.0) var max_duration_in_seconds : float = 45
