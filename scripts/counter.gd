extends StaticBody2D

signal dish_taken

@onready var counter_area = $counter_area

var atCounter = false
var dish = preload("res://scenes/dishware.tscn")

func _on_counter_area_body_entered(body: Node2D) -> void:
	# check if the player entered the area of the counter
	if atCounter == false:
		atCounter = true
		
		
func _process(delta: float) -> void:
	if atCounter == true:
		
		# check if the player is pressing the interact key
		if Input.is_action_just_pressed("pick_up"):
			print("grabbed dish")
			
			emit_signal("dish_taken", dish)
			
			# reset state
			atCounter = false
			
