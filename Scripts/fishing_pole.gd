class_name FishingPole extends Node2D

@export var casting_draw_back_time : float = 0.5
@export var casting_forward_time : float = 0.125
@export var casting_line_segments : int = 20
@export var casting_hang_time : float = 0.75

@export var _sound_floater_hits_water : AudioStream
@export var _sound_caught_fish : AudioStream
@export var _sound_tension_on_the_line : AudioStream

const GRAVITY : Vector2 = Vector2.DOWN * 200.0

var _line_slack : bool = true
var _mini_game : MiniGame = null
var _rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _mouse_click_pos : Vector2
var _map_cell : Vector2i
var _map : TileMapLayer
var _player : Player
var _parabolic_start_point : Vector2
var _parabolic_velocity : Vector2
var _parabolic_time_remaining : float = 0
var _parabolic_time_span : float
var _bobbing_depth : float = -1
var _bobbing_tween : Tween
var _bobbing_image_height : float = 5.0
var _map_runner : MapRunner
var _hooked_fish_floater_offset : Vector2 = Vector2.ZERO
var _default_pole_endpoint : Vector2

func _ready() -> void:
	$Floater.hide()
	$FishingLine.hide()
	_default_pole_endpoint = $PoleLine.get_point_position(1)

func get_floater_position() -> Vector2:
	return position + $Floater.position

func update_floater_offset(offset : Vector2) -> void:
	$Floater.position -= _hooked_fish_floater_offset
	_hooked_fish_floater_offset = offset
	$Floater.position += _hooked_fish_floater_offset

func cast_line(player : Player, map_runner : MapRunner) -> void:
	position = player.position
	_map_runner = map_runner
	_map = map_runner.get_map()
	_player = player
	var speed_multiple : float = _get_speed_multiple()
	_mouse_click_pos = _map.get_local_mouse_position()
	_map_cell = _map.local_to_map(_mouse_click_pos)
	var tween : Tween = create_tween()
	var current_end : Vector2 = _default_pole_endpoint
	if _mouse_click_pos.x < position.x:
		current_end.x = 0.0 - current_end.x
	var snap_pos : Vector2 = Vector2(0 - current_end.x, current_end.y)
	tween.tween_method(Callable(self, "_adjust_end_pos"), current_end, snap_pos, casting_draw_back_time * speed_multiple)
	tween.tween_method(Callable(self, "_adjust_end_pos"), snap_pos, current_end, casting_forward_time * speed_multiple)
	tween.tween_callback(Callable(self, "_fly_floater"))

func _adjust_end_pos(pos : Vector2) -> void:
	$PoleLine.set_point_position(1, pos)

var _prev_pos : Array[Vector2]
func _fly_floater() -> void:
	$FishingLine.show()
	$Floater.show()
	var current_end : Vector2 = $PoleLine.get_point_position(1)
	$FishingLine.clear_points()
	_prev_pos.clear()
	for i in range(0, casting_line_segments):
		$FishingLine.add_point(current_end)
		_prev_pos.append(current_end)
	$Floater.position = current_end
	
	var target_pos : Vector2 = _mouse_click_pos - position
	var hang_time : float = casting_hang_time * _get_speed_multiple()
	_parabolic_start_point = current_end
	_parabolic_velocity = _calculate_parabolic_velocity(target_pos, current_end, hang_time)
	_parabolic_time_span = hang_time
	_parabolic_time_remaining = hang_time

func _calculate_parabolic_velocity(target_pos : Vector2, start_pos : Vector2, duration : float) -> Vector2:
	var dx : float = target_pos.x - start_pos.x
	var dy : float = target_pos.y - start_pos.y
	var vx : float = dx / duration
	var vy : float = (dy - GRAVITY.y * duration * duration / 2) / duration
	return Vector2(vx, vy)

func _invoke_new_bobbing() -> void:
	_bobbing_tween = create_tween()
	var bob_transition_time : float = _rnd.randf_range(0.5, 1.5)
	var next_depth : float = _rnd.randf_range(0, 3.5)
	_bobbing_tween.tween_method(Callable(self, "_set_bobbing_depth"), _bobbing_depth, next_depth, bob_transition_time)
	_bobbing_tween.tween_interval(0.1)
	_bobbing_tween.tween_callback(Callable(self, "_invoke_new_bobbing"))

func _set_bobbing_depth(depth : float) -> void:
	$Floater/Sprite2D.region_rect.size.y = _bobbing_image_height - depth
	$Floater.position.y += (depth - _bobbing_depth)
	_bobbing_depth = depth

func on_player_not_stealthed() -> void:
	if _mini_game != null:
		if _mini_game._fish_type.requirement_to_spawn == Fish.RequirementToSpawn.Stealth:
			_line_slack = true
			if _bobbing_tween != null:
				_bobbing_tween.kill()
			_set_bobbing_depth(0)
			var cell : Vector2i = _map.local_to_map(_mini_game.position)
			_map_runner._expire_spawn_spot(cell)
			_mini_game = null

func _register_mini_game(mg : MiniGame) -> void:
	_mini_game = mg

