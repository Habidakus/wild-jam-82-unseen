class_name ReportCard extends Node

var _fish : Array[Array] = []
var _failures : Array[Fish] = []
var _rnd : RandomNumberGenerator
var _total_time : float = -1
var _finished : bool = false
var _smoke_bomb_escape : bool = false
var _times_heard : int = 0
var _times_seen : int = 0

func start(rnd_seed : int) -> void:
    _rnd = RandomNumberGenerator.new()
    _rnd.seed = rnd_seed
    _total_time = 0
    
func _process(delta: float) -> void:
    if not _finished:
        _total_time += delta
    
func add_heard() -> void:
    _times_heard += 1

func add_seen() -> void:
    _times_seen += 1

func add_smoke_bomb_escape() -> void:
    _smoke_bomb_escape = true

func add_failure(fish_type : Fish) -> void:
    print("Player failed to catch a %s" % fish_type.player_facing_name)
    _failures.append(fish_type)

func _generate_fish_score() -> float:
    var ret_val : float = 10
    for i in range(0, 3):
        var v : float = _rnd.randf_range(0.0, 1.0)
        if abs(v - 0.33) < abs(ret_val - 0.33):
            ret_val = v
    return ret_val

func add_fish(fish_type : Fish) -> void:
    print("Player caught a %s" % fish_type.player_facing_name)
    _fish.append([fish_type, _generate_fish_score()])
