extends Node

export (PoolStringArray) var synced_properties = ['position']

func _ready():
	get_parent().add_to_group("synced")

func get_sync_state():
	var state = {}
	for property in synced_properties:
		state[property] = get_parent().get(property)
	return state