func on_click() -> void:
	if _parabolic_time_remaining > 0:
		# still casting     
		print("TODO: implement cancel parabolic casting")
		_player.cancel_fishing_pole()
		return
	
	if _mini_game == null:
		retract(false)
		return
	
	_mini_game.on_click()

func go_tight() -> void:
	if _bobbing_tween != null:
		_bobbing_tween.kill()
	$AudioStreamPlayer2D.stream = _sound_tension_on_the_line
	$AudioStreamPlayer2D.play()
	create_tween().tween_method(Callable(self, "_set_bobbing_depth"), _bobbing_depth, 5, 0.25)
	_line_slack = false
	
func _get_speed_multiple() -> float:
	if _player._stealth_state:
		return 1.75
	else:
		return 1.0

func retract(report_failure : bool) -> void:
	_line_slack = false
	if _bobbing_tween != null:
		_bobbing_tween.kill()
	_set_bobbing_depth(0)
	var tween : Tween = create_tween()
	var current_end : Vector2 = $PoleLine.get_point_position(1)
	var duration : float = casting_draw_back_time * _get_speed_multiple()
	
	_parabolic_velocity = _calculate_parabolic_velocity(Vector2.ZERO, $Floater.position, duration)
	_parabolic_start_point = $Floater.position
	_parabolic_time_span = duration
	_parabolic_time_remaining = duration
	
	var snap_pos : Vector2 = Vector2(0 - current_end.x, current_end.y)
	tween.tween_method(Callable(self, "_adjust_end_pos"), current_end, snap_pos, duration)
	tween.tween_callback(Callable(_player, "cancel_fishing_pole"))
	
	if _mini_game != null:
		if report_failure:
			_map_runner.get_report_card().add_failure(_mini_game)
		var cell : Vector2i = _map.local_to_map(_mini_game.position)
		_map_runner._expire_spawn_spot(cell)
		_mini_game = null
	
func retract_with_fish(fish_type : Fish) -> void:
	$Floater/Sprite2D.texture = fish_type.texture_image
	$Floater/Sprite2D.region_enabled = true
	$Floater/Sprite2D.region_rect = fish_type.texture_region
	$AudioStreamPlayer2D.stream = _sound_caught_fish
	$AudioStreamPlayer2D.play()
	_bobbing_image_height = fish_type.texture_region.size.y
	_map_runner.get_report_card().add_fish(fish_type, _map_runner.get_tier())
	retract(false)

func on_fish_escaped() -> void:
	if _mini_game != null:
		_map_runner.get_report_card().add_failure(_mini_game)
		_mini_game = null
	_line_slack = true
	_invoke_new_bobbing()

func _process(delta: float) -> void:
	if not $FishingLine.visible:
		return
		
	var floater_final_pos : Vector2 = _mouse_click_pos - position
	var delta_squared : float = delta * delta
	var pole_end : Vector2 = $PoleLine.get_point_position(1)
		
	if _parabolic_time_remaining > 0:
		_parabolic_time_remaining -= delta
		if _parabolic_time_remaining < 0:
			$Floater.position = floater_final_pos
			$AudioStreamPlayer2D.stream = _sound_floater_hits_water
			$AudioStreamPlayer2D.play()
			_bobbing_depth = 0
			_invoke_new_bobbing()
			
			for child in _map.get_children():
				if child is MiniGame:
					var mg : MiniGame = child as MiniGame
					if mg.register_pole(self):
						_register_mini_game(mg)
						break
		else:
			var elapsed_time : float = _parabolic_time_span - _parabolic_time_remaining
			$Floater.position = _parabolic_start_point + _parabolic_velocity * elapsed_time + GRAVITY * elapsed_time * elapsed_time / 2
	
	var line_pos : Array[Vector2]
	var number_of_line_segments : int = $FishingLine.get_point_count() - 1
	line_pos.append(pole_end)
	_prev_pos[0] = pole_end
	for i in range(1, number_of_line_segments):
		var pos : Vector2 = $FishingLine.get_point_position(i)
		var velocity = pos - _prev_pos[i]
		_prev_pos[i] = pos
		line_pos.append(pos + velocity + GRAVITY * delta_squared)
	line_pos.append($Floater.position)
	_prev_pos[number_of_line_segments] = $Floater.position
	
	var total_line_length : float = (floater_final_pos - pole_end).length()
	if _line_slack == true:
		total_line_length *= 1.1
	else:
		total_line_length /= 1.2
	var max_line_seg_length : float = total_line_length / number_of_line_segments
	
	for j in range(10):
		for i in range(0, number_of_line_segments):
			var line : Vector2 = line_pos[i + 1] - line_pos[i]
			var line_length : float = line.length()
			if line_length == 0:
				continue
			var diff : float = (line_length - max_line_seg_length) / line_length
			var offset : Vector2 = line * diff / 2
			if i > 0:
				line_pos[i] += offset
			if i + 1 < number_of_line_segments:
				line_pos[i + 1] -= offset
	for i in range(0, number_of_line_segments + 1):
		$FishingLine.set_point_position(i, line_pos[i])
