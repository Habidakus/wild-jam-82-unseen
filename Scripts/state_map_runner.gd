class_name MapRunner extends StateMachineState

@export var _fish : Array[Fish] = []
@export var _enemy : Array[PackedScene] = []
@export var _player_spawn_spot : Vector2i = Vector2i(7,7)
@export var _music_track : AudioStream
@export var _number_of_fish : int = 5

#var _navigation_region : NavigationRegion2D

var _map : TileMapLayer = null
var _player : Player = null
var _player_scene : PackedScene = preload("res://Scenes/player.tscn")
#var _debug_dot_scene : PackedScene = preload("res://Scenes/debug_dot.tscn")
#var _fish_spawn_scene : PackedScene = preload("res://Scenes/fish_spawn.tscn")

var _spawned_fish : Dictionary[Vector2i, Node2D] = {}
var _spawned_enemy : Array[Enemy] = []
var _rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _last_mini_game_spot : Vector2i = Vector2i.MAX / 2

var shallows : Array[Vector2i]
var medium : Array[Vector2i]
var deep : Array[Vector2i]
var ground : Dictionary[Vector2i, int]
	
func _on_music_finished() -> void:
	%MusicPlayer.play()
	
func get_report_card() -> ReportCard:
	var node : Node = self
	while node is not StateMachine:
		node = node.get_parent()
		if node == null:
			print("Why don't we have a report card storage area?")
			var tmp_card : ReportCard = ReportCard.new()
			tmp_card.start(_rnd.randi())
			return tmp_card
	for child in node.get_children():
		if child is ReportCard:
			return child as ReportCard
	var report_card : ReportCard = ReportCard.new()
	report_card.start(_rnd.randi())
	node.add_child(report_card)
	return report_card

func exit_state(next_state: StateMachineState) -> void:
	if 	%MusicPlayer.finished.is_connected(_on_music_finished):
		%MusicPlayer.finished.disconnect(_on_music_finished)
	
	_player.queue_free()
	
	for fish : Node2D in _spawned_fish.values():
		fish.queue_free()
	_spawned_fish.clear()
	
	for enemy : Node2D in _spawned_enemy:
		enemy.queue_free()
	_spawned_enemy.clear()
		
	super.exit_state(next_state)
	
func enter_state() -> void:
	super.enter_state()
	
	for child in get_children():
		if child is TileMapLayer:
			_map = child as TileMapLayer
		if child is CanvasModulate:
			child.show()
	
	_player = _player_scene.instantiate();
	_player.position = _map.map_to_local(_player_spawn_spot)
	_player.set_map_runner(self)
	_map.add_child(_player)
	
	%MusicPlayer.stream = _music_track
	%MusicPlayer.play()
	%MusicPlayer.finished.connect(_on_music_finished)

	_find_water_cells()
	_spawn_enemies()


func generate_move_path(from : Vector2i, to : Vector2i) -> Array[Vector2i]:
	var ret_val : Array[Vector2i]
	
	if ground.has(from) and ground.has(to):
		var from_id = ground[from]
		var to_id = ground[to]
		var astar_path = _astar.get_point_path(from_id, to_id)
		if astar_path.size() > 0:
			for fpoint in astar_path:
				var ipoint : Vector2i = fpoint
				if ipoint != from:
					ret_val.append(ipoint)
			return ret_val
	
	print("Can't find an astar path from %s to %s" % [from, to])
	var cursor = from
	while cursor != to:
		if cursor.x < to.x:
			cursor.x += 1
		elif cursor.x > to.x:
			cursor.x -= 1
		if cursor.y < to.y:
			cursor.y += 1
		elif cursor.y > to.y:
			cursor.y -= 1
		ret_val.append(cursor)
	
	return ret_val

func get_enemy_spawn_spot(avoid_player : bool) -> Vector2i:
	var valid_spots : Array[Vector2i]
	var player_cell : Vector2i = _map.local_to_map(_player.position)
	for cell in ground.keys():
		if avoid_player:
			if abs(cell.x - player_cell.x) + abs(cell.y - player_cell.y) < 10:
				continue
		var enemy_too_close : bool = false
		for e in _spawned_enemy:
			var e_cell : Vector2i = _map.local_to_map(e.position)
			if abs(cell.x - e_cell.x) + abs(cell.y - e_cell.y) < 2:
				enemy_too_close = true
				break
		if enemy_too_close:
			continue
		
		valid_spots.append(cell)
	
	return valid_spots[_rnd.randi() % valid_spots.size()]

func get_vector_from_player_to_local(local : Vector2) -> Vector2:
	return _player.position - local

func _spawn_enemies() -> void:
	_spawned_enemy.clear()
	for enemy_scene in _enemy:
		var enemy = enemy_scene.instantiate() as Enemy
		enemy.set_map_runner(self, %Radar)
		enemy.position = _map.map_to_local(get_enemy_spawn_spot(true))
		enemy.scale = Vector2.ONE * 2.0
		_map.add_child(enemy)
		_spawned_enemy.append(enemy)

func get_scroll_layer() -> ScrollLayer:
	return %ScrollLayer

func go_back_to_sensei() -> void:
	our_state_machine.switch_state("SenseiHub")

