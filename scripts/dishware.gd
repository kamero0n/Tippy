extends Area2D

# dish properties
var price = 10.0
var weight = 1.0
var dish_type = "sardine_pasta"

@onready var sprite = $Sprite2D

var dish_sprites = {
	"sardine_pasta": preload("res://assets/glassware/sardine_pasta.png"),
	"caviar_coral": preload("res://assets/glassware/caviar_coral.png"),
	"toasted_mackerel": preload("res://assets/glassware/toasted_mackerel.png")
}

func _ready():
	# add to dish group for customer to detect
	add_to_group("dish")
	
	if dish_sprites.has(dish_type) and sprite:
		sprite.texture = dish_sprites[dish_type]

func _on_body_entered(body: Node2D) -> void:
	print("dish pick up")
	queue_free()
	
func get_price():
	return price

func get_weight():
	return weight

func get_dish_type():
	return dish_type
