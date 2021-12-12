extends KinematicBody

var color: Color setget set_color

func _ready():
	rset_config("transform", MultiplayerAPI.RPC_MODE_REMOTE)
	
	randomize()
	set_color(Color.from_hsv(randf(), 1, 1))

func _process(delta):
	if is_network_master():
		move_and_collide(Vector3(0.6, 0, 0) * delta)
		rset("transform", transform)

func set_color(c):
	$mesh/head.material.albedo_color = c
	color = c
