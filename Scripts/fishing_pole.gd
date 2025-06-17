class_name FishingPole extends Node2D

@export var casting_draw_back_time : float = 0.5
@export var casting_forward_time : float = 0.125
@export var casting_line_segments : int = 20
@export var casting_hang_time : float = 0.75

@export var _sound_floater_hits_water : AudioStream

const GRAVITY : Vector2 = Vector2.DOWN * 200.0

var _rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _mouse_click_pos : Vector2
var _map_cell : Vector2i
var _parabolic_velocity : Vector2
var _parabolic_time_remaining : float = 0
var _bobbing_depth : float = -1

func _ready() -> void:
    $Floater.hide()
    $FishingLine.hide()

func cast_line(player : Player, map : TileMapLayer) -> void:
    position = player.position
    _mouse_click_pos = map.get_local_mouse_position()
    _map_cell = map.local_to_map(_mouse_click_pos)
    var tween : Tween = create_tween()
    var current_end : Vector2 = $PoleLine.get_point_position(1)
    var snap_pos : Vector2 = Vector2(0 - current_end.x, current_end.y)
    tween.tween_method(Callable(self, "_adjust_end_pos"), current_end, snap_pos, casting_draw_back_time)
    tween.tween_method(Callable(self, "_adjust_end_pos"), snap_pos, current_end, casting_forward_time)
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

    #var tween : Tween = create_tween()
    #tween.tween_property($Floater, "position", target_pos, casting_hang_time)

    # parabolic arc from end of fishing pole to target position    
    var dx : float = target_pos.x - current_end.x
    var dy : float = target_pos.y - current_end.y
    var vx : float = dx / casting_hang_time
    var vy : float = (dy - GRAVITY.y * casting_hang_time * casting_hang_time / 2) / casting_hang_time
    _parabolic_velocity = Vector2(vx, vy)
    _parabolic_time_remaining = casting_hang_time

var _bobbing_tween : Tween
func _invoke_new_bobbing() -> void:
    _bobbing_tween = create_tween()
    var bob_transition_time : float = _rnd.randf_range(0.5, 1.5)
    var next_depth : float = _rnd.randf_range(0, 3.5)
    _bobbing_tween.tween_method(Callable(self, "_set_bobbing_depth"), _bobbing_depth, next_depth, bob_transition_time)
    _bobbing_tween.tween_interval(0.1)
    _bobbing_tween.tween_callback(Callable(self, "_invoke_new_bobbing"))

func _set_bobbing_depth(depth : float) -> void:
    #var old_depth = 5.0 - $Floater/Sprite2D.region_rect.size.y
    $Floater/Sprite2D.region_rect.size.y = 5.0 - depth
    $Floater.position.y += (depth - _bobbing_depth)
    _bobbing_depth = depth

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
        else:
            var elapsed_time : float = casting_hang_time - _parabolic_time_remaining
            $Floater.position = pole_end + _parabolic_velocity * elapsed_time + GRAVITY * elapsed_time * elapsed_time / 2
    
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
    
    var total_line_length : float = 1.1 * (floater_final_pos - pole_end).length()
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
