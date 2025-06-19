class_name Enemy extends Node2D

## This is what the player will see if we ever print the name of this enemy on the screen
@export var player_facing_name : String
## How fast this enemy moves
@export var speed : float = 50
## How often we switch to a new idle animation frame
@export var idle_rate : float = 1.0
## minimum seconds between refreshes in the darkness of where the oni is
@export var footprint_cooldown_min : float = 1.0
## maximum seconds between refreshes in the darkness of where the oni is
@export var footprint_cooldown_max : float = 5.0
## If the player is ever within this many squares of the Oni, it will just go right at them
@export var max_dist_see_player : int = 6
## Occassionally the Oni will stop and listen, and if the player is walking, they will hear them within this range
@export var max_dist_hear_walking : int = 9
## Occassionally the Oni will stop and listen, and if the player is running, they will hear them within this range
@export var max_dist_hear_running : int = 12

var _next_frame_countdown : float = 0
var _sprite : Sprite2D
var _map_runner : MapRunner
var _movement_path : Array[Vector2i]
var _footprint : Node2D
var _footprint_material : Material
var _footprint_direction : Vector2 = Vector2.ZERO
var _footprint_scene : PackedScene = preload("res://Scenes/guard_footsteps.tscn")
var _radar : CanvasLayer
var _footprint_cooldown : float = footprint_cooldown_max

func set_map_runner(map_runner : MapRunner, radar : CanvasLayer) -> void:
    _map_runner = map_runner
    _radar = radar
 
func _ready() -> void:
    for child in get_children():
        if child is Sprite2D:
            _sprite = child as Sprite2D

func _exit_tree() -> void:
    _footprint.queue_free()

func _get_target_cell() -> Vector2i:
    var player = _map_runner._player
    var player_move_state = _map_runner._player._move_state
    var player_cell : Vector2i = _map_runner.get_map().local_to_map(player.position)
    var our_cell : Vector2i = _map_runner.get_map().local_to_map(position)
    var player_dist : int = abs(player_cell.x - our_cell.x) + abs(player_cell.y - our_cell.y)
    if player_dist < max_dist_hear_walking:
        if player_move_state == Player.MoveState.Walking || player_move_state == Player.MoveState.Running:
            emit_growl()
            return player_cell
    if player_dist < max_dist_hear_running:
        if player_move_state == Player.MoveState.Running:
            emit_growl()
            return player_cell
    return _map_runner.get_enemy_spawn_spot(false)

func emit_growl() -> void:
    print("TODO: %s should growl now" % player_facing_name)

func _process(delta: float) -> void:
    if _footprint == null:
        if _radar != null:
            _footprint = _footprint_scene.instantiate()
            _radar.add_child(_footprint)
            var footprint_texture_rect = _footprint.find_child("TextureRect") as TextureRect
            _footprint_material = footprint_texture_rect.material
            _footprint.hide()
    else:
        _footprint_cooldown -= delta
        if _footprint_cooldown < 0 && _footprint != null:
            _footprint_cooldown = _map_runner._rnd.randf_range(footprint_cooldown_min, footprint_cooldown_max)
            if not _map_runner._player.is_in_light_area(global_position):
                _footprint.show()
                _footprint_material.set_shader_parameter("direction", _footprint_direction)
                var vec : Vector2 = _map_runner.get_vector_from_player_to_local(position)
                _footprint.position = get_viewport().get_visible_rect().size / 2 - vec * 2
                var tween : Tween = create_tween()
                tween.tween_method(
                    func(value) : _footprint_material.set_shader_parameter("fraction", value), 0.0, 1.0, 0.5
                )
                tween.tween_callback(func(): _footprint.hide())
        
    _next_frame_countdown -= delta
    if _next_frame_countdown < 0:
        _sprite.frame = (_sprite.frame + 1) % _sprite.hframes
        _next_frame_countdown = idle_rate

    if _map_runner == null:
        return
    
    var player = _map_runner._player
    var player_cell : Vector2i = _map_runner.get_map().local_to_map(player.position)
    var our_cell : Vector2i = _map_runner.get_map().local_to_map(position)
    var player_dist : int = abs(player_cell.x - our_cell.x) + abs(player_cell.y - our_cell.y)
    if player_dist <= max_dist_see_player:
        _movement_path = _map_runner.generate_move_path(our_cell, player_cell)
    elif _movement_path == null || _movement_path.size() == 0:
        var target_cell = _get_target_cell()
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
    
    var movement_direction : Vector2 = delta_to_dest.normalized();
    position += movement_direction * move_dist
    _footprint_direction = (_footprint_direction * 10.0 + movement_direction * delta) / (10.0 + delta);
    
