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
var _movement_path : Array[Vector2i]

func set_map_runner(map_runner : MapRunner) -> void:
    _map_runner = map_runner
 
func _ready() -> void:
    for child in get_children():
        if child is Sprite2D:
            _sprite = child as Sprite2D

func _process(delta: float) -> void:
    _next_frame_countdown -= delta
    if _next_frame_countdown < 0:
        _sprite.frame = (_sprite.frame + 1) % _sprite.hframes
        _next_frame_countdown = idle_rate

    if _map_runner == null:
        return
    
    if _movement_path == null || _movement_path.size() == 0:
        var target_cell : Vector2i = _map_runner.get_enemy_spawn_spot(false)
        var our_cell : Vector2i = _map_runner.get_map().local_to_map(position)
        _movement_path = _map_runner.generate_move_path(our_cell, target_cell)

    var dest_cell : Vector2i = _movement_path[0]
    var dest_pos : Vector2 = _map_runner.get_map().map_to_local(dest_cell)
    
    var move_dist : float = speed * delta
    var delta_to_dest = dest_pos - position
    $Sprite2D.flip_h = delta_to_dest.x < 0
    if delta_to_dest.length() <= move_dist:
        # pop the first value off
        position = dest_pos
        _movement_path = _movement_path.slice(1)
        return
    
    position += delta_to_dest.normalized() * move_dist
