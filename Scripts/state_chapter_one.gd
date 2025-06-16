extends StateMachineState

@export var _fish : Array[Fish] = []
@export var _player_scene : PackedScene
@export var _music_track : AudioStream
@onready var _map : TileMapLayer = $IntroArea

var _player : Player = null
var _debug_dot_scene : PackedScene = preload("res://Scenes/debug_dot.tscn")

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
	#var water_cells : Dictionary[Vector2i, int]
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

	for cell in shallows:
		var dot : Node2D = _debug_dot_scene.instantiate()
		dot.position = _map.map_to_local(cell)
		_map.add_child(dot)
	for cell in medium:
		var dot : Node2D = _debug_dot_scene.instantiate()
		dot.position = _map.map_to_local(cell)
		(dot.get_child(0) as Polygon2D).modulate = Color.BROWN
		_map.add_child(dot)
	for cell in deep:
		var dot : Node2D = _debug_dot_scene.instantiate()
		dot.position = _map.map_to_local(cell)
		(dot.get_child(0) as Polygon2D).modulate = Color.ORANGE_RED
		_map.add_child(dot)
