class_name SkirmishRangeCircle
extends Node2D

var radius := 200

func _draw() -> void:
	var center = Vector2(0, 0) # Change this to your desired position
	
	# 1. Draw the background with 0.5 opacity (alpha)
	# Color(Red, Green, Blue, Alpha)
	var bg_color = Color(0.341, 0.718, 0.937, 0.396) 
	draw_circle(center, radius, bg_color)
	
	# 2. Draw the 2px stroke on top
	var stroke_color = Color(0.341, 0.718, 0.937) # Solid blue stroke (or change to Color.WHITE, etc.)
	var stroke_width = 2.0
	var point_count = 64 # Higher numbers make the circle edge smoother
	
	# draw_arc arguments: center, radius, start_angle, end_angle, point_count, color, width, antialiased
	draw_arc(center, radius, 0.0, TAU, point_count, stroke_color, stroke_width, true)
