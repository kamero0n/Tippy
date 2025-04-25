extends Control

signal dialog_finished

var dialog = ["meow meow"]
var current_dialog_key = ""

var dialog_index = 0
var finished = false
var current_tween = null

func _ready() -> void:
	# load_dialog()
	print("dialog box ready at: ", get_path())
	
	visible = false
	
func _process(delta: float) -> void:
	# $dialogBox/E.visible = finished
	if Input.is_action_just_pressed("continue"):
		load_dialog()

func load_dialog():
	if dialog_index < dialog.size():
		finished = false
		$dialogBox/RichTextLabel.text = dialog[dialog_index]
		$dialogBox/RichTextLabel.visible_ratio = 0
		
		current_tween = create_tween()
		
		current_tween.tween_property(
			$dialogBox/RichTextLabel, "visible_ratio", 1, 0.5
		)
		
		current_tween.finished.connect(_on_tween_finished)
		current_tween.play()
		
	else:
		emit_signal("dialog_finished", current_dialog_key)
		# queue_free()
		
		visible = false
		dialog_index = 0
	
		
	dialog_index += 1
	
func _on_tween_finished():
	$dialogBox/E.visible = true
	finished = true
