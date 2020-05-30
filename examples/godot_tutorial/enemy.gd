extends KinematicBody2D

var target
const SPEED = 50

func _physics_process(delta):
	if target:
		var direction = (target.position - position).normalized()
		move_and_collide(direction * SPEED * delta)
