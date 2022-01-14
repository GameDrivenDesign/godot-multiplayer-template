extends KinematicBody2D

var target_id
const SPEED = 50
var target

func _ready():
	if target_id:
		target = get_parent().get_node_or_null(str(target_id))

func _physics_process(delta):
	if target:
		var direction = (target.position - position).normalized()
		var collision = move_and_collide(direction * SPEED * delta)
		if is_network_master() && collision && collision.get_collider().is_in_group("players"):
			collision.get_collider().take_damage()
			$Sync.remove()
