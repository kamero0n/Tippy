extends CharacterBody2D


const SPEED = 180.0
const SPRINT_SPEED = 280.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite = $body
@onready var camera = $Camera2D
@onready var tray = $tray
@onready var tray_sprite = $tray/tray_image

var curr_speed = SPEED

var sprinting = false
var carrying_dish = false
var facing_right = false

func _ready() -> void:
	add_to_group("player")
	
	# limit the camera for left
	camera.limit_left = global_position.x - 250
	
	# hide tray
	tray_sprite.visible = false


func _input(event):
	# handle if we press E which likely means we need to drop the dish
	if event.is_action_pressed("drop"):
		deliver_dish()
	
	if event.is_action_pressed("take_order"):
		pass


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump. for now... no jump :[
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	
	# check if we are sprinting
	sprinting = Input.is_action_pressed("sprint")
	curr_speed = SPRINT_SPEED if sprinting else SPEED

	# Get the input direction: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	# flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
		facing_right = true
		
		# position tray on right side
		if carrying_dish == true:
			tray_sprite.flip_h = false
			tray.position = Vector2(26.0, -53.0)
			
		
	elif direction < 0:
		animated_sprite.flip_h = true
		facing_right = false
		
		# position tray on left side
		if carrying_dish == true:
			tray_sprite.flip_h = true
			tray.position = Vector2(-26.0, -53.0)
	
	# play anims
	if(is_on_floor()):
		if direction == 0:
			if carrying_dish == false:
				animated_sprite.play("idle")

			else:
				animated_sprite.play("carry_idle")
		else:
			if carrying_dish == false:
				animated_sprite.play("walk")
			else:
				animated_sprite.play("carry_walk")
	
	# apply movement
	if direction:
		var target_velocity = direction * curr_speed
		velocity.x = lerp(velocity.x, target_velocity, 0.25)
	
	else:
		velocity.x = move_toward(velocity.x, 0, curr_speed)

	move_and_slide()
	
	if carrying_dish:
		tray.update_balance(delta, velocity, sprinting, direction)
	


func deliver_dish():
	# check if we're near a customer w/ active order
	var customers = get_tree().get_nodes_in_group("customers")
	for customer in customers:
		# check dist to customer
		var distance = global_position.distance_to(customer.global_position)
		if distance < 100 and customer.has_active_order:
			# get the top dish from the tray
			var dish = tray.remove_top_dish()
			
			if dish:
				# signal customer that they received their order
				customer.complete_order()
				
				# remove dish from scene
				dish.queue_free()
				
				# if no dishes left, hide tray
				if tray.stacked_dishes.size() <= 0:
					tray_sprite.visible = false
					carrying_dish = false
				
				return
	

func _on_counter_dish_taken(dish_scene: PackedScene) -> void:
	# if this is the first dish, show the tray
	if !carrying_dish:
		tray_sprite.visible = true
		carrying_dish = true
		
		# set initial tray pos
		if facing_right:
			tray_sprite.flip_h = false
			tray.position = Vector2(26.0, -53.0)
		else:
			tray_sprite.flip_h = true
			tray.position = Vector2(-26.0, -53.0)
	
	# add as child of tray
	tray.add_dish(dish_scene)
