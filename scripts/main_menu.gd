extends Control


func _on_start_pressed() -> void:
	var global = get_node("/root/Global")
	global.current_level = 0
	
	
	var scene_manager = get_node("/root/SceneManager")
	scene_manager.change_to_level(global.current_level)
	
	$AudioStreamPlayer2D.play()
