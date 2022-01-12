extends Node
class_name NetworkGame

export(int) var port = 8877
export var ip = 'localhost'
export var max_players = 200
export var auto_connect = true
export(PackedScene) var player_scene
export(NodePath) var players_container
export var change_window_title = true

# Note: this are only emitted on the server
signal player_joined(player, game)
signal player_left(player, game)

var despawned_initial_paths = []

func _ready():
	if not player_scene:
		push_error("Player Scene not set in NetworkGame")
	name = "NetworkGame"
	if auto_connect:
		connect_via_cli()

func connect_via_cli():
	if OS.has_feature("editor"):
		ip = 'localhost'
	
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			match key_value[0]:
				'--ip': ip = key_value[1]
				'--port': port = int(key_value[1])
	
	if is_on_web() or "--client" in OS.get_cmdline_args() or OS.get_environment("USE_CLIENT") == "true":
		connect_client(ip, port)
	else:
		connect_server(port, "--dedicated" in OS.get_cmdline_args())

func connect_client(ip, port):
	var peer = create_client(ip, port)
	assert(get_tree().connect("server_disconnected", self, "client_server_gone") == OK)
	get_tree().set_network_peer(peer)
	
	if change_window_title:
		append_title_string(" (Client)")

func create_client(ip, port):
	print("Connecting to " + ip + ":" + str(port))
	if is_on_web():
		var peer = WebSocketClient.new()
		assert(peer.connect_to_url("wss://" + ip + ":" + str(port), ["wss"], true) == OK)
		return peer
	else:
		var peer = NetworkedMultiplayerENet.new()
		assert(peer.create_client(ip, port) == OK)
		return peer

func connect_server(port, is_dedicated):
	var peer = create_server(port)
	assert(get_tree().connect("network_peer_connected", self, "server_client_connected") == OK)
	assert(get_tree().connect("network_peer_disconnected", self, "server_client_disconnected") == OK)
	get_tree().set_network_peer(peer)
	server_init_world(is_dedicated)
	
	if change_window_title:
		append_title_string(" (Server)")

func create_server(port):
	print("Listening for connections on " + String(port) + " ...")
	if is_for_web():
		print("Using web listener")
		var peer = WebSocketServer.new()
		assert(peer.listen(port, PoolStringArray(), true) == OK)
		return peer
	else:
		print("Using enet/native listener")
		var peer = NetworkedMultiplayerENet.new()
		assert(peer.create_server(port, max_players) == OK)
		return peer

func is_on_web():
	return OS.get_name() == "HTML5"

func is_for_web():
	return OS.has_feature("for_web")

################
# Event Handlers
################

func server_client_connected(new_id: int):
	if new_id != 1:
		print("Connected ", new_id)
		for node in get_tree().get_nodes_in_group("synced"):
			if not node.get_node("Sync").spawned_at_game_start:
				server_spawn_object_for(new_id, node)
		
		for path in despawned_initial_paths:
			rpc("client_despawn_initial", path)
		
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

func get_players_container():
	return players_container if players_container else get_child(0).get_path()

func server_init_world(dedicated):
	for object in get_tree().get_nodes_in_group("synced"):
		var s = object.get_node("Sync")
		s.spawned_at_game_start = true
		if object.has_method("_network_ready"):
			object._network_ready(true)
	
	if not dedicated:
		server_spawn_new_player(1)

remote func client_despawn_initial(path: NodePath):
	get_node(path).queue_free()

func server_spawn_new_player(id: int):
	var new_player = spawn_object("player_" + String(id), get_players_container(), player_scene.instance(), {}, id, true)
	server_spawn_object_on_clients(new_player)
	return new_player

remote func client_remove_player(player_id: int):
	var container = get_node(get_players_container())
	var player = container.get_node(String(player_id))
	container.remove_child(player)
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

func append_title_string(suffix: String):
	var title = ProjectSettings.get("application/config/name")
	OS.set_window_title(title + suffix)
