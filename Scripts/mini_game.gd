class_name MiniGame extends Node2D

@export var medium_distance : float = 12.0
@export var maximum_distance : float = 24.0
@export var failure_time : float = 2.5
@export var max_distance_slowness : float = 4.0
@export var min_nibble_seconds : float = 2
@export var max_nibble_seconds : float = 10

var _rnd : RandomNumberGenerator
var _map_runner : MapRunner
var _fish_type : Fish
var _nibble_wait : float = -1
var _failure_countdown : float = -1
var _pole : FishingPole

func set_fish_type(fish_type : Fish, rnd_seed : int, map_runner : MapRunner) -> void:
    _fish_type = fish_type
    _map_runner = map_runner
    _rnd = RandomNumberGenerator.new()
    _rnd.seed = rnd_seed

func close_enough(dist : float) -> bool:
    return dist < maximum_distance

func register_pole(pole : FishingPole) -> bool:
    var distance : float = (pole.get_floater_position() - position).length()
    if not close_enough(distance):
        return false
    
    _pole = pole
    _nibble_wait = _rnd.randf_range(min_nibble_seconds, max_nibble_seconds)
    if distance > medium_distance:
        _nibble_wait *= max_distance_slowness
    
    return true

func _process(delta: float) -> void:
    if _failure_countdown > 0:
        _failure_countdown -= delta
        if _failure_countdown < 0:
            _map_runner.mark_mini_game_removed(self)
            return
            
    if _nibble_wait < 0:
        return
        
    _nibble_wait -= delta
    if _nibble_wait > 0:
        return
    
    _pole.go_tight()
    _failure_countdown = failure_time
    
