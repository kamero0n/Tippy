extends Control


@onready var tips = $tips
@onready var dishes = $dishBroke
@onready var score = $totalScore

var tips_earned = 0
var dishes_broken = 0
var final_score = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var global = get_node("/root/Global")
	tips_earned = global.tips_earned
	dishes_broken = global.dishes_broken
	final_score = global.final_score
	
	update_score_display()


func initialize(tip, dish, finalscore):
	tips_earned = tip
	dishes_broken = dish
	final_score = finalscore
	
	if is_inside_tree():
		update_score_display()

func update_score_display():
	var format_tips = "%.2f" % tips_earned
	var format_score = "%.2f" % final_score
	
	
	tips.text = "Tips Earned: $" + format_tips
	dishes.text = "Dishes Broken: " + str(dishes_broken)
	score.text = "Total Earnings: $" + format_score


func _on_main_pressed() -> void:
	var scene_manager = get_node("/root/SceneManager")
	scene_manager.change_scene("res://scenes/main_menu.tscn")
	
func _on_restart_pressed() -> void:
	var scene_manager = get_node("/root/SceneManager")
	scene_manager.change_scene("res://scenes/test/tippy_test.tscn")
