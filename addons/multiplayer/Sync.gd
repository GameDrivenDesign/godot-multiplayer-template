extends Node
class_name Sync

export (PoolStringArray) var initial = []
export (PoolStringArray) var synced = []
export (PoolStringArray) var unreliable_synced = []
export (PoolStringArray) var interpolated_synced = []

export var process_only_network_master = false
export var use_ids_for_spawning = true

var synced_last = {}
var unreliable_synced_last = {}
var interpolated_synced_last = {}
var interpolated_synced_target = {}
var is_synced_copy = false
var spawned_at_game_start = false

func _ready():
	var game = get_node("/root/NetworkGame")
	var node = get_parent()
	node.add_to_group("synced")
	
	# execute after the nodes we are syncing
	process_priority = 1000
	
	set_process(synced.size() > 0 or unreliable_synced.size() > 0 or interpolated_synced.size() > 0)
	
	if use_ids_for_spawning and not is_synced_copy and get_tree().has_network_peer():
		node.name += "_" + preload("uuid.gd").v4()
	if node.has_method("_network_ready"):
		node._network_ready(not is_synced_copy)
	
	for property in synced:
		node.rset_config(property, MultiplayerAPI.RPC_MODE_REMOTE)
		synced_last[property] = null
	for property in unreliable_synced:
		node.rset_config(property, MultiplayerAPI.RPC_MODE_REMOTE)
		unreliable_synced_last[property] = null
	for property in interpolated_synced:
		node.rset_config(property, MultiplayerAPI.RPC_MODE_REMOTE)
		interpolated_synced_last[property] = null
	
	if get_tree().has_network_peer() and not is_synced_copy:
		game.server_spawn_object_on_clients(node)
	
	# wait until our parent is also ready, then configure its process
	yield(get_tree(), "idle_frame")
	if process_only_network_master:
		var is_master = node.is_network_master()
		node.set_process(is_master)
		node.set_process_input(is_master)
		node.set_physics_process(is_master)

func remove():
	var node = get_parent()
	if node.is_network_master():
		# we just queue free, next _exit_tree will handle syncing
		node.queue_free()

func _exit_tree():
	var node = get_parent()
	if node.is_network_master():
		rpc("clients_remove")
		check_note_removal()

remote func clients_remove():
	check_note_removal()
	get_parent().queue_free()

func check_note_removal():
	if spawned_at_game_start:
		get_node("/root/NetworkGame").despawned_initial_paths.append(get_parent().get_path())

func _process(delta):
	var node = get_parent()
	if not node.is_network_master():
		for property in interpolated_synced_target:
			get_parent().set(property,
				lerp(get_parent().get(property), interpolated_synced_target[property], delta * 10))
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
	
	for property in interpolated_synced:
		var value = node.get(property)
		# if value != interpolated_synced_last[property]:
		#node.rset_unreliable(property, value)
		rpc_unreliable("interp_set", property, value)
		interpolated_synced_last[property] = value

remote func interp_set(property, value):
	var n = get_parent()
	interpolated_synced_target[property] = value

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
	for property in interpolated_synced:
		var value = get_parent().get(property)
		state[property] = value
		interpolated_synced_last[property] = value
	
	if get_network_master() > 0:
		state['__network_master_id'] = get_network_master()
	return state
