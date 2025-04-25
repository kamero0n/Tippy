extends Node2D

signal tutorial_step_completed(step_name)

var player 
var camera 
var counter
var manager_pos
var score_label
var dialog_box_instance
var customer_manager

var player_at_counter = false
var initial_dish_shown = false
var waiting_for_dish_cyle = false
var waiting_for_player_at_counter = false
var waiting_for_customer_approach = false
var waiting_for_order_taken = false
var waiting_for_dish_delivery = false

# tutorial state
var tutorial_active = true
var current_step = "intro"

var tutorial_customer = null

# dialog content
var dialog = {
		"intro":[
			"Hey! You're the new guy, Tippy, right?",
			"No time for a long speech, we got to get to work.",
			"Here at Sardinos, we provide high class service to high end customers. Do well, get paid nicely.",
			"Let's go over today's dishes and how to serve our clients."
		],
		"go_to_counter":[
			"Walk over to the kitchen counter to the left to see what dishes we have today. Use A or D to move."
		],
		"counter_intro": [
			"This is our kitchen counter. You'll pick up dishes here from chef.",
			"Today we have two special dishes our chef prepared.",
			"First is our classic Sardine Pasta. Rich in flavor, perfect for a pasta lover. Not for fish folk.",
			"Try pressing E to see our other dish on the menu."
		],
		"caviar_intro": [
			"And here's our delicacy, the Caviar Coral. A crunchy delight packed with flavor.",
			"You can cycle through dishes with E, and pick them up with Q.",
			"Some dishes weight heavier than others, so be careful and try not to make a mess, ok?",
		],
		"customer_intro":[
			"Now, let's start service. See that person over there?",
			"Customers will ask for orders. Once you take down their order, you'll see their patience meter.",
			"If the meter runs out, they get angry and don't tip. So try and be quick alright?",
		],
		"take_order":[
			"Go ahead and take their order by pressing E when you're close to them."
		],
		"deliver_order": [
			"Great! Now go back to the counter and pick up the dish they ordered with Q.",
			"Then deliver it to the customer by pressing E when you're close to them.",
			"Feel free to press shift to sprint, but be careful with the dishes."
		],
		"time_limit":[
			"One more thing - we're only open for a limited time each day.",
			"See that timer at the top? Once it runs out, we're done for the day.",
			"Serve as many customers as you can before time's up to maximize your tips!"
		],
		"special_customers":[
			"Oh, and watch out for special customers... they're rich, but annoying."
		],
		"tutorial_wrap_up": [
			"Okay, customers are going to get angry if we wait any longer. Start serving them!"
		]
	}

func _ready() -> void:
	
	player = get_node("../tippy")
	if not player:
		print("error w/ player")
		return
	
	camera = player.get_node("Camera2D")
	if not camera:
		print("error w/ camera")
		return
		
	counter = get_node("../Counter")
	if not counter:
		print("error w/ counter")
		return
	
	manager_pos = Vector2(player.global_position.x -100, player.global_position.y)
	
	dialog_box_instance = get_node("../UI/DialogManager")
	if not dialog_box_instance:
		print("error pain sadness no ui")
		return
		
	score_label = get_node("../UI/dishes_delivered/dishes_label")
	if score_label:
		score_label.text = ""
		
	if not dialog_box_instance.is_connected("dialog_finished", Callable(self, "_on_dialog_finished")):
		dialog_box_instance.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	
	if counter.has_method("update_dish_label"):
		if not counter.is_connected("dish_cycled", Callable(self, "_on_dish_cycled")):
			counter.connect("dish_cycled", Callable(self, "_on_dish_cycled"))
		print("connected dish_cycled")
			
	if counter.has_node("counter_area"):
		var counter_area = counter.get_node("counter_area")
		if not counter_area.is_connected("body_entered", Callable(self, "_on_counter_area_entered")):
			counter_area.connect("body_entered", Callable(self, "_on_counter_area_entered"))
		if not counter_area.is_connected("body_exited", Callable(self, "_on_counter_area_exited")):
			counter_area.connect("body_exited", Callable(self, "_on_counter_area_exited"))
			
	customer_manager = get_node("../customer_manager")
	if customer_manager:
		if not customer_manager.is_connected("order_created", Callable(self, "_on_order_created")):
			customer_manager.connect("order_created", Callable(self, "_on_order_created"))
		if not customer_manager.is_connected("order_delivered", Callable(self, "_on_order_delivered")):
			customer_manager.connect("order_delivered", Callable(self, "_on_order_delivered"))
	
	# start tutorial after short delay
	await get_tree().create_timer(0.5).timeout
	start_tutorial()

func _process(delta: float) -> void:
	if waiting_for_player_at_counter and player_at_counter:
		waiting_for_player_at_counter = false
		show_dishes_at_counter()
		
	if current_step == "take_order" and waiting_for_order_taken:
		var customers = get_tree().get_nodes_in_group("customers")
		if customers.size() > 0 and tutorial_customer == null:
			tutorial_customer = customers[0]
			
			if tutorial_customer != null:
				tutorial_customer.customer_state = "has_order"
				tutorial_customer.order_bubble.visible = true
				tutorial_customer.has_active_order = false
				
				tutorial_customer.emit_signal("ordered")
				
				# if tutorial_customer
				

