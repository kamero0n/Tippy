extends Node2D

const MAIN_MENU = preload("res://scenes/main_menu.tscn")
const TIPPY_TEST = preload("res://scenes/test/tippy_test.tscn")
const END_LEVEL = preload("res://scenes/end_level.tscn")

@onready var transition_screen = $TransitionScreen
@onready var curr_scene_container = $CurrentScene

var curr_scene = null
var next_scene = null

func _ready():
	# set initial scene (main menu)
	if get_tree().current_scene != self:
		return
	
	transition_screen.visible = false
	
	set_current_scene(MAIN_MENU.instantiate())
	
func change_scene(scene_path):
	# store scene path to load after transition
	next_scene = scene_path
	
	# start transition
	transition_screen.visible = true
	transition_screen.transition()


func set_current_scene(scene):
	# remove curr scene if it exists
	if curr_scene != null:
		curr_scene_container.remove_child(curr_scene)
		curr_scene.queue_free()
	
	# add new scene
	curr_scene = scene
	curr_scene_container.add_child(curr_scene)
	transition_screen.visible = false

func _on_transition_screen_transitioned() -> void:
	if next_scene != null:
		# load next scene
		var scene_instance
		
		if typeof(next_scene) == TYPE_STRING:
			scene_instance = load(next_scene).instantiate()
		
		elif next_scene is PackedScene:
			scene_instance = next_scene.instantiate()
		else:
			scene_instance = next_scene
		
		set_current_scene(scene_instance)
		next_scene = null
