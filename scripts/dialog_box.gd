extends Control

var dialog = [
	'Hello there, this is a demo',
	'MEOW MEOW MEOW'
]

var dialog_index = 0
var finished = false
var current_tween = null

func _ready() -> void:
	load_dialog()
	
func _process(delta: float) -> void:
	$E.visible = finished
	if Input.is_action_just_pressed("interact"):
		load_dialog()

func load_dialog():
	if dialog_index < dialog.size():
		finished = false
		$RichTextLabel.text = dialog[dialog_index]
		$RichTextLabel.visible_ratio = 0
		
		current_tween = create_tween()
		
		current_tween.tween_property(
			$RichTextLabel, "visible_ratio", 1, 0.5
		)
		
		current_tween.finished.connect(_on_tween_finished)
		current_tween.play()
		
	else:
		queue_free()
		
	dialog_index += 1
	
func _on_tween_finished():
	finished = true
