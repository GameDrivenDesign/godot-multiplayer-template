extends Node

# list of properties to synchronize on game start
export (PoolStringArray) var initial = []

export (PoolStringArray) var synced = []

export (PoolStringArray) var unreliable_synced = []


#####
# SYNCING HINTS FOR SERVER
#####
# indicates whether this object had been spawned as part of the game's initial
# configuration (i.e. it won't need to be spawned again later)
var spawned_at_start = false
# indicates whether this object has already seen once by the Game
var is_new = true

var synced_last = {}
var unreliable_synced_last = {}

func _ready():
	get_parent().add_to_group("synced")
	
	# execute after the nodes we are syncing
	process_priority = 1000
	
	set_process(synced.size() > 0 or unreliable_synced.size() > 0)
	
	for property in synced:
		get_parent().rset_config(property, MultiplayerAPI.RPC_MODE_REMOTE)
		synced_last[property] = null
	for property in unreliable_synced:
		get_parent().rset_config(property, MultiplayerAPI.RPC_MODE_REMOTE)
		unreliable_synced_last[property] = null

func _process(_delta):
	if not get_parent().is_network_master():
		return
	
	for property in synced:
		var value = get_parent().get(property)
		if value != synced_last[property]:
			get_parent().rset(property, value)
			synced_last[property] = value
	
	for property in unreliable_synced:
		var value = get_parent().get(property)
		if value != unreliable_synced_last[property]:
			get_parent().rset_unreliable(property, value)
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
