extends Node

signal timeout
# heavily ref: https://www.youtube.com/watch?v=ejRXpRlFa_Y&ab_channel=VenexSource

@onready var timer = $Timer
@onready var label = $Label

func _ready() -> void:
	timer.connect("timeout", _on_timer_timeout)

func time_left_in_level():
	var time_left = timer.time_left
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]

func _process(delta):
	label.text  = "%02d:%02d" % time_left_in_level()	

func _on_timer_timeout():
	emit_signal("timeout")
	
func set_duration(seconds):
	timer.wait_time = seconds
	
func start_timer():
	timer.start()

func stop_timer():
	timer.stop()
