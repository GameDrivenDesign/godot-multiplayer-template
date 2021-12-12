extends Node
class_name Player

var id: int setget set_id

func set_id(new_id: int):
	set_network_master(new_id)
	id = new_id
