class_name MiniGame_Capture extends MiniGame

## player must place their floater within this radius of the bubble center
@export var radius : float = 12.0
## number of seconds the player has to react to the nibble before the fish escapes
@export var failure_time : float = 2.5
## speed that the fish will swim at to get away
@export var fish_speed : float = 200
## minimum time the player will have to wait before the nibbles start
@export var min_nibble_seconds : float = 2
## maximum time the player will have to wait before the nibbles start
@export var max_nibble_seconds : float = 10
## How directly infront of the fish the player has to click; with 1 being impossibly directly infront and 0 being anywhere in the forward arc
@export_range(-1, 1) var min_player_accuracy : float = 0.5

var _nibble_wait : float = -1
var _failure_countdown : float = -1
var _pole : FishingPole
var _fish_dash_normal : Vector2
var _stop_processing : bool = false

func close_enough(dist : float) -> bool:
    return dist < radius

func register_pole(pole : FishingPole) -> bool:
    var distance : float = (pole.get_floater_position() - position).length()
    if not close_enough(distance):
        return false
    
    _pole = pole
    _nibble_wait = _rnd.randf_range(min_nibble_seconds, max_nibble_seconds)
    _fish_dash_normal = Vector2(_rnd.randf_range(-1, 1), _rnd.randf_range(-1, 1)).normalized()
    
    return true

func on_click() -> void:
    _stop_processing = true
    
    if _nibble_wait > 0:
        _map_runner.mark_mini_game_removed(self)
        _pole.retract()
        return
    
    if _failure_countdown < 0:
        print("How is mini-game getting a click after it's failure countdown has expired?")
        _pole.retract()

    var mouse_click_pos : Vector2 = _map_runner.get_map().get_local_mouse_position()
    var click_relative_to_fish : Vector2 = (mouse_click_pos - (position + get_fish_offset())).normalized()
    var click_dot : float = _fish_dash_normal.dot(click_relative_to_fish)
    var caught_fish : bool = click_dot > min_player_accuracy
    #print("click_offset=%s dash=%s dot=%s" % [_fish_dash_normal, click_relative_to_fish, click_dot])
    if caught_fish:
        _pole.retract_with_fish(_fish_type)
    else:
        _pole.retract()

func get_fish_offset() -> Vector2:
    return _fish_dash_normal * (failure_time - _failure_countdown) * fish_speed
    
func _process(delta: float) -> void:
    if _stop_processing:
        return

    if _failure_countdown > 0:
        _failure_countdown -= delta
        if _failure_countdown < 0:
            _map_runner.mark_mini_game_removed(self)
            _pole.on_fish_escaped()
        else:
            _pole.update_floater_offset(get_fish_offset())
        return
            
    if _nibble_wait < 0:
        return
        
    _nibble_wait -= delta
    if _nibble_wait > 0:
        return
    
    if _pole != null:
        _pole.go_tight()
        _failure_countdown = failure_time
    
