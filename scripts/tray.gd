extends Area2D

signal dish_fallen(dish_position)

@onready var tray = $"."

var stacked_dishes = []
var max_dishes = 3

# positioning the dishes
var start_pos = Vector2(0.0, -15.0)
var offset = 5.0 # this is a Y offset to stack the plates

var balance = 0.0 # 0 = perf balance, high values = not perf balance
var max_balance = 100.0 # if dishes reach here, should fall
var balance_recovery_rate = 20.0 # how quick dishes recover balance
var dish_offset = 0.0 # this is a X offset
var last_direction = 0 # track which way the player is moving

var dish_target_positions = []
var lerp_speed = 1.0

func _process(delta: float) -> void:
	# apply smooth movement to dishes
	for i in range(stacked_dishes.size()):
		if i < dish_target_positions.size():
			var dish = stacked_dishes[i]
			
			dish.position = dish.position.lerp(dish_target_positions[i], lerp_speed * delta)
		

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
	
	# add dish positions
	dish_target_positions.append(dish.position)
	
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

func drop_dish():
	if stacked_dishes.size() > 0:
		var dish = remove_top_dish()
		if dish:
			print("I DROPPED!")
			# get position of dish before removing
			var fallen_position = global_position + dish.position
			
			# emit signal w/ position where dish fell
			emit_signal("dish_fallen", fallen_position)
			
			# remove dish from tray
			dish.queue_free()
		
		# reset balance partially 
		balance = max(0, balance - 25.0)

func update_dish_positions():
	for i in range(stacked_dishes.size()):
		var dish = stacked_dishes[i]
		
		# get base pos
		var base_pos = Vector2(0, -15.0 - (i * offset))
		
		# apply curr offset
		var target_pos = base_pos + Vector2(dish_offset, 0)
		
		# update target pos for this dish
		dish_target_positions[i] = target_pos
		
		# lerp from prev dish pos to new target pos
		dish.position = dish.position.lerp(dish_target_positions[i], 0.1)
		
		# check if any dish has moved too far off the tray
		if(abs(dish.position.x) > 15.0):
			print("dish gonna fall")
			call_deferred("drop_dish")
			break

# the big fella
func update_balance(delta, player_velocity, is_sprinting, direction):
	# store the prev direction for comparison
	var direction_changed = (direction != 0 and direction != last_direction)
	
	# if direction changed and we were already moving before, add imbalance
	if direction_changed and last_direction != 0:
		balance += 15.0 # BIG imbalance
	
	# update last direction if we are moving
	if direction != 0:
		last_direction = direction
	
	# increase imbalance when player is sprinting
	if is_sprinting and stacked_dishes.size() > 0:
		balance += delta * 15.0
	
	# increase imbalance if a good amount of dishes
	var dish_factor = stacked_dishes.size() * 0.5
	
	# calculate recovery 
	var recovery = balance_recovery_rate / (1.0 + dish_factor)
	balance = max(0.0, balance - (recovery * delta))
	
	# calculate offset based on balance
	var max_offset = 12.0
	var target_offset = max_offset * (balance/max_balance) * last_direction
	dish_offset = lerp(dish_offset, target_offset, 5.0 * delta)
	
	# apply offset to dishes
	update_dish_positions()
	
	# check if dishes should fall
	if abs(dish_offset) >= 15.0:
		drop_dish()
