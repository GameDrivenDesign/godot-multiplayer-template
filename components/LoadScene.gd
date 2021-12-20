extends Node2D

var level_path: String setget _set_level_path

# Called when the node enters the scene tree for the first time.
func _ready():
	rset_config('level_path', MultiplayerAPI.RPC_MODE_REMOTESYNC)

func set_level(new_path: String):
	rset('level_path', new_path)

func _set_level_path(new_path: String):
	level_path = new_path
	for child in get_children():
		# take care to not delete the sync component
		if child.name != 'Sync':
			self.remove_child(child)
			child.queue_free()
	
	var new_level = load(new_path).instance()
	add_child(new_level)
