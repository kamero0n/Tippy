extends Node

signal order_delivered(delivery_time)
signal order_timeout

@onready var dish_area = $foodArea
@onready var order_timer_display = $orderTimer
@onready var order_bubble = $orderBubble
@onready var order_progress_bar = $orderProgressBar

var has_active_order = false
var order_start_time = 0
var order_time_limit = 30
var order_timer = 0


func _ready() -> void:
	# hide UI
	order_bubble.visible = false
	order_progress_bar.visible = false
	
	# add customers group for players to detect
	add_to_group("customers")

func _process(delta: float) -> void:
	if has_active_order:
		# update timer
		order_timer -= delta
		
		# update progress bar
		order_progress_bar.value = (order_timer / order_time_limit) * 100
		
		# check for timeout
		if order_timer <= 0:
			timeout_order()

func start_order():
	has_active_order = true
	order_timer = order_time_limit
	order_start_time = Time.get_ticks_msec() / 1000.0
	
	# show UI
	order_bubble.visible = true
	order_progress_bar.visible = true
	order_progress_bar.value = 100
	
	_update_progress_bar()
	
	print("Customer started order!")

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

func complete_order():
	if has_active_order:
		has_active_order = false
		
		# hide UI
		order_bubble.visible = false
		order_progress_bar.visible = false
		
		# calculate delivery time
		var delivery_time = (Time.get_ticks_msec() / 1000.0) - order_start_time
		
		# emit signal w/ delivery time
		emit_signal("order_delivered", delivery_time)
		print("Completed order in " + str(delivery_time) + " sec")
	
		return true
	
	return false
		
