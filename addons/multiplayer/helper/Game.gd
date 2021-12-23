extends Node

export var port = 8877
export var ip = 'localhost'
export var max_players = 200
export(PackedScene) var player_scene
var is_server = false

# Note: this are only emitted on the server
signal player_joined(player, game)
signal player_left(player, game)

func _ready():
	if not player_scene:
		push_error("Player Scene not set in NetworkGame")
	
	var peer = NetworkedMultiplayerENet.new()
	var is_client = "--client" in OS.get_cmdline_args() or OS.get_environment("USE_CLIENT") == "true"
	var is_dedicated = "--dedicated" in OS.get_cmdline_args()
	is_server = not is_client
	
	name = "Game"
	
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			match key_value[0]:
				'--ip': ip=key_value[1]
				'--port': port=int(key_value[1])
	
	if is_client:
		assert(peer.create_client(ip, port) == OK)
		assert(get_tree().connect("server_disconnected", self, "client_server_gone") == OK)
	else:
		print("Listening for connections on " + String(port) + " ...")
		assert(peer.create_server(port, max_players) == OK)
		assert(get_tree().connect("network_peer_connected", self, "server_client_connected") == OK)
		assert(get_tree().connect("network_peer_disconnected", self, "server_client_disconnected") == OK)
	
	get_tree().set_network_peer(peer)
	
	if not is_client:
		server_init_world(is_dedicated)

################
# Event Handlers
################

func server_client_connected(new_id: int):
	if new_id != 1:
		print("Connected ", new_id)
		for node in get_tree().get_nodes_in_group("synced"):
			if not node.get_node("Sync").spawned_at_game_start:
				server_spawn_object_for(new_id, node)
		
		var player = server_spawn_new_player(new_id)
		emit_signal("player_joined", player, self)

func server_client_disconnected(id: int):
	print("Disconnected ", id)
	var player = client_remove_player(id)
	rpc("client_remove_player", id)
	emit_signal("player_left", player, self)

func client_server_gone():
	print("Server disconnected from player, exiting ...")
	get_tree().quit()

##################
# Helper Functions
##################

func get_level():
	return get_child(0)

func server_init_world(dedicated):
	for object in get_tree().get_nodes_in_group("synced"):
		var s = object.get_node("Sync")
		s.spawned_at_game_start = true
		if object.has_method("_network_ready"):
			object._network_ready(true)
	
	if not dedicated:
		server_spawn_new_player(1)

func server_spawn_new_player(id: int):
	var new_player = spawn_object("player_" + String(id), get_level().get_path(), player_scene.instance(), {}, id, true)
	server_spawn_object_on_clients(new_player)
	return new_player

remote func client_remove_player(player_id: int):
	var player = get_level().get_node(String(player_id))
	get_level().remove_child(player)
	return player

func get_sync(object: Node):
	var s = object.get_node_or_null("Sync")
	if not s:
		return {}
	else:
		return s.get_sync_state()

func server_spawn_object_on_clients(object: Node):
	rpc("spawn_object", object.name, object.get_parent().get_path(), object.filename, get_sync(object), 0, false)

func server_spawn_object_for(client_id: int, object: Node):
	rpc_id(client_id, "spawn_object", object.name, object.get_parent().get_path(), object.filename, get_sync(object))

remote func spawn_object(name: String, parent_path: NodePath, filenameOrNode, state: Dictionary, master_id: int = 0, is_source = false):
	# The parent_node MUST exist before spawning the object
	var parent: Node = get_node(parent_path)
	var add_to_scene = false
	
	var object: Node = parent.get_node_or_null(name)
	if not object:
		object = filenameOrNode if filenameOrNode is Node else load(filenameOrNode).instance()
		object.name = name
		var s = object.get_node_or_null("Sync")
		if s:
			s.is_synced_copy = not is_source
		if master_id > 0:
			object.set_network_master(master_id)
		add_to_scene = true
	
	if object.has_method("_use_update"):
		object._use_update(state)
	else:
		for property in state:
			if property == '__network_master_id':
				object.set_network_master(state[property])
			else:
				object.set(property, state[property])
	
	if add_to_scene:
		parent.add_child(object)
	
	return object
