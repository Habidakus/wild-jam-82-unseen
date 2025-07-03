class_name MiniGame_Orbits extends MiniGame

## player must place their floater within this radius of the bubble center
@export var radius : float = 12.0
## time it will take for the orbits to align
@export var min_cycle_span : float = 2.5
@export var max_cycle_span : float = 2.5
## minimum time the player will have to wait before the nibbles start
@export var min_nibble_seconds : float = 2
## maximum time the player will have to wait before the nibbles start
@export var max_nibble_seconds : float = 10
## what the maximum orbit speed is of each bubble ring
@export var max_orbit_speed : float = 15.0
## how close to alignment the player needs to be (on either side of alignment)
@export_range(0, 1) var min_player_accuracy : float = 0.25

var _nibble_wait : float = -1
var _total_nibble_time : float = -1
#var _failure_countdown : float = -1
var _pole : FishingPole
var _stop_processing : bool = false
var _ring_material : Material = null
var _total_alignment_time : float = -1
var _current_orbit_time : float = -1
var _pole_down_time : float
var _ring1_speed : float = -1
var _ring2_speed : float = -1
var _ring3_speed : float = -1
var _ring4_speed : float = -1
var _ring5_speed : float = -1
const SLOWNESS : float = 10.0

func get_hint(fish_name : String) -> String:
    return "The %s is celestial - observe its\norbital nature and await alignment." % fish_name
    
func _ready() -> void:
    #$TextureRect.hide()
    _ring_material = ($TextureRect as TextureRect).material
    _total_nibble_time = _rnd.randf_range(min_nibble_seconds, max_nibble_seconds)
    _total_alignment_time = _rnd.randf_range(min_cycle_span, max_cycle_span)
    _current_orbit_time = _total_nibble_time + _total_alignment_time
    _pole_down_time = _current_orbit_time + _total_nibble_time / SLOWNESS
    
    _ring1_speed = _rnd.randf_range(-1.0, 1.0) * max_orbit_speed;
    _ring2_speed = _rnd.randf_range(-1.0, 1.0) * max_orbit_speed;
    _ring3_speed = _rnd.randf_range(-1.0, 1.0) * max_orbit_speed;
    _ring4_speed = _rnd.randf_range(-1.0, 1.0) * max_orbit_speed;
    _ring5_speed = _rnd.randf_range(-1.0, 1.0) * max_orbit_speed;
    
    _ring_material.set_shader_parameter("time", _pole_down_time)
    _ring_material.set_shader_parameter("alignment", _rnd.randf_range(0.0, 2.0 * PI))
    _ring_material.set_shader_parameter("ring1_speed", _ring1_speed)
    _ring_material.set_shader_parameter("ring2_speed", _ring2_speed)
    _ring_material.set_shader_parameter("ring3_speed", _ring3_speed)
    _ring_material.set_shader_parameter("ring4_speed", _ring4_speed)
    _ring_material.set_shader_parameter("ring5_speed", _ring5_speed)

func is_being_played() -> bool:
    return _pole != null

func close_enough(dist : float) -> bool:
    return dist < radius

func register_pole(pole : FishingPole) -> bool:
    var distance : float = (pole.get_floater_position() - position).length()
    if not close_enough(distance):
        return false
    
    _handle_summon_oni(Fish.SummonsOni.OnStart)
    _pole = pole
    _nibble_wait = _total_nibble_time
    _current_orbit_time = _nibble_wait + _total_alignment_time
    
    return true

func on_click() -> void:
    _stop_processing = true
    
    if _nibble_wait > 0:
        _map_runner.mark_mini_game_removed(self)
        _pole.retract(true)
        _handle_summon_oni(Fish.SummonsOni.OnFailure)
        return

    if _current_orbit_time < min_player_accuracy * _total_alignment_time:
        _pole.retract_with_fish(_fish_type)
        _handle_summon_oni(Fish.SummonsOni.OnSuccess)
    else:
        _handle_summon_oni(Fish.SummonsOni.OnFailure)
        _pole.retract(true)
    
func _process(delta: float) -> void:
    if _stop_processing:
        return
    
    if _pole == null:
        return

    if _current_orbit_time < (0 - min_player_accuracy * _total_alignment_time):
            _map_runner.mark_mini_game_removed(self)
            _pole.on_fish_escaped()
            _handle_summon_oni(Fish.SummonsOni.OnFailure)
            return
            
    if _nibble_wait < 0:
        _current_orbit_time -= delta
        _ring_material.set_shader_parameter("time", _current_orbit_time)
        return
        
    _nibble_wait -= delta
    if _nibble_wait > 0:
        var lrp : float = 1.0 - _nibble_wait / _total_nibble_time
        lrp = lrp * lrp
        
        var tm : float = lerpf(_pole_down_time, _current_orbit_time, lrp)
        _ring_material.set_shader_parameter("time", tm)
        return

    _ring_material.set_shader_parameter("time", _current_orbit_time)
    
    if _pole != null:
        _pole.go_tight()
