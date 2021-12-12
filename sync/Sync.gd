extends Node

export (PoolStringArray) var synced_properties = []

func _ready():
	get_parent().add_to_group("synced")

func get_sync_state():
	var state = {}
	for property in synced_properties:
		state[property] = get_parent().get(property)
	state['__network_master_id'] = get_network_master()
	return state
