class_name InputScrollDisplay extends ScrollDisplayBase

var _scroll_layer : ScrollLayer
var _click_cooldown : float = 0.1;

func _process(delta: float) -> void:
        
    if _click_cooldown > 0:
        _click_cooldown -= delta
        return

    if Input.is_key_pressed(KEY_ENTER):
        _scroll_layer.remove()

func do_callback() -> void:
    if _callback.is_valid():
        _callback.call($MarginContainer/ContentsContainer/VBoxContainer/LineEdit.text)

func init(scroll_layer : ScrollLayer, _item : Control, callback : Callable) -> void:
    _scroll_layer = scroll_layer
    _callback = callback
    
func set_question(text : String) -> void:
    $MarginContainer/ContentsContainer/VBoxContainer/Label.text = text
    $MarginContainer/ContentsContainer.reset_size()
