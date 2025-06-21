class_name TeleportationArea extends Node2D

## Drag the map (State Machine State) here which the player should be moved to
@export var destination_map : StateMachineState
@export var tier : int = 0
@export var blocks : bool = false

# Having the state machine set to non-null is a sentinel value that triggers the switching
# of the states outside of the physics loop (which angers the Godot engine)
var _our_state_machine : StateMachine = null
var _blocker : StaticBody2D = null

func _ready() -> void:
	_blocker = find_child("Blocker") as StaticBody2D
	if blocks == false:
		unblock()

func get_tier() -> int:
	return tier

func unblock() -> void:
	blocks = false
	_blocker.process_mode = Node.PROCESS_MODE_DISABLED
	_blocker.hide()

func _process(_delta: float) -> void:
	if _our_state_machine != null:
		_our_state_machine.switch_state(destination_map.name)
		_our_state_machine = null

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	
	var node : Node = self
	while not node is StateMachineState:
		node = node.get_parent()
		if node == null:
			print("%s is not a child of a state machine state! Cannot teleport" % self.name)
			return
	 
	_our_state_machine = (node as StateMachineState).our_state_machine
