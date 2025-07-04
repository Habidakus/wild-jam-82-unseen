extends StateMachineState

@onready var _light_circle : Node2D = $LightCircle
@onready var _game_label : Label = $Label
const SPEED : float = 300
var _forward : bool = true
var _falling : bool = true
var _leave_tween : Tween = null
var _can_leave : bool = false
var _show_click_to_advance : bool = false
var _use_oni : bool = true

func _ready() -> void:
    var sw_resource : String = "res://Data/SilentWolfId.tres"
    if ResourceLoader.exists(sw_resource):
        var swid_data : SilentWolfId = ResourceLoader.load(sw_resource)
        if !swid_data.api_key.is_empty():
            SilentWolf.configure({
                "api_key": swid_data.api_key,
                "game_id": swid_data.game_id,
                "log_level": 1
            })
            
            var sw_result: Dictionary = await SilentWolf.Scores.get_scores(10).sw_get_scores_complete
            if sw_result.has("scores"):
                for entry in sw_result["scores"]:
                    print(str(entry["player_name"]) + ": " + str(entry["score"]) + ", " + str(entry["metadata"]))
                
func _process(delta: float) -> void:
    const TEXTURE_OFFSET : float = 64 * 2
    var frac : float = (_light_circle.position.x + TEXTURE_OFFSET - _game_label.position.x) / _game_label.size.x
    
    var target_y = _game_label.position.y + (cos(4.0 * frac * PI) * _game_label.size.y / 4) - _game_label.size.y / 4
    if _falling:
        _light_circle.position.y += delta * SPEED
        if _light_circle.position.y + TEXTURE_OFFSET > target_y:
            _falling = false
    
    _light_circle.position.y = target_y
    
    if _forward == true:
        _light_circle.position.x += delta * SPEED
        if _light_circle.position.x + TEXTURE_OFFSET > _game_label.position.x + _game_label.size.x:
            _forward = false
            _can_leave = true
            _show_buttons()
        return
    
    _light_circle.position.x -= delta * SPEED
    if _light_circle.position.x + TEXTURE_OFFSET < _game_label.position.x:
        _forward = true

func _show_buttons() -> void:
    if _show_click_to_advance == false:
        _show_click_to_advance = true
        var choices : Array = []
        choices.append(["Play\nWith Oni", Callable(self, "_play_with_oni")])
        choices.append(["Play\nCasual", Callable(self, "_play_without_oni")])
        choices.append(["Credits", Callable(self, "_show_credits")])
        %ScrollLayer.display_choices(choices, null)
        #%ScrollLayer.display_with_callback("The journey of a thousand miles\nbegins with a mouse click.", null, Callable(self, "_advance"))

func _input(event : InputEvent) -> void:
    _handle_event(event)

func _unhandled_input(event : InputEvent) -> void:
    _handle_event(event)

func _handle_event(_event : InputEvent) -> void:
    # We process on "released" instead of pressed because otherwise immediately
    # switching screens could still have the mouse being pressed on some other
    # screen's button.
    if process_mode == ProcessMode.PROCESS_MODE_DISABLED:
        return

    if _can_leave == false:
        return;
        
    #if _leave_tween == null:
        #if event.is_released():
            #if event is InputEventKey:
                #_advance(false)
            #elif event is InputEventMouseButton:
                #_advance(false)

#func _advance(_was_clicked_on : bool) -> void:
    #print("_advance(" + str(_was_clicked_on) + ")")
    #our_state_machine.switch_state("SenseiHub")
    
func _play_with_oni(_was_clicked_on : bool) -> void:
    if _was_clicked_on:
        _show_click_to_advance = false
        _use_oni = true
        our_state_machine.switch_state("SenseiHub")

func _play_without_oni(_was_clicked_on : bool) -> void:
    if _was_clicked_on:
        _show_click_to_advance = false
        _use_oni = false
        our_state_machine.switch_state("SenseiHub")

func _show_credits(_was_clicked_on : bool) -> void:
    if _was_clicked_on:
        var series : Array[Node] = []
        series.append(generate_label("Sprites and Tile Art from:\n\n- https://cyberrumor.itch.io\n- https://deepdivegamestudio.itch.io\n- https://gfragger.itch.io\n- https://danieldiggle.itch.io\n- https://kenmi-art.itch.io\n- https://shubibubi.itch.io\n- https://govfx.itch.io"))
        series.append(generate_label("Map Music was from https://www.FesliyanStudios.com\nVarious in game SFX from https://zapsplat.com"))
        series.append(generate_label("Fonts from https://www.fontspace.com/gang-of-three-font-f46138"))
        series.append(generate_label("Thanks to our playtesters:\n\n-Mister Zeus\n-dredwngs\n-Steven (Stick) Olguin\n-Andy Collins\n-Ziro Cool\n-Oxdottir"))
        %ScrollLayer.display_series_with_callback(series, null, Callable(self, "_on_credits_done"))
        
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

func _on_credits_done(_ignore : bool) -> void:
    _show_click_to_advance = false
    call_deferred("_show_buttons")
    
func exit_state(next_state: StateMachineState) -> void:
    if _leave_tween != null && _leave_tween.is_running():
        return
    
    if next_state is MapRunner:
        (next_state as MapRunner)._use_oni = _use_oni

    _leave_tween = get_tree().create_tween()
    _leave_tween.tween_property(_light_circle.get_child(0), "scale", Vector2.ZERO, 1)
    var when_finished_callback : Callable = Callable(self, "_on_leave_tween_finished")
    _leave_tween.tween_callback(when_finished_callback.bind(next_state))

func _on_leave_tween_finished(next_state: StateMachineState) -> void:
    super.exit_state(next_state)
    _leave_tween = null
