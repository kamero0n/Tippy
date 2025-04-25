extends Node
class_name Customer

signal order_delivered(delivery_time)
signal order_timeout
signal ordered
signal order_taken

@onready var dish_area = $foodArea
@onready var order_timer_display = $orderTimer
@onready var order_bubble = $orderBubble
@onready var order_progress_bar = $orderProgressBar
@onready var animatedSprite = $AnimatedSprite2D

var customer_state = "idle"
var has_active_order = false
var order_start_time = 0
var order_time_limit = 20
var order_timer = 0
var player_in_range = false
var customer_type = "regular"

var is_angry = false

var tip_multiplier = 1.0
var can_change_order = false
var wrong_dish_penalty = 10.0

var current_dish_type = "sardine_pasta" # default dish
var received_dish = null # track dish received

func _ready() -> void:
	# Check if UI nodes exist
	if order_bubble:
		order_bubble.visible = false
	if order_progress_bar:
		order_progress_bar.visible = false
	
	# add customers group for players to detect
	add_to_group("customers")
	
	# init based on customer type
	initialize_customer_type()
	
	if animatedSprite:
		animatedSprite.play("idle")
	
func initialize_customer_type():
	pass

func _process(delta: float) -> void:
	if has_active_order:
		# update timer
		order_timer -= delta
		
		# update progress bar
		if order_progress_bar:
			order_progress_bar.value = (order_timer / order_time_limit) * 100
		
		# check for timeout
		if order_timer <= 0:
			timeout_order()
	
	if customer_state == "has_order" and player_in_range:
		if Input.is_action_just_pressed("take_order"):
			start_order()
			
	process_customer_behavior(delta)

func process_customer_behavior(delta: float) -> void:
	pass


func create_order():
	customer_state = "has_order"
	
	# Update order bubble with dish info if available
	if order_bubble:
		order_bubble.visible = true
	
	if order_progress_bar:
		order_progress_bar.visible = false
	
	is_angry = false
	
	emit_signal("ordered")

func start_order():
	if customer_state == "has_order":
		customer_state = "waiting_for_food"
		
		has_active_order = true
		order_timer = order_time_limit
		order_start_time = Time.get_ticks_msec() / 1000.0
		
		# show UI
		if order_bubble:
			order_bubble.visible = false
		if order_progress_bar:
			order_progress_bar.visible = true
			order_progress_bar.value = 100
		
		emit_signal("order_taken")
		
		# Try to find the right customer_manager reference using different paths
		var customer_manager = null
		var possible_paths = [
			"/root/game_manager/customer_manager",
			"../customer_manager",
			"../../customer_manager",
			"/root/SceneManager/CurrentScene/*/customer_manager"
		]
		
		for path in possible_paths:
			var node = get_node_or_null(path)
			if node:
				customer_manager = node
				break
		
		# Try finding using get_tree() if the direct paths failed
		if not customer_manager:
			var nodes = get_tree().get_nodes_in_group("customer_manager")
			if nodes.size() > 0:
				customer_manager = nodes[0]
		
		# Emit signal only if we found a valid customer_manager
		if customer_manager:
			customer_manager.emit_signal("order_created", self)
		else:
			# Print a warning but don't throw an error
			print("Warning: Could not find customer_manager to emit order_created signal")
			
			# As a fallback, let's check if we're in the tutorial
			var tutorial_manager = get_node_or_null("../TutorialManager")
			if not tutorial_manager:
				tutorial_manager = get_node_or_null("../../TutorialManager")
			
			if tutorial_manager:
				# Directly call the tutorial manager's method for handling the order
				if tutorial_manager.has_method("_on_order_created"):
					tutorial_manager._on_order_created(self)

func _update_progress_bar():
	if has_active_order and order_progress_bar:
		order_progress_bar.value = (order_timer / order_time_limit) * 100

func timeout_order():
	has_active_order = false
	
	# hide UI
	if order_bubble:
		order_bubble.visible = false
	if order_progress_bar:
		order_progress_bar.visible = false
	
	# emit timeout signal 
	emit_signal("order_timeout")
	print("Order timed out! Angry customer!")
	
	is_angry = true
	customer_state = "idle"

func complete_order(dish_type = "regular"):
	if has_active_order:
		
		if dish_type != current_dish_type and not can_change_order:
			print("wrong dish! customer wants: " + current_dish_type)
			
		has_active_order = false
		customer_state = "idle"
		
		# hide UI
		if order_bubble:
			order_bubble.visible = false
		if order_progress_bar:
			order_progress_bar.visible = false
		
		# calculate delivery time
		var delivery_time = (Time.get_ticks_msec() / 1000.0) - order_start_time
		
		# emit signal w/ delivery time
		emit_signal("order_delivered", self, delivery_time)
		print("Completed order in " + str(delivery_time) + " sec")
	
		return true
	
	return false

func set_received_dish(dish):
	received_dish = dish

func get_received_dish():
	return received_dish


func _on_food_area_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("player"):
		player_in_range = true

func _on_food_area_body_exited(body: Node2D) -> void:
	if body and body.is_in_group("player"):
		player_in_range = false
