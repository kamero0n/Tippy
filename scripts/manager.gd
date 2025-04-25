extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("idle")
