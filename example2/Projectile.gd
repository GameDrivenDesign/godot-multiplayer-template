extends KinematicBody2D

var direction
const SPEED = 300

func _ready():
	# wait for a bit then kill the projectile
	if is_network_master():
		yield(get_tree().create_timer(3), "timeout")
		rpc("kill")

func _physics_process(delta):
	var collision = move_and_collide(direction * delta * SPEED)
	if collision and collision.get_collider().is_in_group("enemy"):
		collision.get_collider().queue_free()

remotesync func kill():
	queue_free()
