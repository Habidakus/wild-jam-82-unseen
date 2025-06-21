class_name MiniGame_Default extends MiniGame

## if the player places their floater within this distance of the center of the bubbles, time-to-nibble will be normal
@export var medium_distance : float = 12.0
## if the player places their floater far from the center of the bubbles, but still within this distance, time-to-nibble will be multiplied by max_distance_slowness
@export var maximum_distance : float = 24.0
## the nibble wait time will be multiplied by this value if the player places their floater too far from the center of the bubbles
@export var max_distance_slowness : float = 4.0
## number of seconds the player has to react to the nibble before the fish escapes
@export var failure_time : float = 2.5
## minimum time the player will have to wait before the nibbles start
@export var min_nibble_seconds : float = 2
## maximum time the player will have to wait before the nibbles start
@export var max_nibble_seconds : float = 10

var _nibble_wait : float = -1
var _failure_countdown : float = -1
var _pole : FishingPole

func get_hint(fish_name : String) -> String:
    return "You must wait until the line goes taut,\nbefore you attempt to land the %s ." % fish_name

func close_enough(dist : float) -> bool:
    return dist < maximum_distance

func is_being_played() -> bool:
    return _pole != null

func register_pole(pole : FishingPole) -> bool:
    var distance : float = (pole.get_floater_position() - position).length()
    if not close_enough(distance):
        return false
    
    _pole = pole
    _nibble_wait = _rnd.randf_range(min_nibble_seconds, max_nibble_seconds)
    if distance > medium_distance:
        _nibble_wait *= max_distance_slowness
    
    return true

func on_click() -> void:
    if _nibble_wait > 0:
        _map_runner.mark_mini_game_removed(self)
        _pole.retract(true)
        return
    
    if _failure_countdown < 0:
        print("How is mini-game getting a click after it's failure countdown has expired?")
        _pole.retract(true)
    else:
        _pole.retract_with_fish(_fish_type)
        
    _map_runner.mark_mini_game_removed(self)
    
func _process(delta: float) -> void:
    if _failure_countdown > 0:
        _failure_countdown -= delta
        if _failure_countdown < 0:
            _map_runner.mark_mini_game_removed(self)
            _pole.on_fish_escaped()
            return
            
    if _nibble_wait < 0:
        return
        
    _nibble_wait -= delta
    if _nibble_wait > 0:
        return
    
    if _pole != null:
        _pole.go_tight()
        _failure_countdown = failure_time
    
