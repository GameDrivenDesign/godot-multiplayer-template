extends RigidBody2D

var reset = false
var reset_linear_velocity
var reset_angular_velocity
var reset_position
var reset_rotation

func _integrate_forces(state: Physics2DDirectBodyState):
	if reset:
		reset = false
		state.transform = Transform2D(reset_rotation, reset_position)
		state.linear_velocity = reset_linear_velocity
		state.angular_velocity = reset_angular_velocity

func use_update(position: Vector2, state: Dictionary):
	reset = true
	reset_position = position
	reset_linear_velocity = state['linear_velocity']
	reset_angular_velocity = state['angular_velocity']
	reset_rotation = state['rotation']
