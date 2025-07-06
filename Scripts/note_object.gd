class_name NoteObject extends Node2D

var _scroll_layer : ScrollLayer
var _map_runner : MapRunner
@export_multiline var _text : String
@export var _highscore_object : bool = false
@export var _flip_h : bool = false

func _ready() -> void:
    var node = self
    while node != null && node is not MapRunner:
        node = node.get_parent()
    if node == null:
        print("%s must be under a MapRunner" % name)
        return
    _map_runner = node as MapRunner
    _scroll_layer = _map_runner.get_scroll_layer()
    if _flip_h == true:
        var sprite : Sprite2D = find_child("Sprite2D") as Sprite2D
        sprite.flip_h = true

func _generate_container() -> Container:
    var margin_container: MarginContainer = MarginContainer.new()
    margin_container.add_theme_constant_override("margin_left", 10)
    margin_container.add_theme_constant_override("margin_right", 10)
    margin_container.add_theme_constant_override("margin_bottom", 10)
    margin_container.add_theme_constant_override("margin_top", 10)
    if _highscore_object:
        var hsc = await _generate_high_score_container()
        margin_container.add_child(hsc)
    else:
        margin_container.add_child(_generate_text_container())
    return margin_container

func _generate_high_score_container() -> Control:
    var high_scores_pair : Array = await StateIntro.generate_high_score_dictionaries()
    var high_score_list : Array
    if _map_runner._use_oni:
        high_score_list = high_scores_pair[0]
    else:
        high_score_list = high_scores_pair[1]
    
    var local_player_name : String = ReportCard.read_local_player_name()
    return StateIntro.generate_scoreboard(_map_runner._use_oni, high_score_list, local_player_name)

func _generate_text_container() -> Control:
    var label : Label = Label.new()
    label.text = _text
    label.label_settings = LabelSettings.new()
    label.label_settings.font_color = Color(0,0,0)
    label.label_settings.font_size = 20
    return label

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
    
    var container = await _generate_container()
    _scroll_layer.display(container, _map_runner._player)

var _glow_tween : Tween
func _run_glow_tween(color : Color) -> void:
    if _glow_tween != null && _glow_tween.is_running():
        _glow_tween.kill()
    _glow_tween = create_tween()
    _glow_tween.tween_property(self, "modulate", color, 0.25)

func _on_static_body_2d_mouse_entered() -> void:
    Input.set_default_cursor_shape(Input.CURSOR_HELP)
    _run_glow_tween(Color(1.5, 1.5, 1.0))

func _on_static_body_2d_mouse_exited() -> void:
    Input.set_default_cursor_shape(Input.CURSOR_ARROW)
    _run_glow_tween(Color(1.0, 1.0, 1.0))