var _astar : AStar2D
func _find_water_cells() -> void:
	ground.clear()
	shallows.clear()
	medium.clear()
	deep.clear()
	
	_astar = AStar2D.new()
	
	var ground_index : int = 0
	var processed : Dictionary[Vector2i, int]
	var unprocessed : Dictionary[Vector2i, int]
	for cell in _map.get_used_cells():
		var tile_data : TileData = _map.get_cell_tile_data(cell)
		var water_data = tile_data.get_custom_data("Water")
		var wall_data = tile_data.get_custom_data("Wall")
		var is_water : bool = water_data != null && (water_data as bool) == true
		if not is_water:
			processed.set(cell, 0)
		else:
			unprocessed.set(cell, 0)
		var is_wall : bool = wall_data != null && (wall_data as bool) == true
		if not is_wall and not is_water:
			ground.set(cell, ground_index)
			_astar.add_point(ground_index, cell)
			
			if ground.has(cell + Vector2i.UP):
				_astar.connect_points(ground_index, ground[cell + Vector2i.UP])
			if ground.has(cell + Vector2i.DOWN):
				_astar.connect_points(ground_index, ground[cell + Vector2i.DOWN])
			if ground.has(cell + Vector2i.LEFT):
				_astar.connect_points(ground_index, ground[cell + Vector2i.LEFT])
			if ground.has(cell + Vector2i.RIGHT):
				_astar.connect_points(ground_index, ground[cell + Vector2i.RIGHT])

			ground_index += 1

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

func _select_spawn_spot(spots : Array[Vector2i]) -> Vector2i:
	var count : int = 0
	while true:
		# it could be a particular type of fish could not be placed on the map
		# MAX is a sentinel value to try again with a different fish.
		count += 1
		if count > 25:
			return Vector2i.MAX

		var spot = spots[_rnd.randi() % spots.size()]
		var dist_from_last_spot : int = abs(spot.x - _last_mini_game_spot.x) + abs(spot.y - _last_mini_game_spot.y)
		var good_spot : bool = dist_from_last_spot > 6
		if good_spot == true:
			for already_spawned_spot in _spawned_fish.keys():
				if abs(spot.x - already_spawned_spot.x) + abs(spot.y - already_spawned_spot.y) < 6:
					good_spot = false
					break
		if good_spot == true:
			return spot
			
	assert(false, "We should never reach this code")
	return Vector2i.MAX

func get_map() -> TileMapLayer:
	return _map

func _process(_delta: float) -> void:
	var count : int = 0
	while _spawned_fish.size() < _number_of_fish:
		var spawn_spot : Vector2i = Vector2i.MAX
		var fish_type_index = _rnd.randi() % _fish.size()
		var fish_type : Fish
		while spawn_spot == Vector2i.MAX && count < 100:
			count += 1
			fish_type = _fish[fish_type_index]
			assert(fish_type.texture_region.size.x * fish_type.texture_region.size.y > 0, "Fish texture region is size zero")
			var viable_cells : Array[Vector2i]
			match fish_type.distance_from_shore:
				Fish.DistanceFromShore.Shallows:
					viable_cells = shallows
				Fish.DistanceFromShore.Medium:
					viable_cells = medium
				Fish.DistanceFromShore.Far:
					viable_cells = deep
				Fish.DistanceFromShore.Anywhere:
					viable_cells = medium + shallows + deep
				_:
					assert(false, "Unknown distance from shore %s" % [fish_type.distance_from_shore])
			spawn_spot = _select_spawn_spot(viable_cells)
			# bump the fish type in case we didn't get a valid spot
			fish_type_index = (fish_type_index + 1) % _fish.size()

		if spawn_spot == Vector2i.MAX:
			print("Failed to spawn fish %s of %s" % [_spawned_fish.size() + 1, _number_of_fish] )
			return
		
		var spawn : MiniGame = fish_type.mini_game.instantiate() as MiniGame
		spawn.position = _map.map_to_local(spawn_spot)
		spawn.set_fish_type(fish_type, _rnd.randi(), self)
		_map.add_child(spawn)
		_spawned_fish.set(spawn_spot, spawn)
		var expire_tween : Tween = spawn.create_tween()
		expire_tween.tween_interval(_rnd.randf_range(fish_type.min_duration_in_seconds, fish_type.max_duration_in_seconds))
		expire_tween.tween_callback(Callable.create(self, "_expire_spawn_spot_if_not_being_played").bind(spawn_spot))

func mark_mini_game_removed(mini_game : MiniGame) -> void:
	var mini_game_cell : Vector2i = _map.local_to_map(mini_game.position)
	_spawned_fish.erase(mini_game_cell)
	_last_mini_game_spot = mini_game_cell
	mini_game.queue_free()

func _expire_spawn_spot_if_not_being_played(spot : Vector2i) -> void:
	if not _spawned_fish.has(spot):
		# spot already gone
		return
	var mini_game = _spawned_fish[spot]
	if mini_game.is_being_played():
		# Don't remove if player is currently using it
		return
	_last_mini_game_spot = spot
	_spawned_fish[spot].queue_free()
	_spawned_fish.erase(spot)

func _expire_spawn_spot(spot : Vector2i) -> void:
	if not _spawned_fish.has(spot):
		# spot already gone
		return
	
	_last_mini_game_spot = spot
	_spawned_fish[spot].queue_free()
	_spawned_fish.erase(spot)
