extends Customer
class_name Shark

# low patience high tip!

func _ready():
	super._ready()
	customer_type = "shark"

func initialize_customer_type():
	order_time_limit = 15.0
	tip_multiplier = 2.0
	
	print("shark customer!")
