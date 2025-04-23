extends Area2D

signal dish_fallen(dish_position)

@onready var tray = $"."
@onready var balance_face = $"balance_face"

var face_happy = preload("res://assets/UI/happy_tippy.png")
var face_neutral = preload("res://assets/UI/worried_tippy.png")
var face_worried = preload("res://assets/UI/veryworried_tippy.png")
var face_panic = preload("res://assets/UI/dead_tippy.png")

var broken_dish_scene = preload("res://scenes/objects/broken_dish.tscn") # shout out https://www.youtube.com/watch?v=s14LA_fbMoI&ab_channel=%231SoundFX%21

var stacked_dishes = []
var max_dishes = 5

# positioning the dishes
var start_pos = Vector2(0.0, -15.0)
var offset = 5.0 # this is a Y offset to stack the plates

var balance = 0.0 # 0 = perf balance, high values = not perf balance
var max_balance = 100.0 # if dishes reach here, should fall
var tray_edge_limit = 14.0 # max X before the plate falls
var recovery_rate = 30.0 # how quick balance recovers per second

# impact balance factors (think of a % of affecting balance)
var sprint_impact = 30.0 # %
var direction_change_impact = 10.0 # %
var walk_impact = 5.0 # %
var dish_stack_multiplier = 1.6 # each dish inc impact by this factor

# movement variables
var curr_slide_offset = 0.0 # curr x offset of the dishes
var last_move_dir = 0 # either (-1, 0, 1)
var last_slide_offset = 0.0

# smooth movement
var dish_target_positions = []
var smooth_speed = 5.0

func _ready() -> void:
	# connect fallen dish to game manager 
	var game_manager = get_parent().get_parent().get_parent().get_node("game_manager")
	if game_manager:
		# print("connecting to game manager")
		connect("dish_fallen", game_manager._on_dish_fallen)

func _process(delta: float) -> void:
	# apply smooth movement to dishes
	for i in range(stacked_dishes.size()):
		if i < dish_target_positions.size():
			var dish = stacked_dishes[i]
			
			dish.position = dish.position.lerp(dish_target_positions[i], smooth_speed * delta)
	
	# update_balance_face()
	
	if stacked_dishes.size() > 0:
		var top_dish = stacked_dishes[stacked_dishes.size() - 1]
		if abs(top_dish.position.x) > tray_edge_limit:
			drop_dish()
		

func add_dish(dish_scene):
	# check if we have max dishes
	if stacked_dishes.size() >= max_dishes:
		print("Tray full!")
		return false
	
	# reset balance when adding a new dish (i'm not sure if this will feel good but try out)
	balance = 0.0
	curr_slide_offset = 0.0
	
	# create new dish instance
	var dish = dish_scene.instantiate()
	
	# play sound here?
	if has_node("plate_stack_sound"):
		get_node("plate_stack_sound").play()
	
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
	
	# init target position
	dish_target_positions.append(dish.position)
	
	# add to scene tree
	add_child(dish)
	return true

func remove_top_dish():
	# check that the list isn't empty
	if stacked_dishes.size() <= 0:
		# print("No dishes!")
		return null
	
	# get top dish
	var dish = stacked_dishes.pop_back()
	
	# remove target position associate
	if dish_target_positions.size() > 0:
		dish_target_positions.pop_back()
	
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
			# print("I DROPPED!")
			# get position of dish before removing
			var fallen_position = global_position + dish.position
			
			# create broken dish instance
			var broken_dish = broken_dish_scene.instantiate()
			get_parent().get_parent().add_child(broken_dish)
			
			# position at floor level
			var floor_y = get_parent().global_position.y - 15.0
			broken_dish.global_position = Vector2(fallen_position.x, floor_y)
			
			if broken_dish.has_node("dish_break_sound"):
				broken_dish.get_node("dish_break_sound").play()
			
			
			# emit signal w/ position where dish fell
			emit_signal("dish_fallen", fallen_position)
			
			# remove dish from tray
			dish.queue_free()
		
		# reset balance partially 
		balance = max(0, balance - 30.0)

