class_name ScrollDisplay extends Node2D

var _scroll_layer : ScrollLayer
var _click_cooldown : float = 0.1;
var _callback : Callable
var _regular_vertical_size : float = -1
var _hover_vertical_size : float
var _label : Control
var _hover : bool = false
var _must_be_clicked : bool = false
var _unroll_speed : float = 300.0

func _process(delta: float) -> void:
    if _label.size.y != 0:
        if _hover:
            if _label.custom_minimum_size.y == 0:
                _label.custom_minimum_size.y = _label.size.y
            var advance : float = _unroll_speed * delta
            var size_diff : float = _hover_vertical_size - _label.custom_minimum_size.y
            if size_diff < advance:
                _label.custom_minimum_size.y = _hover_vertical_size
            else:
                _label.custom_minimum_size.y = _label.size.y + advance
        elif _regular_vertical_size < 0:
            _regular_vertical_size = _label.size.y
            _hover_vertical_size = _regular_vertical_size + 40
        elif _label.size.y != _regular_vertical_size:
            var advance : float = _unroll_speed * delta
            var size_diff : float = _label.custom_minimum_size.y - _regular_vertical_size
            if size_diff < advance:
                _label.custom_minimum_size.y = 0
                _label.size.y = _regular_vertical_size
            else:
                _label.custom_minimum_size.y -= advance
                _label.size.y = _label.custom_minimum_size.y
        else:
            _regular_vertical_size = _label.size.y
            _hover_vertical_size = _regular_vertical_size + 40

    if _click_cooldown > 0:
        _click_cooldown -= delta
        return

    if Input.is_action_just_released("click"):
        _scroll_layer.remove()

func do_callback() -> void:
    if _callback.is_valid():
        _callback.call(_hover)
        
func _ready() -> void:
    _label = $MarginContainer/ContentsContainer
    assert(_label != null)

func init(scroll_layer : ScrollLayer, callback : Callable) -> void:
    _scroll_layer = scroll_layer
    _callback = callback

func _on_margin_container_mouse_entered() -> void:
    if _must_be_clicked:
        _hover = true

func _on_margin_container_mouse_exited() -> void:
    _hover = false