func _on_counter_area_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_at_counter = true

func _on_counter_area_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_at_counter = false
		
func _on_dish_cycled(dish_index: int) -> void:
	# print("dish cycled to index: ", dish_index)
	
	if waiting_for_dish_cyle and dish_index == 1:
		waiting_for_dish_cyle = false
		
		await get_tree().create_timer(0.5).timeout
		show_dialog("caviar_intro")

func _on_order_created(customer):
	if waiting_for_order_taken:
		waiting_for_order_taken = false
		tutorial_customer = customer
		
		# show deliver order instructions
		await get_tree().create_timer(0.5).timeout
		show_dialog("deliver_order")

func _on_order_delivered(customer, delivery_time = 0):
	if waiting_for_dish_delivery and customer == tutorial_customer:
		waiting_for_dish_delivery = false
		
		await get_tree().create_timer(0.5).timeout
		show_dialog("time_limit")

func start_tutorial():
	pan_camera_to_manager(Vector2(-50, 0))
	
func pan_camera_to_manager(position: Vector2):
	var original_offset = camera.offset
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "offset", position, 1.0)
	await tween.finished
	
	if current_step == "intro":
		show_dialog("intro")


func pan_camera_to_customer(position: Vector2):
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "offset", position, 1.0)
	await tween.finished
	
	
func show_dialog(dialog_key):
	# instance the dialog box
	dialog_box_instance.visible = true
	
	# add_child(dialog_box_instance)
	
	# print("instantiated node type: ", dialog_box_instance.get_class())
	
	# set content
	if dialog_box_instance.has_method("load_dialog"):
		dialog_box_instance.dialog = dialog[dialog_key]
		dialog_box_instance.dialog_index = 0
	
		# store curr dialogue key to know which one finished
		dialog_box_instance.current_dialog_key = dialog_key
		
		# start dialog
		dialog_box_instance.load_dialog()
		
	else:
		#print("some error man")
		pass
		
			
func show_dishes_at_counter():
	#var counter_offset = Vector2, 0)
	#
	#var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#tween.tween_property(camera, "offset", counter_offset, 1.0)
	#await tween.finished
	
	# get ref to counter
	if counter:
		# reset to first dish
		counter.curr_dish_index = 0
		counter.update_dish_label()
		
		# ensure dish preview is visible
		if counter.has_node("dish_preview"):
			counter.get_node("dish_preview").visible = true
			
		if counter.has_node("dish_label"):
			counter.get_node("dish_label").visible = true
			
	# show dish dialog
	show_dialog("counter_intro")
	
	waiting_for_dish_cyle = true
	initial_dish_shown = true
	
	
func _on_dialog_finished(dialog_key = null):
	if dialog_key == null:
		dialog_key = current_step
	
	emit_signal("tutorial_step_completed", dialog_key)
	
	match dialog_key:
		"intro":
			current_step = "go_to_counter"
			
			pan_camera_back_to_player()
			
			await get_tree().create_timer(0.5).timeout
			show_dialog("go_to_counter")
			
		"go_to_counter":
			current_step = "counter_intro"
			waiting_for_player_at_counter = true
			
		"counter_intro":
			pass
			
		"caviar_intro":
			current_step = "customer_intro"
			
			pan_camera_to_customer(Vector2(150, 0))
			
			await get_tree().create_timer(0.5).timeout
			show_dialog("customer_intro")
			
		"customer_intro":
			current_step = "take_order"
			
			# pan back to player
			pan_camera_back_to_player()
			
			await get_tree().create_timer(0.5).timeout
			show_dialog("take_order")
			
			waiting_for_order_taken = true
		
		"take_order":
			pass
		
		"deliver_order":
			waiting_for_dish_delivery = true
						# Show UI timer
			var timer_node = get_node("../UI/timer_node")
			if timer_node:
				timer_node.visible = true
		
		"time_limit":
			current_step = "tutorial_wrap_up"
			
			pan_camera_to_manager(Vector2(5, 0))
			await get_tree().create_timer(0.5).timeout 
			show_dialog("tutorial_wrap_up")
			#
		#"special_customers":
			#current_step = "tutorial_wrap_up"
			#
			#pan_camera_to_manager(Vector2(5, 0))
			#await get_tree().create_timer(0.5).timeout 
			#show_dialog("tutorial_wrap_up")
			
		"tutorial_wrap_up":
			current_step = "tutorial_complete"
			
			#if counter:
				#if counter.has_node("dish_preview"):
					#counter.get_node("dish_preivew").visible = false
				#if counter.has_node("dish_label"):
					#counter.get_node("dish_label").visible = false
			
			pan_camera_back_to_player()
			
			if score_label:
				score_label.text = "0"
			
			await get_tree().create_timer(0.5).timeout
			emit_signal("tutorial_step_completed", "final_step")
		

func pan_camera_back_to_player():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "offset", Vector2.ZERO, 1.0)
	await tween.finished

	
