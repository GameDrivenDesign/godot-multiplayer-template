extends KinematicBody

var color: Color

func _network_ready(is_source):
	if is_source:
		randomize()
		color = Color.from_hsv(randf(), 1, 1)
	$mesh/head.material.albedo_color = color

func _process(delta):
	move_and_collide(Vector3(0.6, 0, 0) * delta)
