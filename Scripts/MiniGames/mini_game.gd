class_name MiniGame extends Node2D

var _rnd : RandomNumberGenerator
var _map_runner : MapRunner
var _fish_type : Fish
var _has_summoned : bool = false

func get_hint(fish_name : String) -> String:
    return "The %s, very tricky..." % fish_name
    
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

func _summon_oni() -> void:
    _has_summoned = true
    _map_runner.summon_oni_to_player()

func _handle_summon_oni(event : Fish.SummonsOni) -> void:
    if _has_summoned:
        return
        
    match _fish_type.summons_oni:
        Fish.SummonsOni.Never:
            _has_summoned = true
            return
        Fish.SummonsOni.OnSuccess:
            if event == Fish.SummonsOni.OnSuccess:
                _summon_oni()
            return
        Fish.SummonsOni.OnFailure:
            if event == Fish.SummonsOni.OnFailure:
                _summon_oni()
            return
        Fish.SummonsOni.OnSuccessOrFailure:
            if event == Fish.SummonsOni.OnSuccess || event == Fish.SummonsOni.OnFailure:
                _summon_oni()
            return
        Fish.SummonsOni.OnStart:
            if event == Fish.SummonsOni.OnStart:
                _summon_oni()
            return
