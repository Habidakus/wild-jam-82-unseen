extends StateMachineState

@export var _player_scene : PackedScene
@onready var _map : TileMapLayer = $IntroArea

var _player : Player = null

func enter_state() -> void:
	super.enter_state()
	
	_player = _player_scene.instantiate();
	_player.position = _map.map_to_local(Vector2i(7, 7))
	_map.add_child(_player)
