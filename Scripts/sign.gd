class_name TooltipSign extends Node2D

## What text the sign should display when the mouse hovers over it
@export var sign_text : String

func _ready() -> void:
    (find_child("Control") as Control).tooltip_text = sign_text
