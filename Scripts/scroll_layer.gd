class_name ScrollLayer extends CanvasLayer

var _scroll_object : Node2D
var _scroll_scene : PackedScene = preload("res://Scenes/scroll.tscn")

func _ready() -> void:
	hide()

func display(item : Control) -> void:
	_scroll_object = _scroll_scene.instantiate()
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
	_scroll_object.queue_free()
	_scroll_object = null
