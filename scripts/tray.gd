extends Area2D

@onready var tray = $"."

var stacked_dishes = []
var max_dishes = 3

var start_pos = Vector2(0.0, -15.0)
var offset = 5.0

func add_dish(dish_scene):
	# check if we have max dishes
	if stacked_dishes.size() >= max_dishes:
		print("Tray full!")
		return false
		
	# create new dish instance
	var dish = dish_scene.instantiate()
	
	# set new dish pos
	var new_tray_pos
	if stacked_dishes.size() <= 0.0:
		new_tray_pos = start_pos
	else:
		new_tray_pos = Vector2(start_pos.x, start_pos.y - offset)
	dish.position = new_tray_pos
	start_pos = new_tray_pos
	
	# add to our stack
	stacked_dishes.append(dish)
	
	# add to scene tree
	add_child(dish)
	return true

func remove_top_dish():
	# check that the list isn't empty
	if stacked_dishes.size() <= 0:
		print("No dishes!")
		return null
	
	# get top dish
	var dish = stacked_dishes.pop_back()
	
	# reset stack position to account for removed dish
	if stacked_dishes.size() <= 0:
		start_pos = Vector2(0.0, -15.0)
	else:
		start_pos = Vector2(start_pos.x, start_pos.y + offset)
	
	# return the dish
	return dish
