extends StateMachineState

@onready var _light_circle : Node2D = $LightCircle
@onready var _game_label : Label = $Label
const SPEED : float = 300
var _forward : bool = true
var _falling : bool = true

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	const TEXTURE_OFFSET : float = 64 * 2
	var frac : float = (_light_circle.position.x + TEXTURE_OFFSET - _game_label.position.x) / _game_label.size.x
	
	var target_y = _game_label.position.y + (cos(4.0 * frac * PI) * _game_label.size.y / 2) - _game_label.size.y / 4
	if _falling:
		_light_circle.position.y += delta * SPEED
		if _light_circle.position.y + TEXTURE_OFFSET > target_y:
			_falling = false
	
	_light_circle.position.y = target_y
	
	if _forward == true:
		_light_circle.position.x += delta * SPEED
		if _light_circle.position.x + TEXTURE_OFFSET > _game_label.position.x + _game_label.size.x:
			_forward = false
		return
	
	_light_circle.position.x -= delta * SPEED
	if _light_circle.position.x + TEXTURE_OFFSET < _game_label.position.x:
		_forward = true
