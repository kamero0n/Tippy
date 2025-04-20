extends Area2D

func _ready():
	# add to dish group for customer to detect
	add_to_group("dish")

func _on_body_entered(body: Node2D) -> void:
	print("dish pick up")
	queue_free()
