class_name ScrollDisplay extends Node2D

var _scroll_layer : ScrollLayer

func _process(_delta: float) -> void:
	if Input.is_action_just_released("click"):
		_scroll_layer.remove()

func stop_map_runner(scroll_layer : ScrollLayer) -> void:
	_scroll_layer = scroll_layer
