extends StateMachineState

@onready var _light_circle : Node2D = $LightCircle
@onready var _game_label : Label = $Label
const SPEED : float = 300
var _forward : bool = true
var _falling : bool = true
var _leave_tween : Tween = null
var _can_leave : bool = false

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    const TEXTURE_OFFSET : float = 64 * 2
    var frac : float = (_light_circle.position.x + TEXTURE_OFFSET - _game_label.position.x) / _game_label.size.x
    
    var target_y = _game_label.position.y + (cos(4.0 * frac * PI) * _game_label.size.y / 4) - _game_label.size.y / 4
    if _falling:
        _light_circle.position.y += delta * SPEED
        if _light_circle.position.y + TEXTURE_OFFSET > target_y:
            _falling = false
    
    _light_circle.position.y = target_y
    
    if _forward == true:
        _light_circle.position.x += delta * SPEED
        if _light_circle.position.x + TEXTURE_OFFSET > _game_label.position.x + _game_label.size.x:
            _forward = false
            _can_leave = true
        return
    
    _light_circle.position.x -= delta * SPEED
    if _light_circle.position.x + TEXTURE_OFFSET < _game_label.position.x:
        _forward = true

func _input(event : InputEvent) -> void:
    _handle_event(event)

func _unhandled_input(event : InputEvent) -> void:
    _handle_event(event)

func _handle_event(event : InputEvent) -> void:
    # We process on "released" instead of pressed because otherwise immediately
    # switching screens could still have the mouse being pressed on some other
    # screen's button.
    if process_mode == ProcessMode.PROCESS_MODE_DISABLED:
        return

    if _can_leave == false:
        return;
        
    if _leave_tween == null:
        if event.is_released():
            var next_state : String = "SenseiHub"
            if event is InputEventKey:
                var keycode : Key = (event as InputEventKey).keycode
                match keycode:
                    Key.KEY_1:
                        next_state = "BeginnerFishing"
                    Key.KEY_2:
                        next_state = "AdvancedFishing"
                our_state_machine.switch_state(next_state)
            if event is InputEventMouseButton:
                our_state_machine.switch_state(next_state)

func exit_state(next_state: StateMachineState) -> void:
    if _leave_tween != null && _leave_tween.is_running():
        return

    _leave_tween = get_tree().create_tween()
    _leave_tween.tween_property(_light_circle.get_child(0), "scale", Vector2.ZERO, 1)
    var when_finished_callback : Callable = Callable(self, "_on_leave_tween_finished")
    _leave_tween.tween_callback(when_finished_callback.bind(next_state))

func _on_leave_tween_finished(next_state: StateMachineState) -> void:
    super.exit_state(next_state)
    _leave_tween = null
