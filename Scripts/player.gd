class_name Player extends CharacterBody2D

var _map_runner : MapRunner
var _terrain : TileMapLayer 
var _goal_light_size : float = 0

enum MoveState { Moving, Still }
var _movement_before_next_frame : float = 0
var _move_state : MoveState = MoveState.Still
var _stealth_state : bool = false
@export var _speed : float = 200
@export var _distance_before_advancing_a_frame : float = 16
@export var _footsteps_fast : AudioStream
@export var _light_area_delta_speed : float = 3
@export var _light_area_size_normal : float = 3
@export var _light_area_size_stealthed : float = 2.25
var _fishing_pole_scene : PackedScene = preload("res://Scenes/fishing_pole.tscn")
var _smoke_bomb_scene : PackedScene = preload("res://Scenes/smoke_bomb.tscn")
var _fishing_pole : FishingPole = null
var _sprite : Sprite2D
var _inhibit_mouse_release_cooldown : float = -1

func _ready() -> void:
    $LightCircle/PointLight2D.scale = Vector2.ZERO
    _sprite = $Sprite2D

func _handle_mouse_click() -> void:
    if _inhibit_mouse_release_cooldown >= 0:
        # the player just released clicking on something else
        _inhibit_mouse_release_cooldown = 0
        return
    
    if _fishing_pole != null:
        # The player is already fishing, let the pole handle this
        _fishing_pole.on_click()
        return
    
    if _map_runner.get_scroll_layer().is_active():
        return

    var map_cell = _terrain.local_to_map(_terrain.get_local_mouse_position())
    var tile_data : TileData = _terrain.get_cell_tile_data(map_cell)
    var water_data = tile_data.get_custom_data("Water")
    var is_water : bool = water_data != null && (water_data as bool) == true
    if not is_water:
        # you cannot fish on dry land
        return
        
    if _map_runner.get_report_card().have_smoke_bombed():
        _map_runner.get_scroll_layer().display_line("You reek of smoke bomb,\nreturn to the sensei.", self)
        return
    if _map_runner.get_report_card().have_caught_your_limit():
        _map_runner.get_scroll_layer().display_line("You have caught your limit;\nreturn to the sensei.", self)
        return
        
    _fishing_pole = _fishing_pole_scene.instantiate() as FishingPole
    _terrain.add_child(_fishing_pole)
    _fishing_pole.cast_line(self, _map_runner)

func _process_input():
        
    var _sprite_y_increase_if_running : int = 0
    var speed = _speed

    if Input.is_action_pressed("walk"):
        _stealth_state = true
        speed = _speed / 2
    else:
        _stealth_state = false
        _sprite_y_increase_if_running = 3
    
    # Get input (example using Input Map)
    if Input.is_action_pressed("move_right"):
        velocity.x = speed
    elif Input.is_action_pressed("move_left"):
        velocity.x = -speed
    else:
        velocity.x = 0

    if Input.is_action_pressed("move_down"):
        velocity.y = speed
    elif Input.is_action_pressed("move_up"):
        velocity.y = -speed
    else:
        velocity.y = 0
    
    if velocity.x != 0:
        _sprite.frame_coords.y = 2 + _sprite_y_increase_if_running
        _sprite.flip_h = velocity.x >= 0
    elif velocity.y < 0:
        _sprite.frame_coords.y = 1 + _sprite_y_increase_if_running
    else:
        _sprite.frame_coords.y = 0 + _sprite_y_increase_if_running

    _move_state = MoveState.Moving
    if velocity.x == 0 && velocity.y == 0:
        _move_state = MoveState.Still
        
    if _move_state != MoveState.Still:
        if _fishing_pole != null:
            _fishing_pole.hide()
            _fishing_pole.queue_free();
            _fishing_pole = null
    else:
        if Input.is_action_just_released("click"):
            _handle_mouse_click()
    
    if Input.is_action_just_pressed("Music"):
        var music_bus_index : int = AudioServer.get_bus_index("Music")
        var music_bus_muteness : bool = AudioServer.is_bus_mute(music_bus_index)
        AudioServer.set_bus_mute(music_bus_index, !music_bus_muteness)

# NOTE: This is a crap way to implement this, but we're close to the deadline, so, we live with it
func inhibit_mouse_release(seconds : float) -> void:
    _inhibit_mouse_release_cooldown = seconds

func cancel_fishing_pole() -> void:
    if _fishing_pole != null:
        _fishing_pole.hide()
        _fishing_pole.queue_free();
        _fishing_pole = null

func set_map_runner(map_runner : MapRunner):
    _map_runner = map_runner
    _terrain = _map_runner.get_map()

func is_in_light_area(global_pos : Vector2) -> bool:
    var f : PointLight2D = $LightCircle/PointLight2D
    var radius : float = (f.texture.get_size() * f.scale).x
    return (global_pos - global_position).length() < radius

