extends RigidBody2D

var direction: Vector2
var owned_by_id: String
const speed = 500

func _network_ready(is_source):
	if is_source:
		# spawn outside our owner
		position = position + direction * 50
		
		# accelerate in direction of shooting
		rotation = direction.angle()
	
	apply_central_impulse(direction * speed)
	
	if is_network_master():
		yield(get_tree().create_timer(2), "timeout")
		$Sync.remove()

func _integrate_forces(state: Physics2DDirectBodyState):
	if is_network_master():
		for i in range(state.get_contact_count()):
			var body = state.get_contact_collider_object(i)
			if body and body.name != owned_by_id and body.is_in_group("players"):
				body.rpc("kill")
