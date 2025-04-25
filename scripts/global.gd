extends Node

# game state vars
var tips_earned = 0
var dishes_broken = 0
var final_score = 0

var current_level = 0
var max_levels = 1

var level_paths = {
	0: "res://scenes/test/tippy_test_tutorial.tscn",
	1: "res://scenes/test/tippy_test.tscn"
}

func get_level_path(level_number):
	if level_number in level_paths:
		return level_paths[level_number]
	else:
		return null
