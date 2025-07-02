class_name MultipleScrollChoice extends ScrollDisplayBase

var _h_box_container : HBoxContainer
var _scroll_scene : PackedScene = preload("res://Scenes/scroll.tscn")

func do_callback() -> void:
    for child in _h_box_container.get_children():
        child.do_callback()

func _ready() -> void:
    _h_box_container = find_child("HBoxContainer") as HBoxContainer

func _generate_item(text : String) -> Control:
    var label : Label = Label.new()
    label.label_settings = LabelSettings.new()
    label.label_settings.font_color = Color(0,0,0)
    label.label_settings.font_size = 20
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var margin_container: MarginContainer = MarginContainer.new()
    margin_container.add_theme_constant_override("margin_left", 10)
    margin_container.add_theme_constant_override("margin_right", 10)
    margin_container.add_theme_constant_override("margin_bottom", 10)
    margin_container.add_theme_constant_override("margin_top", 10)
    margin_container.add_child(label)
    return margin_container

func add_text(scroll_layer : ScrollLayer, text : String, callback : Callable, x : float) -> void:
    var scroll : ScrollDisplay = _scroll_scene.instantiate()
    scroll.init(scroll_layer, _generate_item(text), callback)
    scroll._must_be_clicked = true
    scroll.position.x = x
    var h_box_container = find_child("HBoxContainer") as HBoxContainer
    h_box_container.add_child(scroll)

#func init(_scroll_layer : ScrollLayer, _item : Control, callback : Callable) -> void:
#    _callback = callback
