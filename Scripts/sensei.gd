class_name Sensei extends Node2D

var _flip_facing_cooldown : float = 5
var _change_frame_cooldown : float = 2
var _rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _sprite : Sprite2D

func _ready() -> void:
	_sprite = find_child("Sprite2D") as Sprite2D

func _process(delta: float) -> void:
	_flip_facing_cooldown -= delta
	if _flip_facing_cooldown < 0:
		_flip_facing_cooldown = _rnd.randf_range(5, 15)
		_sprite.flip_h = !_sprite.flip_h
	
	_change_frame_cooldown -= delta
	if _change_frame_cooldown < 0:
		_change_frame_cooldown = _rnd.randf_range(1, 5)
		_sprite.frame = _rnd.randi() % _sprite.hframes
