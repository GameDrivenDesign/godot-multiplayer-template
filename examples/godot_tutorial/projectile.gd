extends KinematicBody2D

var direction
const SPEED = 300

func _physics_process(delta):
	var collision = move_and_collide(direction * delta * SPEED)
	if collision and collision.get_collider().is_in_group("enemy"):
		collision.get_collider().queue_free()

