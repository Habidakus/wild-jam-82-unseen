class_name fish extends Resource

@export var player_facing_name : String
@export var texture_image : Texture
@export var texture_region : Rect2

enum MiniGame { Default }
@export var mini_game : MiniGame = MiniGame.Default

enum DistanceFromShore { Shallows, Anywhere, Far }
@export var distance_from_shore : DistanceFromShore = DistanceFromShore.Anywhere

enum RequirementToSpawn { None, Silence, Meditation }
@export var requirement_to_spawn : RequirementToSpawn = RequirementToSpawn.None
