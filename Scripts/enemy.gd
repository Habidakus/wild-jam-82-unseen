class_name Enemy extends Node2D

## This is what the player will see if we ever print the name of this enemy on the screen
@export var player_facing_name : String
## How fast this enemy moves
@export var speed : float = 50
## How often we switch to a new idle animation frame
@export var idle_rate : float = 1.0

var _next_frame_countdown : float = 0
var _sprite : Sprite2D
var _map_runner : MapRunner
@onready var _nav_agent : NavigationAgent2D = $NavigationAgent2D

func set_map_runner(map_runner : MapRunner) -> void:
    _map_runner = map_runner
 
func _ready() -> void:
    for child in get_children():
        if child is Sprite2D:
            _sprite = child as Sprite2D

    _pick_random_destination()

func _pick_random_destination() -> void:
    var cell : Vector2i = _map_runner.get_enemy_spawn_spot(false)
    var map : TileMapLayer = _map_runner.get_map()
    _nav_agent.set_target_position(map.to_global(map.map_to_local(cell)))

func _physics_process(_delta: float) -> void:
    if _nav_agent.is_navigation_finished():
        _pick_random_destination()
    
    var next_global_pos = _nav_agent.get_next_path_position()
    var direction = global_position.direction_to(next_global_pos)
    position += direction * speed

func _process(delta: float) -> void:
    _next_frame_countdown -= delta
    if _next_frame_countdown < 0:
        _sprite.frame = (_sprite.frame + 1) % _sprite.hframes
        _next_frame_countdown = idle_rate