func update_dish_positions():
	for i in range(stacked_dishes.size()):
		if i < stacked_dishes.size() and i < dish_target_positions.size():
			# get base position
			var base_pos = Vector2(0.0, -15.0 - (i * offset))
			
			# the higher the dish the MORE unstable
			var position_factor = float(i + 1) / stacked_dishes.size()
			var amplified_offset = curr_slide_offset * position_factor * 3.0
			
			# calc target pos with offset
			var target_pos = base_pos + Vector2(amplified_offset, 0.0)
			
			
			# update target pos
			dish_target_positions[i] = target_pos
			
			# apply red tint based on edge
			var dish = stacked_dishes[i]
			var edge_prox = abs(target_pos.x) / tray_edge_limit
			
			if edge_prox > 0.4:
				var red_amount = min(1.0, edge_prox * 1.5)
				dish.modulate = Color(1.0, 1.0 - red_amount, 1.0 - red_amount)
			else:
				dish.modulate = Color(1.0, 1.0, 1.0)

func update_balance_face():
	# skip if no face sprite
	if !balance_face || stacked_dishes.size() <= 0:
		if balance_face:
			balance_face.visible = false
		return
	
	# get player's facing dir
	var facing_right = get_parent().facing_right
	
	# position UI based on facing dir
	var base_x_pos
	if facing_right:
		base_x_pos = -30
	else:
		base_x_pos = 30
	var base_y_pos = -60
	
	# hide if no dishes
	balance_face.visible = true
	
	# calc dish stability
	var top_dish = stacked_dishes[stacked_dishes.size() - 1]
	
	# track velocity of edge movement
	var edge_prox = abs(top_dish.position.x) / tray_edge_limit
	
	var dish_movement_trend = abs(curr_slide_offset - last_slide_offset) * 10.0
	if sign(curr_slide_offset) == sign(last_slide_offset) && abs(curr_slide_offset) > abs(last_slide_offset):
		edge_prox += dish_movement_trend
	
	edge_prox = clamp(edge_prox, 0.0, 1.0)
	
	if edge_prox <= 0.3:
		balance_face.texture = face_happy
	elif edge_prox <= 0.5:
		balance_face.texture = face_neutral
	elif edge_prox <= 0.75:
		balance_face.texture = face_worried
	else:
		balance_face.texture = face_panic
	
	var shake_offset = 0
	if edge_prox > 0.5:
		var shake_intensity = 1.0 + (edge_prox - 0.5) * 8.0
		shake_offset = sin(Time.get_ticks_msec() * 0.02) * shake_intensity
	
	balance_face.position = Vector2(base_x_pos + shake_offset, base_y_pos)
	
	last_slide_offset = curr_slide_offset
		

# the big fella
func update_balance(delta, player_velocity, is_sprinting, direction):
	# apply balance if we have dishes
	if stacked_dishes.size() <= 0:
		return
	
	# const small wobble
	#var wobble_amount = 3.0
	#var constant_wobble = sin(Time.get_ticks_msec() * 0.01) * wobble_amount * direction
	#
	# detect direction changes
	var direction_changed = (direction != 0 and direction != last_move_dir)
	
	# update direction tracking
	if direction != 0:
		last_move_dir = direction
	
	# --- INCREASE IMBALANCE ---
	
	# direction changes cause burst of imbalance
	if direction_changed and last_move_dir != 0:
		balance += direction_change_impact
	
	# movement impact
	var move_impact = 0.0
	if is_sprinting:
		move_impact = sprint_impact
	else:
		move_impact = walk_impact
		
	# apply movement impact based on number of stacked dishes
	var stack_factor = 1.0
	for i in range(stacked_dishes.size() - 1):
		stack_factor *= dish_stack_multiplier
		
	balance += move_impact * delta * stack_factor
	
	# --- RECOVER BALANCE --
	
	# standing still
	var recovery_modifier = 2.0 if direction == 0 else 1.0
	
	# recover balance
	balance = max(0.0, balance - (recovery_rate * recovery_modifier * delta))
	
	# if standing still, reduce slide offset
	if direction == 0:
		curr_slide_offset = lerp(curr_slide_offset, 0.0, 6.0 * delta)
	
	# --- APPLY BALANCE EFFECTS ---
	
	# calc slide amount based on balance %
	var max_slide = 12.0
	var slide_direction = last_move_dir if last_move_dir != 0 else 1
	var balance_percentage = balance / max_balance
	
	# compute target slide w/ wobble
	var target_slide = (max_slide * balance_percentage * slide_direction) # + constant_wobble
	
	# smooth transition to new slide amount
	var slide_smooth = 12.0 if direction == 0 else 8.0
	curr_slide_offset = lerp(curr_slide_offset, target_slide, slide_smooth * delta)
	
		
	# update balance face
	# update_balance_face()
	
	# update dish positions with new slide amount
	update_dish_positions()
	
	# check if dishes should fall
	if abs(curr_slide_offset) >= tray_edge_limit:
		drop_dish()
