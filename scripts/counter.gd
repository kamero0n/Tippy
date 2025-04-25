extends StaticBody2D

signal dish_taken
signal dish_cycled(dish_index)

@onready var counter_area = $counter_area
@onready var dish_preview = $dish_preview

var atCounter = false
var dish = preload("res://scenes/objects/dishware.tscn")

var dish_types = {
	"sardine_pasta": {
		"price": 8.0,
		"weight": 1.0,
		"description": "Sardine pasta"
	},
	"caviar_coral":{
		"price": 15.0,
		"weight": 0.9,
		"description": "Caviar with Coral"
	}
}

var preview_sprites = {
	"sardine_pasta": preload("res://assets/glassware/spaghetPlate.png"),
	"caviar_coral": preload("res://assets/glassware/wineCup.png")
}

var curr_dish_index = 0
var dish_keys = ["sardine_pasta", "caviar_coral"]

func _ready() -> void:
	if has_node("dish_label"):
		update_dish_label()
	
	if has_node("dish_preview"):
		update_dish_preview()

func update_available_dishes(available_dishes):
	if available_dishes and available_dishes.size() > 0:
		dish_keys = available_dishes.duplicate()
		curr_dish_index = 0
		update_dish_label()
		update_dish_preview()


func _on_counter_area_body_entered(body: Node2D) -> void:
	# check if the player entered the area of the counter
	if body.is_in_group("player"):
		atCounter = true
		
		if has_node("dish_label"):
			get_node("dish_label").visible = true
		
		if has_node("dish_preview"):
			get_node("dish_preview").visible = true

func _on_counter_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		atCounter = false
		
		if has_node("dish_label"):
			get_node("dish_label").visible = false
			
		if has_node("dish_preview"):
			get_node("dish_preview").visible = false
		
func _process(delta: float) -> void:
	if atCounter == true:
		# check if player is cycling through dishes
		if Input.is_action_just_pressed("cycle_dishes"):
			curr_dish_index = (curr_dish_index + 1) % dish_keys.size()
			update_dish_label()
			emit_signal("dish_cycled", curr_dish_index)
		
		# check if the player is pressing the interact key
		if Input.is_action_just_pressed("pick_up"):
			if dish_keys.size() > 0:
				var dish_instance = dish.instantiate()
			
				# get curr dish type
				var curr_dish_type = dish_keys[curr_dish_index]
				
				# set properties based on type
				dish_instance.dish_type = curr_dish_type
				dish_instance.price = dish_types[curr_dish_type]["price"]
				dish_instance.weight = dish_types[curr_dish_type]["weight"]
			
			
				emit_signal("dish_taken", dish_instance)


func update_dish_label():
	if has_node("dish_label"):
		var curr_dish_type = dish_keys[curr_dish_index]
		var dish_info = dish_types[curr_dish_type]
		get_node("dish_label").text = dish_info["description"] + "\n$" + str(dish_info["price"])
	
	update_dish_preview()

func update_dish_preview():
	if has_node("dish_preview"):
		var curr_dish_type = dish_keys[curr_dish_index]
		if preview_sprites.has(curr_dish_type):
			get_node("dish_preview").texture = preview_sprites[curr_dish_type]
			get_node("dish_preview").visible = true
