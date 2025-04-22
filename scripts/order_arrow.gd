extends Node2D

@onready var arrow_sprite = $Sprite2D

var height = 3.0
var speed = 4.0
var init_pos = Vector2

# ref to target
var target_customer = null
var player = null

func _ready() -> void:
	visible = false
	
func _process(delta: float) -> void:
	# only show and update if we have a target
	if target_customer == null or player == null:
		visible = false
		return
		
	var camera = player.get_node("Camera2D")
	var screen_size = get_viewport_rect().size
	var target_position = target_customer.global_position
	
	var camera_pos = camera.get_screen_center_position()
	
	# calc screen bounds
	var screen_left = camera_pos.x - screen_size.x/2
	var screen_right = camera_pos.x + screen_size.x/2
	var screen_top = camera_pos.y - screen_size.y/2
	var screen_bottom = camera_pos.y + screen_size.y/2
	
	# check if customer is visible on screen
	if(target_position.x >= screen_left and
		target_position.x <= screen_right and
		target_position.y >= screen_top and 
		target_position.y <= screen_bottom):
		visible = false
		return
	
	visible = true
	
	# calc direction to target
	var dir = (target_position - player.global_position).normalized()
	
	var arrow_pos = Vector2()
