extends Node2D

var port = 8877
var ip = 'localhost'
var max_players = 200

func _ready():
	var peer = NetworkedMultiplayerENet.new()
	var is_client = "--client" in OS.get_cmdline_args()
	var is_dedicated = "--dedicated" in OS.get_cmdline_args()
	
	if is_client:
		peer.create_client(ip, port)
		get_tree().connect("server_disconnected", self, "client_note_disconnected")
	else:
		print("Listening for connections on " + String(port) + " ...")
		peer.create_server(port, max_players)
		get_tree().connect("network_peer_connected", self, "server_player_connected")
		get_tree().connect("network_peer_disconnected", self, "server_player_disconnected")
		if not is_dedicated:
			register_player(1, {})
	
	get_tree().set_network_peer(peer)

func client_note_disconnected():
	print("Server disconnected from player, exiting ...")
	get_tree().quit()

func server_player_connected(player_id: int):
	if player_id != 1:
		print("Connected ", player_id)
		# get our new player informed about all the old players and objects
		for old_player in get_tree().get_nodes_in_group("players"):
			rpc_id(player_id, "register_player", old_player.id, old_player.get_sync_state())
		for node in get_tree().get_nodes_in_group("synced"):
			rpc_id(player_id, "spawn_object", node.name, node.filename, node.get_node("sync").get_sync_state())
		
		# inform all our players about the new player
		var new_player = register_player(player_id, {})
		rpc("register_player", player_id, new_player.get_sync_state())

func server_player_disconnected(player_id: int):
	print("Disconnected ", player_id)
	rpc("unregister_player", player_id)

remote func spawn_object(name: String, filename: String, state: Dictionary):
	# either create the object or just find the existing one
	var object: Node2D = get_node_or_null(name)
	if not object:
		object = load(filename).instance()
		object.name = name
		add_child(object)
	
	# rigid bodys need to be our syncable_rigid_body because you can't set the
	# position or any other physics property outside of its own _integrate_forces
	if object is RigidBody2D:
		object.use_update(state)
	else:
		for property in state:
			object.set(property, state[property])
	
	return object

remote func register_player(player_id: int, state: Dictionary):
	var player: Node2D = preload("res://player/player.tscn").instance()
	player.id = player_id
	player.set_network_master(player.id)
	player.name = String(player.id)
	player.add_to_group("players")
	
	add_child(player)
	
	for property in state:
		player.set(property, state[property])
	return player

remotesync func unregister_player(player_id: int):
	remove_child(get_node(String(player_id)))
