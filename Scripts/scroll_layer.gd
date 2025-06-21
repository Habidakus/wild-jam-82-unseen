class_name ScrollLayer extends CanvasLayer

var _scroll_object : ScrollDisplay
var _scroll_scene : PackedScene = preload("res://Scenes/scroll.tscn")
var _player : Player
var _queue : Array[Array] = []

func _ready() -> void:
	hide()

func is_active() -> bool:
	return _scroll_object != null

func display_series(items: Array[Control], player : Player) -> void:
	for c :Control in items:
		_queue.append([c, player])
	remove()

func display(item : Control, player : Player) -> void:
	if _scroll_object != null:
		_scroll_object.queue_free()
	
	_player = player
	_scroll_object = _scroll_scene.instantiate()
	_scroll_object.stop_map_runner(self)
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
		_player.inhibit_mouse_release(0.1)
		_scroll_object.queue_free()
		_scroll_object = null

	if _queue.size() > 0:
		display(_queue[0][0], _queue[0][1])
		_queue = _queue.slice(1)
