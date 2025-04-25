extends Node

signal order_created(customer)
signal order_completed(customer, tip_amount)
signal order_failed(customer)

# level config
var base_tip_amount = 10.0
var max_tip_amount = 20.0
var min_tip_amount = 5.0
var tip_deduction_per_second = 0.5
var dish_break_penalty = 5.0

var level_duration = 60.0
var level_timer = null
var level_started = false
var level_ended = false

# game state
var score = 0
var score_label = "0"

# dishes of the day system
var dishes_of_the_day = []
var all_available_dishes = ["sardine_pasta", "caviar_coral"]


@onready var customer_manager = $customer_manager
@onready var counter = $Counter


var in_tutorial_mode = false

var total_tips_earned = 0
var total_dishes_broken = 0

func _ready():
	## get ref to customer
	#customer = $customer
	
	# get ref to timer
	level_timer = $UI/timer_node/timer
	if level_timer:
		level_timer.connect("timeout", _on_level_timeout)
		level_timer.set_duration(level_duration)
	
	# get ref to score label
	score_label = $UI/dishes_delivered/dishes_label
	
	# connect signals
	if counter:
		counter.connect("dish_taken", _on_dish_taken)
	
	if customer_manager:
		customer_manager.connect("order_delivered", _on_order_delivered)
		customer_manager.connect("order_timeout", _on_order_timeout)
		customer_manager.connect("order_created", _on_customer_order_taken)
	
	# set up dishes of the day
	setup_dishes_of_the_day()
	
	var tutorial_manager = $TutorialManager
	if tutorial_manager and level_timer and $UI/timer_node:
		in_tutorial_mode = true
		$UI/timer_node.visible = false
		
		if score_label:
			score_label.text = ""
		
		tutorial_manager.connect("tutorial_step_completed", _on_tutorial_step_completed)
	else:
		# start level
		start_level()

func start_level():
	level_started = true
	level_ended = false
	score = 0
	
	# set initial score
	if score_label:
		score_label.text = str(score)
	
	# start timer
	if level_timer:
		level_timer.start_timer()
	
	# start customer orders
	if customer_manager:
		customer_manager.start()


func setup_dishes_of_the_day():
	# change this later to be dependent on level data
	dishes_of_the_day = all_available_dishes.duplicate()
	
	# if counter exists, update its dish types to match dishes of the day
	if counter:
		counter.update_available_dishes(dishes_of_the_day)


func _on_level_timeout():
	level_ended = true
	level_timer.stop_timer()
	
	customer_manager.stop()
	
	print("level time ended!")
	
	var global = get_node("/root/Global")
	global.tips_earned = total_tips_earned
	global.dishes_broken = total_dishes_broken
	global.final_score = score
	
	# change scene
	var scene_manager = get_node("/root/SceneManager")
	scene_manager.change_scene("res://scenes/end_level.tscn")
	

func _on_customer_order_taken(customer):
	# assign random dish type from dishes of the day
	if dishes_of_the_day.size() > 0:
		var random_dish = dishes_of_the_day[randi() % dishes_of_the_day.size()]
		customer.current_dish_type = random_dish
	
	
	# print("player took the order!")
	emit_signal("order_created", customer)

# called when player takes a dish from counter
func _on_dish_taken(dish):
	# print("player took dish")
	pass

# called when customer gets order
func _on_order_delivered(customer, delivery_time):
	# base reward
	var base_reward = 5.0
	
	var dish_type = "unknown"
	
	var dish = customer.get_received_dish()
	if dish:
		if dish.has_method("get_price"):
			base_reward = dish.get_price()
		if dish.has_method("get_dish_type"):
			dish_type = dish.get_dish_type()
	
	# calc tip based on time
	var tip = base_tip_amount
	
	# deduct time based on time it took 
	# tip -= delivery_time * tip_deduction_per_second
	
	# apply customer-specific tip multiplier
	if customer.has_method("get_tip_multiplier"):
		tip *= customer.tip_multiplier
	
	# ensure tip is w/in range
	tip = clamp(tip, min_tip_amount, max_tip_amount)
	
	# if customer is angry, zero out the tip
	if customer.is_angry:
		tip = 0.0
	
	# add to score
	score += tip + base_reward
	total_tips_earned += tip
	
	update_score()
	
	# print("order completed! tip: " + str(tip) + " | total score " + str(score))

	emit_signal("order_completed", customer, tip)
	
	## wait before starting a new order
	#await get_tree().create_timer(2.0).timeout
	#start_customer_order()
	
# called when order times out
func _on_order_timeout(customer):
	# print("order time out! MAD CUSTOMER!!!")
	
	# add penalty (should be the same...as breaking a plate?)
	# score -= dish_break_penalty
	
	# update the score
	# update_score()
	
	emit_signal("order_failed", customer)
	

# called when dish falls from tray
func _on_dish_fallen(dish_position):
	score = max(0.0, score - dish_break_penalty)
	total_dishes_broken += 1
	
	# update the score
	update_score()
	
	# print("dish broken")
	
func update_score():
	score = max(0.0, score)
	score_label.text = str(int(score))

func _on_tutorial_step_completed(step):
	if step == "final_step":
		in_tutorial_mode = false
		start_level()
		
		if $UI/timer_node:
			$UI/timer_node.visible = true
