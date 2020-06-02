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

func use_update(state: Dictionary):
	reset = true
	reset_position = state['position']
	reset_linear_velocity = state['linear_velocity']
	reset_angular_velocity = state['angular_velocity']
	reset_rotation = state['rotation']
	
	state.erase('position')
	state.erase('lineary_velocity')
	state.erase('angular_velocity')
	state.erase('rotation')
	
	for property in state:
		self.set(property, state[property])
