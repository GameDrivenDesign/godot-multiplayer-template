extends Node

export (PoolStringArray) var initial = []
export (PoolStringArray) var synced = []
export (PoolStringArray) var unreliable_synced = []

export var process_only_network_master = false
export var use_ids_for_spawning = true

var synced_last = {}
var unreliable_synced_last = {}
var is_synced_copy = false
var spawned_at_game_start = false

func _ready():
	var game = get_node("/root/Game")
	var node = get_parent()
	node.add_to_group("synced")
	
	# execute after the nodes we are syncing
	process_priority = 1000
	
	set_process(synced.size() > 0 or unreliable_synced.size() > 0)
	
	if use_ids_for_spawning and not is_synced_copy:
		node.name += "_" + preload("uuid.gd").v4()
	if node.has_method("_network_ready"):
		node._network_ready(not is_synced_copy)
	
	for property in synced:
		node.rset_config(property, MultiplayerAPI.RPC_MODE_REMOTE)
		synced_last[property] = null
	for property in unreliable_synced:
		node.rset_config(property, MultiplayerAPI.RPC_MODE_REMOTE)
		unreliable_synced_last[property] = null
	
	if not is_synced_copy:
		game.server_spawn_object_on_clients(node)
	
	# wait until our parent is also ready, then configure its process
	yield(get_tree(), "idle_frame")
	if process_only_network_master:
		var is_master = node.is_network_master()
		node.set_process(is_master)
		node.set_process_input(is_master)
		node.set_physics_process(is_master)

func _exit_tree():
	if get_parent().is_network_master():
		rpc("remove")

remote func remove():
	get_parent().queue_free()

func _process(_delta):
	var node = get_parent()
	if not node.is_network_master():
		return
	
	for property in synced:
		var value = node.get(property)
		if value != synced_last[property]:
			node.rset(property, value)
			synced_last[property] = value
	
	for property in unreliable_synced:
		var value = node.get(property)
		if value != unreliable_synced_last[property]:
			node.rset_unreliable(property, value)
			unreliable_synced_last[property] = value

func get_sync_state():
	var state = {}
	
	for property in initial:
		state[property] = get_parent().get(property)
	for property in synced:
		var value = get_parent().get(property)
		state[property] = value
		synced_last[property] = value
	for property in unreliable_synced:
		var value = get_parent().get(property)
		state[property] = value
		unreliable_synced_last[property] = value
	
	if get_network_master() > 0:
		state['__network_master_id'] = get_network_master()
	return state
