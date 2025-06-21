class_name ReportCard extends Node

var _fish : Array[Array] = []
var _failures : Array[Fish] = []
var _rnd : RandomNumberGenerator
var _total_time : float = -1
var _finished : bool = false
var _smoke_bomb_escape : bool = false
var _times_heard : int = 0
var _times_seen : int = 0

func have_smoke_bombed() -> bool:
	return _smoke_bomb_escape

func what_tier_does_report_unlock() -> int:
	if _smoke_bomb_escape:
		return 0
	if _fish.size() < 2:
		return 0
	if _fish.size() < 5:
		return 1
	var lowest_tier_caught : int = 100
	for tuple in _fish:
		var tier : int = tuple[2]
		if tier < lowest_tier_caught:
			lowest_tier_caught = tier
	return lowest_tier_caught + 1

func get_image_from_fish_type(fish_type : Fish) -> TextureRect:
	var atlas : AtlasTexture = AtlasTexture.new()
	atlas.atlas = fish_type.texture_image
	atlas.region = fish_type.texture_region
	var image : TextureRect = TextureRect.new()
	image.texture = atlas
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	image.custom_minimum_size = fish_type.texture_region.size
	image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return image

func get_ounce_string(ounces : int, eighths: int) -> String:
	if eighths == 0:
		return "%s" % ounces
	elif eighths == 4:
		return "%s 1/2 " % ounces
	elif eighths == 2:
		return "%s 1/4 " % ounces
	elif eighths == 6:
		return "%s 3/4 " % ounces
	else:
		return "%s %s/8" % [ounces, eighths]

func get_total_weight(fish_type : Fish, score : float) -> float:
	return (fish_type.max_weight_in_pounds - fish_type.min_weight_in_pounds) * score + fish_type.min_weight_in_pounds
	
func get_fish_weight_label(fish_type : Fish, score : float) -> Label:
	var pounds : float = get_total_weight(fish_type, score)
	return get_weight_as_label(pounds)

func get_weight_as_label(pounds : float) -> Label:
	if pounds == 0:
		return get_text_as_label("zero")
	var total : int = int(round(pounds * 8.0 * 16.0))
	var eighths : int = total % 8
	total = round((total - eighths) / 8.0)
	var ounces : int = total % 16
	total = round((total - ounces) / 16.0)
	var ipounds : int = total
	var text : String = ""
	if ipounds > 1:
		text = "%s pounds" % ipounds
	elif ipounds == 1:
		text = "1 pound"
	if ounces > 0 or eighths > 0:
		if text.length() > 0:
			text += ", %s oz" % get_ounce_string(ounces, eighths)
		else:
			text = "%s ounces" % get_ounce_string(ounces, eighths)
	if text.length() == 0:
		text = "1/16 ounce"
	return get_text_as_label(text)

func get_text_as_label(text : String) -> Label:
	var name_label : Label = Label.new()
	name_label.label_settings = LabelSettings.new()
	name_label.label_settings.font_color = Color(0,0,0)
	name_label.label_settings.font_size = 20
	name_label.text = text
	return name_label

func has_progress() -> bool:
	if _smoke_bomb_escape:
		return true
	if _fish.size() > 0:
		return true
	if _failures.size() > 0:
		return true
	if _times_heard + _times_seen > 0:
		return true
	return false

func get_as_container() -> Container:
	var grid_container : GridContainer = GridContainer.new()
	grid_container.columns = 4
	for tuple in _fish:
		var fish_type: Fish = tuple[0]
		var score : float = tuple[1]
		grid_container.add_child(get_image_from_fish_type(fish_type))
		grid_container.add_child(get_text_as_label(fish_type.player_facing_name))
		grid_container.add_child(get_text_as_label(" - "))
		if _smoke_bomb_escape:
			grid_container.add_child(get_text_as_label("spoiled"))
		else:
			grid_container.add_child(get_fish_weight_label(fish_type, score))
	
	var fish_weight : float = 0
	var vbox : VBoxContainer = VBoxContainer.new()
	vbox.add_child(get_text_as_label("Evaluation:"))
	if grid_container.get_child_count() > 0:
		vbox.add_child(grid_container)
		if _smoke_bomb_escape == false:
			for entry in _fish:
				fish_weight += get_total_weight(entry[0], entry[1])
	else:
		grid_container.queue_free()
	
	var score_grid : GridContainer = GridContainer.new()
	score_grid.columns = 2
	score_grid.add_child(get_text_as_label("Total Catch:"))
	score_grid.add_child(get_weight_as_label(fish_weight))
	score_grid.add_child(get_text_as_label("Stealth:"))
	if _times_heard == 0 && _times_seen == 0:
		if fish_weight == 0:
			score_grid.add_child(get_text_as_label("Untested"))
		else:
			score_grid.add_child(get_text_as_label("Perfect"))
	elif _times_seen == 0:
		if _times_heard == 1:
			score_grid.add_child(get_text_as_label("Heard just once"))
		else:
			score_grid.add_child(get_text_as_label("Heard"))
	elif _times_seen < 100:
		score_grid.add_child(get_text_as_label("Glimsed"))
	elif _times_seen > 750:
		score_grid.add_child(get_text_as_label("Appalling"))
	else:
		score_grid.add_child(get_text_as_label("Seen"))
	
	vbox.add_child(score_grid)
	
	var margin_container: MarginContainer = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_child(vbox)
	return margin_container

func clear() -> void:
	_fish.clear()
	_failures.clear()
	_total_time = 0
	_finished = false
	_smoke_bomb_escape = false
	_times_heard = 0
	_times_seen = 0
	
func have_caught_your_limit() -> bool:
	return _fish.size() >= 5

func start(rnd_seed : int) -> void:
	_rnd = RandomNumberGenerator.new()
	_rnd.seed = rnd_seed
	_total_time = 0
	
func _process(delta: float) -> void:
	if not _finished:
		_total_time += delta
	
func add_heard() -> void:
	_times_heard += 1

func add_seen() -> void:
	_times_seen += 1

func add_smoke_bomb_escape() -> void:
	_smoke_bomb_escape = true

func add_failure(fish_type : Fish) -> void:
	print("Player failed to catch a %s" % fish_type.player_facing_name)
	_failures.append(fish_type)

func _generate_fish_score() -> float:
	var ret_val : float = 10
	for i in range(0, 3):
		var v : float = _rnd.randf_range(0.0, 1.0)
		if abs(v - 0.33) < abs(ret_val - 0.33):
			ret_val = v
	return ret_val

func add_fish(fish_type : Fish, tier : int) -> void:
	_fish.append([fish_type, _generate_fish_score(), tier])
