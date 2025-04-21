extends StaticBody2D

signal dish_taken

@onready var counter_area = $counter_area

var atCounter = false
var dish = preload("res://scenes/dishware.tscn")

func _on_counter_area_body_entered(body: Node2D) -> void:
	# check if the player entered the area of the counter
	if body.is_in_group("player"):
		atCounter = true

func _on_counter_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		atCounter = false
		
func _process(delta: float) -> void:
	if atCounter == true:
		
		# check if the player is pressing the interact key
		if Input.is_action_just_pressed("pick_up"):
			print("grabbed dish")
			
			emit_signal("dish_taken", dish)

			
