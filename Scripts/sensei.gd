class_name Sensei extends Node2D

var _flip_facing_cooldown : float = 5
var _change_frame_cooldown : float = 2
var _rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _sprite : Sprite2D
var _player_has_smokebombed : bool = false
var _map_runner : MapRunner
var _scroll_layer : ScrollLayer

enum ProgressionStage { PreIntroduction, PreFirstCatch, PreThreePonds, PreHorseshoe, Graduated }

func _ready() -> void:
	_sprite = find_child("Sprite2D") as Sprite2D
	var node = self
	while node != null && node is not MapRunner:
		node = node.get_parent()
	if node == null:
		print("%s must be under a MapRunner" % name)
		return
	_map_runner = node as MapRunner
	_scroll_layer = _map_runner.get_scroll_layer()

func generate_label(text : String) -> Control:
	var label : Label = Label.new()
	label.text = text
	label.label_settings = LabelSettings.new()
	label.label_settings.font_color = Color(0,0,0);
	label.label_settings.font_size = 20
	var margin_container: MarginContainer = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_child(label)
	return margin_container

func trigger_dialog() -> void:
	var labels : Array[Control] = []
	labels.append(generate_label("You have come to me to master ninja fishing."))
	labels.append(generate_label("I am California Sensei, and I am hella good at ninja fishing."))
	labels.append(generate_label("Attend me, my dude."))
	labels.append(generate_label("Walk to my pond just to the east."))
	labels.append(generate_label("Return when you have caught two fish."))
	_scroll_layer.display_series(labels, _map_runner._player)

func evaluate_report_card() -> bool:
	var report_card : ReportCard = _map_runner.get_report_card()
	return false

func _process(delta: float) -> void:
	_flip_facing_cooldown -= delta
	if _flip_facing_cooldown < 0:
		_flip_facing_cooldown = _rnd.randf_range(5, 15)
		_sprite.flip_h = !_sprite.flip_h
	
	_change_frame_cooldown -= delta
	if _change_frame_cooldown < 0:
		_change_frame_cooldown = _rnd.randf_range(1, 5)
		_sprite.frame = _rnd.randi() % _sprite.hframes

func _on_static_body_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _map_runner.get_scroll_layer().is_active():
		return
		
	if event is not InputEventMouseButton:
		return
	
	var iemb : InputEventMouseButton = event as InputEventMouseButton	
	if iemb.button_index != MOUSE_BUTTON_LEFT:
		return

	if not iemb.is_released():
		return
	
	if evaluate_report_card():
		return
		
	trigger_dialog()
