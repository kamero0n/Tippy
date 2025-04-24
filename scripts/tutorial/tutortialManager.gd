extends Node2D

signal tutorial_step_completed(step_name)

var player 
var camera 
var manager_pos
var dialog_box_instance

# tutorial state
var tutorial_active = true
var current_step = "intro"

# dialog content
var dialog = {
		"intro":[
			"Hey! You're the new guy, Tippy, right?",
			"No time for a long speech, we got to get to work.",
			"Here at Sardinos, we provide high class service to high end customers. Do well, get paid nicely.",
			"Let's go over today's dishes and how to serve our clients."
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
	
	manager_pos = Vector2(player.global_position.x -100, player.global_position.y)
	
	dialog_box_instance = get_node("../UI/DialogManager")
	if not dialog_box_instance:
		print("error pain sadness no ui")
		return
		
	if not dialog_box_instance.is_connected("dialog_finished", Callable(self, "_on_dialog_finished")):
		dialog_box_instance.connect("dialog_finished", Callable(self, "_on_dialog_finished"))
	
	# start tutorial after short delay
	await get_tree().create_timer(0.5).timeout
	start_tutorial()

func start_tutorial():
	pan_camera_to_manager()
	
func pan_camera_to_manager():
	var original_offset = camera.offset
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "offset", Vector2(-50, 0), 1.0)
	await tween.finished
	
	show_dialog("intro")
	

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
		print("some error man")

func _on_dialog_finished(dialog_key = null):
	if dialog_key == null:
		dialog_key = current_step
	
	emit_signal("tutorial_step_completed", dialog_key)
	
	match dialog_key:
		"intro":
			pan_camera_back_to_player()

func pan_camera_back_to_player():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "offset", Vector2.ZERO, 1.0)
	await tween.finished

	
