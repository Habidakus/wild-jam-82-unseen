class_name Sensei extends Node2D

var _flip_facing_cooldown : float = 5
var _change_frame_cooldown : float = 2
var _rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _sprite : Sprite2D
var _player_has_smokebombed : bool = false
var _map_runner : MapRunner
var _scroll_layer : ScrollLayer

enum ProgressionStage { PreIntroduction, PreThreePonds, PreHorseshoe, PreGraduated, Graduated }
var _stage : ProgressionStage = ProgressionStage.PreIntroduction

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

func send_intro_dialog() -> void:
	var labels : Array[Control] = []
	labels.append(generate_label("You have come to me to master ninja fishing."))
	labels.append(generate_label("I am California Sensei, and I am hella good at ninja fishing."))
	labels.append(generate_label("Attend me, my dude."))
	labels.append(generate_label("Walk to my pond just to the east."))
	labels.append(generate_label("Return when you have caught two fish."))
	_scroll_layer.display_series(labels, _map_runner._player)
	_stage = ProgressionStage.PreThreePonds

func push_three_ponds_dialog() -> void:
	var labels : Array[Control] = []
	labels.append(generate_label("The real journey now begins."))
	labels.append(generate_label("Head north to Three Ponds area."))
	labels.append(generate_label("Catch five fish and return."))
	labels.append(generate_label("But beware the patrolling Oni,\nalways listen for their approach."))
	labels.append(generate_label("Practice the way of the SPACE BAR\nto be extra stealthy."))
	_scroll_layer.display_series(labels, _map_runner._player)
	_stage = ProgressionStage.PreHorseshoe

func push_horseshoe_dialog() -> void:
	var labels : Array[Control] = []
	labels.append(generate_label("It is now time to cruise south and fish horseshoe lake."))
	labels.append(generate_label("It is hella difficult."))
	labels.append(generate_label("Bring me five dank fish unruined by smoke and you will have mastered ninja fishing."))
	_scroll_layer.display_series(labels, _map_runner._player)
	_stage = ProgressionStage.PreGraduated

func push_graduation_dialog() -> void:
	var labels : Array[Control] = []
	labels.append(generate_label("You have mastered ninja fishing."))
	labels.append(generate_label("You are legit."))
	labels.append(generate_label("... and also rad."))
	_scroll_layer.display_series(labels, _map_runner._player)
	_stage = ProgressionStage.Graduated

func push_need_x_fish_dialog(required_no : int) -> void:
	var labels : Array[Control] = []
	labels.append(generate_label("You will need to bring me %s fish at once." % required_no))
	_scroll_layer.display_series(labels, _map_runner._player)

func push_smokebomb_dialog(has_any_fish : bool) -> void:
	var labels : Array[Control] = []
	if _player_has_smokebombed:
		match _rnd.randi() % 7:
			0:
				labels.append(generate_label("Be as silent as a Friday night in Modesto."))
			1:
				labels.append(generate_label("Be as still at the Pacific at low tide."))
			2:
				labels.append(generate_label("Before casting, listen closely to your inner child."))
			3:
				labels.append(generate_label("Perhaps, bait the hook with some avocado?\nHowever, I am out of both avocado and toast."))
			4:
				labels.append(generate_label("The oni are stoked about your failure."))
			5:
				labels.append(generate_label("Like any trip on the 101, this is taking longer than expected."))
			6:
				labels.append(generate_label("We need gnarly fish unruined by smoke."))
		if has_any_fish:
			labels.append(generate_label("These fish are ruined, my dude.\nTry Again!"))
	else:
		labels.append(generate_label("Your skills will always let you evade the Oni."))
		labels.append(generate_label("You slip away like a tech CEO evading taxes."))
		labels.append(generate_label("But any hit of smoke ruins the nuances of flavor found in ninja fish."))
		if has_any_fish:
			labels.append(generate_label("These fish are ruined, my dude."))
		_scroll_layer.display_series(labels, _map_runner._player)
		_player_has_smokebombed = true

func evaluate_report_card() -> bool:
	var report_card : ReportCard = _map_runner.get_report_card()
	if report_card != null:
		if report_card.has_progress():
			report_card._finished = true
			_scroll_layer.display_series([generate_label("Lets see how you did:"), report_card.get_as_container()], _map_runner._player)
			if report_card._smoke_bomb_escape == true:
				push_smokebomb_dialog(report_card._fish.size() > 0)
			var unlock : int = report_card.what_tier_does_report_unlock()
			if _stage == ProgressionStage.PreThreePonds:
				if unlock > 0:
					push_three_ponds_dialog()
				else:
					push_need_x_fish_dialog(2)
			elif _stage == ProgressionStage.PreHorseshoe:
				if unlock > 1:
					push_horseshoe_dialog()
				else:
					push_need_x_fish_dialog(5)
			elif _stage == ProgressionStage.PreGraduated:
				if unlock > 2:
					push_graduation_dialog()
				else:
					push_need_x_fish_dialog(5)
			report_card.clear()
			return true
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
		
	if _stage == ProgressionStage.PreIntroduction:
		send_intro_dialog()
		return
	
	if evaluate_report_card():
		return