func _process(delta: float) -> void:
    _inhibit_mouse_release_cooldown -= delta
    
    if _stealth_state:
        _goal_light_size = _light_area_size_stealthed
    else:
        _goal_light_size = _light_area_size_normal
    
    if _fishing_pole != null:
        if _stealth_state == false:
            _fishing_pole.on_player_not_stealthed()

    var movement_sound : AudioStream = null;
    if _move_state == MoveState.Moving && _stealth_state == false:
        movement_sound = _footsteps_fast
    
    if $AudioStreamPlayer.stream != movement_sound:
        $AudioStreamPlayer.stream = movement_sound
        $AudioStreamPlayer.play()
    elif $AudioStreamPlayer.playing == false:
        $AudioStreamPlayer.play()
    
    var current_scale : float = $LightCircle/PointLight2D.scale.x
    if current_scale != _goal_light_size:
        var scale_speed = _light_area_delta_speed * delta
        if current_scale < _goal_light_size:
            if current_scale + scale_speed > _goal_light_size:
                current_scale = _goal_light_size
            else:
                current_scale += scale_speed
        else:
            if current_scale - scale_speed < _goal_light_size:
                current_scale = _goal_light_size
            else:
                current_scale -= scale_speed
        $LightCircle/PointLight2D.scale = Vector2(current_scale, current_scale)

func _physics_process(_delta : float):
    _process_input()
    var current_pos = position
    move_and_slide()

    # check if we have to rollback the position
    if position != current_pos:
        var cell : Vector2i = _terrain.local_to_map(position)
        var rollback : bool = true
        if _terrain.get_cell_source_id(cell) != -1:
            var tile_data : TileData = _terrain.get_cell_tile_data(cell)
            var water_data = tile_data.get_custom_data("Water") || tile_data.get_custom_data("Wall") || tile_data.get_custom_data("Coast")
            if water_data == null || water_data as bool == false:
                rollback = false

        if rollback:
            var cell_x : Vector2i = _terrain.local_to_map(Vector2(position.x, current_pos.y))
            var rollback_x = true
            if _terrain.get_cell_source_id(cell_x) != -1:
                var tile_data : TileData = _terrain.get_cell_tile_data(cell_x)
                var water_data = tile_data.get_custom_data("Water") || tile_data.get_custom_data("Wall") || tile_data.get_custom_data("Coast")
                if water_data == null || water_data as bool == false:
                    rollback_x = false

            var cell_y : Vector2i = _terrain.local_to_map(Vector2(current_pos.x, position.y))
            var rollback_y = true
            if _terrain.get_cell_source_id(cell_y) != -1:
                var tile_data : TileData = _terrain.get_cell_tile_data(cell_y)
                var water_data = tile_data.get_custom_data("Water") || tile_data.get_custom_data("Wall") || tile_data.get_custom_data("Coast")
                if water_data == null || water_data as bool == false:
                    rollback_y = false

            if rollback_x:
                position.x = current_pos.x
            if rollback_y:
                position.y = current_pos.y

    if current_pos == position:
        _move_state = MoveState.Still
    
    var distance_covered : float = (position - current_pos).length()
    _movement_before_next_frame -= distance_covered
    if _movement_before_next_frame < 0:
        _movement_before_next_frame += _distance_before_advancing_a_frame
        _sprite.frame_coords.x = (_sprite.frame_coords.x + 1) % _sprite.hframes

    #Example using move_and_collide()
    #var collision = move_and_collide(velocity * delta)
    #if collision:
    #	velocity = velocity.bounce(collision.get_normal()) # Or other collision logic

    # Example of accessing slide collisions
    for i in get_slide_collision_count():
        var collider = get_slide_collision(i).get_collider()
        while collider is not Enemy and collider is not NoteObject and collider is not Sensei:
            collider = collider.get_parent()
            if collider == null:
                break
        
        if collider is Enemy:
            #var enemy : Enemy = collider as Enemy
            if _vanishing == false:
                _map_runner.get_report_card().add_smoke_bomb_escape()
                _vanishing = true
                var smoke_bomb : Node2D = _smoke_bomb_scene.instantiate()
                smoke_bomb.position = position
                (smoke_bomb.find_child("AnimatedSprite2D") as AnimatedSprite2D).play()
                get_parent().add_child(smoke_bomb)
                var tween : Tween = create_tween()
                tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5);
                tween.tween_interval(0.5)
                tween.tween_callback(Callable(self, "_resolve_vanish").bind(smoke_bomb))
        elif collider is NoteObject:
            pass
        elif collider is Sensei:
            pass
            #(collider as Sensei).trigger_dialog()
        else:
            print(collider)

    #Example of accessing last collision
    #var last_collision = get_last_slide_collision()
    #if last_collision:
    #	print("Last collision normal: ", last_collision.get_normal())

var _vanishing : bool = false
func _resolve_vanish(smoke_bomb : Node2D) -> void:
    smoke_bomb.queue_free()
    _map_runner.go_back_to_sensei()
