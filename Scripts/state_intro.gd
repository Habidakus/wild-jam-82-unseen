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
var _high_score_enabled : bool = false

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
            
            _high_score_enabled = true
                
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
        if _high_score_enabled:
            choices.append(["High\nScores", Callable(self, "_show_high_scores")])
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

func _show_high_scores(_was_clicked_on : bool) -> void:
    if not _was_clicked_on:
        return
                
    var series : Array[Node] = []
    var sw_result: Dictionary = await SilentWolf.Scores.get_scores(500).sw_get_scores_complete
    if not sw_result.has("scores"):
        series.append(generate_label("An error has occured fetching the high scores."))
        %ScrollLayer.display_series_with_callback(series, null, Callable(self, "_on_credits_done"))
        return

    var local_player_name : String = ReportCard.read_local_player_name()
    var track_player_with_oni : Dictionary = {}
    var track_player_casual : Dictionary = {}
    var scores_with_oni : Array = []
    var scores_casual : Array = []
    for entry in sw_result["scores"]:
        var player_name : String = entry["player_name"]
        if entry["metadata"]["oni_guards"]:
            if not track_player_with_oni.has(player_name):
                track_player_with_oni[player_name] = true
                scores_with_oni.append([player_name, entry["score"], entry["metadata"]])
        else:
            if not track_player_casual.has(player_name):
                track_player_casual[player_name] = true
                scores_casual.append([player_name, entry["score"], entry["metadata"]])

    if not scores_with_oni.is_empty():
        series.append(generate_scoreboard(true, scores_with_oni, local_player_name))
    if not scores_casual.is_empty():
        series.append(generate_scoreboard(false, scores_casual, local_player_name))
    %ScrollLayer.display_series_with_callback(series, null, Callable(self, "_on_credits_done"))

func _show_credits(_was_clicked_on : bool) -> void:
    if _was_clicked_on:
        var series : Array[Node] = []
        series.append(generate_label("Sprites and Tile Art from:\n\n- https://cyberrumor.itch.io\n- https://deepdivegamestudio.itch.io\n- https://gfragger.itch.io\n- https://danieldiggle.itch.io\n- https://kenmi-art.itch.io\n- https://shubibubi.itch.io\n- https://govfx.itch.io"))
        series.append(generate_label("Map Music was from https://www.FesliyanStudios.com\nVarious in game SFX from https://zapsplat.com"))
        series.append(generate_label("Fonts from https://www.fontspace.com/gang-of-three-font-f46138"))
        series.append(generate_label("Thanks to our playtesters:\n\n-Mister Zeus\n-dredwngs\n-Steven (Stick) Olguin\n-Andy Collins\n-Ziro Cool\n-Oxdottir"))
        %ScrollLayer.display_series_with_callback(series, null, Callable(self, "_on_credits_done"))

func _generate_label(text : String) -> Label:
    var label : Label = Label.new()
    label.text = text
    label.label_settings = LabelSettings.new()
    label.label_settings.font_color = Color(0,0,0);
    label.label_settings.font_size = 20
    return label

func _generate_score_notes(notes : Dictionary) -> String:
    var ret_val : String = ""
    var unique_fish = int(round(notes["unique_fish"]))
    if unique_fish < 2:
        ret_val = "same fish"
    else:
        ret_val = str(unique_fish) + " unique fish"
    if notes["witnessed"] == "unseen" && notes["oni_guards"]:
        ret_val += ", unseen"
    if notes["missed_fish"] == 0:
        ret_val += ", prefect stance"
    if notes["spoiled"]:
        ret_val += ", spoiled"
    return ret_val

func generate_scoreboard(with_oni : bool, scores: Array, local_player_name : String) -> Control:
    var vbox : VBoxContainer = VBoxContainer.new()
    var label : Label
    if with_oni:
        label = _generate_label("Against Oni Guards")
    else:
        label = _generate_label("Casual Fishing")
    vbox.add_child(label)

    var bar : HSeparator = HSeparator.new()
    vbox.add_child(bar)

    var grid : GridContainer = GridContainer.new()    
    grid.columns = 4
    
    grid.add_child(_generate_label("Score"))
    grid.add_child(_generate_label("Name"))
    grid.add_child(_generate_label("Weight"))
    grid.add_child(_generate_label("Notes"))
            
    var i : int = 0
    var seen_local_player : int = 0
    while i < 10 and not scores.is_empty():
        var entry : Array = scores[0]
        scores = scores.slice(1)
        
        if entry[0] == local_player_name:
            grid.add_child(_generate_label(str(round(entry[1]))))
            grid.add_child(_generate_label(local_player_name))
            var weight : float = entry[2]["total_weight"]
            grid.add_child(_generate_label(ReportCard.get_weight_as_text(weight)))
            grid.add_child(_generate_label(_generate_score_notes(entry[2])))
            seen_local_player = 1
            i += 1
        elif i < 9 + seen_local_player:
            grid.add_child(_generate_label(str(round(entry[1]))))
            grid.add_child(_generate_label(entry[0]))
            var weight : float = entry[2]["total_weight"]
            grid.add_child(_generate_label(ReportCard.get_weight_as_text(weight)))
            grid.add_child(_generate_label(_generate_score_notes(entry[2])))
            i += 1
    vbox.add_child(grid)
    
    var margin_container: MarginContainer = MarginContainer.new()
    margin_container.add_theme_constant_override("margin_left", 10)
    margin_container.add_theme_constant_override("margin_right", 10)
    margin_container.add_theme_constant_override("margin_bottom", 10)
    margin_container.add_theme_constant_override("margin_top", 10)
    margin_container.add_child(vbox)
    return margin_container

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
