class_name ScrollDisplay extends Node2D

var _scroll_layer : ScrollLayer
var _click_cooldown : float = 0.1;
var _callback : Callable

func _process(delta: float) -> void:
	if _click_cooldown > 0:
		_click_cooldown -= delta
		return
	if Input.is_action_just_released("click"):
		_scroll_layer.remove()

func do_callback() -> void:
	if _callback.is_valid():
		_callback.call()

func init(scroll_layer : ScrollLayer, callback : Callable) -> void:
	_scroll_layer = scroll_layer
	_callback = callback
