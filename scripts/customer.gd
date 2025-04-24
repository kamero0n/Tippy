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

var customer_state = "idle"
var has_active_order = false
var order_start_time = 0
var order_time_limit = 20
var order_timer = 0
var player_in_range = false
var customer_type = "regular"

var tip_multiplier = 1.0
var can_change_order = false
var wrong_dish_penalty = 10.0

var current_dish_type = "regular"

func _ready() -> void:
	# hide UI
	order_bubble.visible = false
	order_progress_bar.visible = false
	
	# add customers group for players to detect
	add_to_group("customers")
	
	# init based on customer type
	initialize_customer_type()
	
func initialize_customer_type():
	pass

func _process(delta: float) -> void:
	if has_active_order:
		# update timer
		order_timer -= delta
		
		# update progress bar
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
	
	# show only order bubble
	order_bubble.visible = true
	order_progress_bar.visible = false
	
	# set dish type
	current_dish_type = "regular"
	
	emit_signal("ordered")

func start_order():
	if customer_state == "has_order":
		customer_state = "waiting_for_food"
		
		has_active_order = true
		order_timer = order_time_limit
		order_start_time = Time.get_ticks_msec() / 1000.0
		
		# show UI
		order_bubble.visible = false
		order_progress_bar.visible = true
		order_progress_bar.value = 100
		
		emit_signal("order_taken")
	
	# print("Customer started order!")

func _update_progress_bar():
	if has_active_order:
		order_progress_bar.value = (order_timer / order_time_limit) * 100

func timeout_order():
	has_active_order = false
	
	# hide UI
	order_bubble.visible = false
	order_progress_bar.visible = false
	
	# emit timeout signal 
	emit_signal("order_timeout")
	print("Order timed out! Angry customer!")
	
	customer_state = "idle"

func complete_order(dish_type = "regular"):
	if has_active_order:
		
		if dish_type != current_dish_type and can_change_order:
			print("wrong dish! customer wants: " + current_dish_type)
			
		has_active_order = false
		customer_state = "idle"
		
		# hide UI
		order_bubble.visible = false
		order_progress_bar.visible = false
		
		# calculate delivery time
		var delivery_time = (Time.get_ticks_msec() / 1000.0) - order_start_time
		
		# emit signal w/ delivery time
		emit_signal("order_delivered", self, delivery_time)
		print("Completed order in " + str(delivery_time) + " sec")
	
		return true
	
	return false
		

func _on_food_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_food_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
