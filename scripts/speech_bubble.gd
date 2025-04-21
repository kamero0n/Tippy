extends Sprite2D


var height = 3.0
var speed = 4.0
var initial_position = Vector2()

func _ready():
	initial_position = position

func _process(delta: float) -> void:
	var bob = sin(Time.get_ticks_msec() * 0.001 * speed) * height
	position = initial_position + Vector2(0, bob)
