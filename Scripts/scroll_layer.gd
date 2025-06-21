class_name ScrollLayer extends CanvasLayer

var _scroll_object : ScrollDisplay
var _scroll_scene : PackedScene = preload("res://Scenes/scroll.tscn")
var _player : Player
var _queue : Array[Array] = []

func _ready() -> void:
	hide()

func is_active() -> bool:
	return _scroll_object != null

func display_with_callback(text : String, player : Player, callback : Callable) -> void:
	var label : Label = Label.new()
	label.label_settings = LabelSettings.new()
	label.label_settings.font_color = Color(0,0,0)
	label.label_settings.font_size = 20
	label.text = text
	var margin_container: MarginContainer = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_child(label)
	_display_internal(margin_container, player, callback)

func display_line(text : String, player : Player) -> void:
	display_with_callback(text, player, Callable())

func display_series(items: Array[Control], player : Player) -> void:
	for c :Control in items:
		_queue.append([c, player])
	
	if _queue.size() > 0:
		if not is_active():
			display(_queue[0][0], _queue[0][1])
			_queue = _queue.slice(1)

func display(item : Control, player : Player) -> void:
	_display_internal(item, player, Callable())

func _display_internal(item : Control, player : Player, callable : Callable) -> void:
	#if _scroll_object != null:
		#_scroll_object.queue_free()
	
	if _scroll_object == null:
		_player = player
		_scroll_object = _scroll_scene.instantiate()
		_scroll_object.init(self, callable)
		var contents_container : Container = _scroll_object.find_child("ContentsContainer")
		for child in contents_container.get_children():
			contents_container.remove_child(child)
		contents_container.add_child(item)
		contents_container.reset_size()
		add_child(_scroll_object)
		_scroll_object.position = get_viewport().get_visible_rect().size / 2
		show()

func remove() -> void:
	hide()
	if _scroll_object != null:
		if _player != null:
			_player.inhibit_mouse_release(0.1)
		_scroll_object.do_callback()
		_scroll_object.queue_free()
		_scroll_object = null

	if _queue.size() > 0:
		display(_queue[0][0], _queue[0][1])
		_queue = _queue.slice(1)
