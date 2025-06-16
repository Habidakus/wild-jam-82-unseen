extends StateMachineState

@export var _fish : Array[Fish] = []
@export var _music_track : AudioStream
@export var _number_of_fish : int = 5
@onready var _map : TileMapLayer = $IntroArea

var _player : Player = null
var _player_scene : PackedScene = preload("res://Scenes/player.tscn")
var _debug_dot_scene : PackedScene = preload("res://Scenes/debug_dot.tscn")
var _fish_spawn_scene : PackedScene = preload("res://Scenes/fish_spawn.tscn")

var shallows : Array[Vector2i]
var medium : Array[Vector2i]
var deep : Array[Vector2i]
	
func _on_music_finished() -> void:
	%MusicPlayer.play()

func exit_state(next_state: StateMachineState) -> void:
	if 	%MusicPlayer.finished.is_connected(_on_music_finished):
		%MusicPlayer.finished.disconnect(_on_music_finished)
	
	super.exit_state(next_state)
	
func enter_state() -> void:
	super.enter_state()
	
	_player = _player_scene.instantiate();
	_player.position = _map.map_to_local(Vector2i(7, 7))
	_player.set_light_area(3.0)
	_player.set_terrain(_map)
	_map.add_child(_player)
	
	%MusicPlayer.stream = _music_track
	%MusicPlayer.play()
	%MusicPlayer.finished.connect(_on_music_finished)
	
	var processed : Dictionary[Vector2i, int]
	var unprocessed : Dictionary[Vector2i, int]
	for cell in _map.get_used_cells():
		var tile_data : TileData = _map.get_cell_tile_data(cell)
		var water_data = tile_data.get_custom_data("Water")
		if water_data == null:
			processed.set(cell, 0)
		elif water_data as bool == false:
			processed.set(cell, 0)
		else:
			unprocessed.set(cell, 0)

	const MAX_DIST : int = 1000
	while not unprocessed.is_empty():
		var water_work : Array[Vector2i] = unprocessed.keys()
		var to_add : Dictionary[Vector2i, int]
		for cell in water_work:
			var dist : int = MAX_DIST
			if processed.has(cell - Vector2i.DOWN):
				dist = min(dist, processed[cell-Vector2i.DOWN])
			if processed.has(cell - (Vector2i.DOWN + Vector2i.RIGHT)):
				dist = min(dist, processed[cell-(Vector2i.DOWN + Vector2i.RIGHT)])
			if processed.has(cell - (Vector2i.DOWN + Vector2i.LEFT)):
				dist = min(dist, processed[cell-(Vector2i.DOWN + Vector2i.LEFT)])
			if processed.has(cell - Vector2i.UP):
				dist = min(dist, processed[cell-Vector2i.UP])
			if processed.has(cell - (Vector2i.UP + Vector2i.RIGHT)):
				dist = min(dist, processed[cell-(Vector2i.UP + Vector2i.RIGHT)])
			if processed.has(cell - (Vector2i.UP + Vector2i.LEFT)):
				dist = min(dist, processed[cell-(Vector2i.UP + Vector2i.LEFT)])
			if processed.has(cell - Vector2i.RIGHT):
				dist = min(dist, processed[cell-Vector2i.RIGHT])
			if processed.has(cell - Vector2i.LEFT):
				dist = min(dist, processed[cell-Vector2i.LEFT])
			if dist < MAX_DIST:
				unprocessed.erase(cell)
				to_add.set(cell, dist + 1)
		for cell in to_add.keys():
			processed.set(cell, to_add[cell])

	for cell in processed.keys():
		var dist : int = processed[cell]
		if dist == 1:
			shallows.append(cell)
		elif dist == 2 or dist == 3:
			medium.append(cell)
		elif dist == 4 or dist == 5:
			deep.append(cell)

	#for cell in shallows:
		#var dot : Node2D = _debug_dot_scene.instantiate()
		#dot.position = _map.map_to_local(cell)
		#_map.add_child(dot)
	#for cell in medium:
		#var dot : Node2D = _debug_dot_scene.instantiate()
		#dot.position = _map.map_to_local(cell)
		#(dot.get_child(0) as Polygon2D).modulate = Color.BROWN
		#_map.add_child(dot)
	#for cell in deep:
		#var dot : Node2D = _debug_dot_scene.instantiate()
		#dot.position = _map.map_to_local(cell)
		#(dot.get_child(0) as Polygon2D).modulate = Color.ORANGE_RED
		#_map.add_child(dot)

var _spawned_fish : Dictionary[Vector2i, Node2D] = {}
var _rnd : RandomNumberGenerator = RandomNumberGenerator.new()

func _select_spawn_spot(spots : Array[Vector2i]) -> Vector2i:
	var count : int = 0
	while true:
		count += 1
		assert(count < 1000, "Caught in spin loop in _select_spawn_spot");
		var spot = spots[_rnd.randi() % spots.size()]
		var good_spot : bool = true
		for already_spawned_spot in _spawned_fish.keys():
			if abs(spot.x - already_spawned_spot.x) + abs(spot.y - already_spawned_spot.y) < 6:
				good_spot = false
		if good_spot == true:
			return spot
			
	assert(false, "We should never reach this code")
	return Vector2i.ZERO

func _process(_delta: float) -> void:
	while _spawned_fish.size() < _number_of_fish:
		var fish_type : Fish = _fish[_rnd.randi() % _fish.size()]
		assert(fish_type.texture_region.size.x * fish_type.texture_region.size.y > 0, "Fish texture region is size zero")
		var viable_cells : Array[Vector2i]
		match fish_type.distance_from_shore:
			Fish.DistanceFromShore.Shallows:
				viable_cells = shallows
			Fish.DistanceFromShore.Anywhere:
				viable_cells = medium
			Fish.DistanceFromShore.Far:
				viable_cells = deep
			_:
				assert(false, "Unknown distance from shore %s" % [fish_type.distance_from_shore])
		var spawn_spot : Vector2i = _select_spawn_spot(viable_cells)
		
		var spawn : Node2D = _fish_spawn_scene.instantiate()
		spawn.position = _map.map_to_local(spawn_spot)
		var spawn_sprite : Sprite2D = spawn.get_child(0) as Sprite2D
		spawn_sprite.texture = fish_type.texture_image
		spawn_sprite.region_enabled = true
		spawn_sprite.region_rect = fish_type.texture_region
		_map.add_child(spawn)
		_spawned_fish.set(spawn_spot, spawn)
		var expire_tween : Tween = spawn_sprite.create_tween()
		expire_tween.tween_interval(_rnd.randf_range(fish_type.min_duration_in_seconds, fish_type.max_duration_in_seconds))
		expire_tween.tween_callback(Callable.create(self, "_expire_spawn_spot").bind(spawn_spot))

func _expire_spawn_spot(spot : Vector2i) -> void:
	if not _spawned_fish.has(spot):
		# spot already gone
		return
	
	_spawned_fish[spot].queue_free()
	_spawned_fish.erase(spot)
