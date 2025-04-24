extends Control



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	var scene_manager = get_node("/root/SceneManager")
	scene_manager.change_scene("res://scenes/test/tippy_test.tscn")
