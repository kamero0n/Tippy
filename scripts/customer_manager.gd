extends Node2D

signal order_created(customer)
signal order_delivered(customer, delivery_time)
signal order_timeout(customer)

@export var min_order_interval: float = 1.0 # min time between orders
@export var max_order_interval: float = 8.0 # max time between orders
@export var max_concurrent_orders: int = 3 # how many orders can happen at the same time?

var customers = []
var active_orders = 0
var next_order_timer = 0.0
var level_active = false

# track customer types
var shark_customers = []
var octopus_customers = []
var regular_customers = []

func _ready() -> void:
	# find customers in scene
	customers = get_tree().get_nodes_in_group("customers")
	# print("customerManager found ", customers.size(), " customers")
	
	# connect signals from each customer
	for customer in customers:
		customer.connect("order_delivered", _on_customer_order_delivered)
		customer.connect("order_timeout", _on_customer_order_timeout)
		customer.connect("ordered", _on_customer_ordered)
	
	# start first order timer
	reset_order_timer()
	

func _process(delta: float) -> void:
	if level_active:
		# count down to next order
		if active_orders < max_concurrent_orders:
			next_order_timer -= delta
			
			if next_order_timer <= 0:
				create_random_order()
				reset_order_timer()


# start random customer ordering
func create_random_order():
	# get available customers
	var available_customers = []
	
	for customer in customers:
		if customer.customer_state == "idle":
			available_customers.append(customer)
			
			if available_customers.size() >= 3:
				break
	
	# if we have available customers, let them order!
	if available_customers.size() > 0:
		var random_index = randi() % available_customers.size()
		var customer = available_customers[random_index]
		
		if customer and customer.has_method("set_order_dish_type"):
			var random_dish = get_random_dish_type()
			customer.set_order_dish_type(random_dish)
			
		customer.create_order()
		
		active_orders += 1
		emit_signal("order_created", customer)
		# print("order created for customer at position ", customer.global_position)
		print("order created for ", customer.customer_type, " customer at position ", customer.global_position)


func get_random_dish_type():
	var game_manager = get_node_or_null("../")
	
	if not game_manager or not game_manager.has_method("get") or not game_manager.get("dishes_of_the_day"):
		# Fallback to hardcoded dish types
		var dish_types = ["sardine_pasta", "caviar_coral", "toasted_mackerel"]
		return dish_types[randi() % dish_types.size()]
	
	if game_manager.dishes_of_the_day.size() > 0:
		return game_manager.dishes_of_the_day[randi() % game_manager.dishes_of_the_day.size()]
	else:
		return "sardine_pasta"

func reset_order_timer():
	next_order_timer = randf_range(min_order_interval, max_order_interval)

func start():
	level_active = true
	active_orders = 0
	
	# create an immediate first order
	create_random_order()
	
	# reset timer for the rest
	reset_order_timer()

func stop():
	level_active = false

func _on_customer_ordered():
	pass

func _on_customer_order_delivered(customer, delivery_time):
	active_orders -= 1
	emit_signal("order_delivered", customer, delivery_time)

func _on_customer_order_timeout(customer):
	active_orders -= 1
	emit_signal("order_timeout", customer)
