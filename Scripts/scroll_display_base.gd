class_name ScrollDisplayBase extends Node2D

var _callback : Callable

func do_callback() -> void:
    if _callback.is_valid():
        _callback.call(false)

func init(_scroll_layer : ScrollLayer, _item : Control, callback : Callable) -> void:
    assert(false, "Only scroll_display.gd supports init() call")
    _callback = callback
