class_name NoteObject extends Node2D

var _scroll_layer : ScrollLayer
var _map_runner : MapRunner
@export_multiline var _text : String

func _ready() -> void:
	var node = self
	while node != null && node is not MapRunner:
		node = node.get_parent()
	if node == null:
		print("%s must be under a MapRunner" % name)
		return
	_map_runner = node as MapRunner
	_scroll_layer = _map_runner.get_scroll_layer()

func _generate_container() -> Container:
	var margin_container: MarginContainer = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	var label : Label = Label.new()
	label.text = _text
	label.label_settings = LabelSettings.new()
	label.label_settings.font_color = Color(0,0,0)
	margin_container.add_child(label)
	return margin_container

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _map_runner.get_scroll_layer().is_active():
		return
		
	if event is not InputEventMouseButton:
		return
	
	var iemb : InputEventMouseButton = event as InputEventMouseButton	
	if iemb.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if not iemb.is_released():
		return
	
	_scroll_layer.display(_generate_container(), _map_runner._player)
