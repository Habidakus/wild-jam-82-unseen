class_name MiniGame_Ring extends MiniGame

## player must place their floater within this radius of the bubble center
@export var radius : float = 12.0
## time it will take for the circle to contract
@export var min_cycle_span : float = 2.5
@export var max_cycle_span : float = 2.5
## minimum time the player will have to wait before the nibbles start
@export var min_nibble_seconds : float = 2
## maximum time the player will have to wait before the nibbles start
@export var max_nibble_seconds : float = 10
## how complete the ring must be before the player can successfully pull the fish out
@export_range(0, 1) var min_player_accuracy : float = 0.75

var _nibble_wait : float = -1
#var _failure_countdown : float = -1
var _pole : FishingPole
var _fish_dash_normal : Vector2
var _stop_processing : bool = false
var _ring_material : Material = null
var _circle_span : float
var _circle_remaining_time : float = -1

func get_hint(fish_name : String) -> String:
	return "The %s is crafty, and you must be\npatient and wait until the ring is almost closed." % fish_name
	
func _ready() -> void:
	$TextureRect.hide()
	_ring_material = ($TextureRect as TextureRect).material

func is_being_played() -> bool:
	return _pole != null

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
		_pole.retract(true)
		return

	var circle_fraction : float = _circle_span - _circle_remaining_time
	if circle_fraction >= min_player_accuracy:
		_pole.retract_with_fish(_fish_type)
	else:
		_pole.retract(true)
	
func _process(delta: float) -> void:
	if _stop_processing:
		return

	if _circle_remaining_time > 0:
		_circle_remaining_time -= delta
		if _circle_remaining_time <= 0:
			_map_runner.mark_mini_game_removed(self)
			_pole.on_fish_escaped()
		else:
			var circle_fraction : float = (_circle_span - _circle_remaining_time) / _circle_span
			_ring_material.set_shader_parameter("fraction", circle_fraction)
		return
			
	if _nibble_wait < 0:
		return
		
	_nibble_wait -= delta
	if _nibble_wait > 0:
		return
	
	if _pole != null:
		_pole.go_tight()
		_circle_span = _rnd.randf_range(min_cycle_span, max_cycle_span)
		_circle_remaining_time = _circle_span
		$TextureRect.show()
		_ring_material.set_shader_parameter("fraction", 0)
