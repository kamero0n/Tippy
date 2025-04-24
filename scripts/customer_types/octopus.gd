extends Customer
class_name Octopus

# high patience low tip!

func _ready():
	super._ready()
	customer_type = "octopus"

func initialize_customer_type():
	order_time_limit = 30.0
	tip_multiplier = 0.5
	
	print("octopus customer!")
