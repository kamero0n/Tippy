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

# game state
var score = 0
var customer = null
var available_dishes = ["spaghet"]

@onready var counter = $counter

func _ready():
	# get ref to customer
	customer = $customer
	
	# connect signals
	if counter:
		counter.connect("dish_taken", _on_dish_taken)
	
	if customer:
		customer.connect("order_delivered", _on_order_delivered)
		customer.connect("order_timeout", _on_order_timeout)
		
		# start w/ active order
		start_customer_order()
	

# start an order for customer
func start_customer_order():
	if customer and !customer.has_active_order:
		customer.start_order()
		
		emit_signal("order_created", customer)
		print("order created for customer!")
		
# called when player takes a dish from counter
func _on_dish_taken(dish):
	print("player took dish")
	
	# if customer doesn't have an order, start one
	if customer and !customer.has_active_order:
		start_customer_order()

# called when customer gets order
func _on_order_delivered(delivery_time):
	# calc tip based on time
	var tip = base_tip_amount
	
	# deduct time based on time it took 
	tip -= delivery_time * tip_deduction_per_second
	
	# ensure tip is w/in range
	tip = clamp(tip, min_tip_amount, max_tip_amount)
	
	# add to score
	score += tip
	
	print("order completed! tip: " + str(tip) + " | total score " + str(score))

	emit_signal("order_completed", customer, tip)
	
	# wait before starting a new order
	await get_tree().create_timer(2.0).timeout
	start_customer_order()
	
# called when order times out
func _on_order_timeout():
	print("order time out! MAD CUSTOMER!!!")
	
	# add penalty (should be the same...as breaking a plate?)
	score -= dish_break_penalty
	
	emit_signal("order_failed", customer)
	
	await get_tree().create_timer(3.0).timeout
	start_customer_order()	

# called when dish falls from tray
func _on_dish_fallen(dish_position):
	score -= dish_break_penalty
