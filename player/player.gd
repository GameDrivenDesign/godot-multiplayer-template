extends Node2D

var color setget set_color

func _network_ready(is_source):
	if is_source:
		set_color(Color.from_hsv(rand_range(1, 360), 1, 1))
		position = Vector2(rand_range(0, 600), rand_range(0, 400))

func set_color(c):
	color = c
	$token.color = c
