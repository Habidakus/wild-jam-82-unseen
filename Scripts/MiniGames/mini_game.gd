class_name MiniGame extends Node2D

var _rnd : RandomNumberGenerator
var _map_runner : MapRunner
var _fish_type : Fish

func is_being_played() -> bool:
    print("ERROR: %s needs to implement is_being_played()" % name)
    return false

func set_fish_type(fish_type : Fish, rnd_seed : int, map_runner : MapRunner) -> void:
    _fish_type = fish_type
    _map_runner = map_runner
    _rnd = RandomNumberGenerator.new()
    _rnd.seed = rnd_seed

func register_pole(_pole : FishingPole) -> bool:
    print("ERROR: %s needs to implement register_pole()" % name)
    return false

func on_click() -> void:
    print("ERROR: %s needs to implement on_click()" % name)
