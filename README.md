# Godot Multiplayer Template

Enables a peer-to-peer connection between instances of a Godot game.
Aims to have you change your code as little as possible and do most things via configuration.

## Getting Started

1. Install the addon by copying the `addons/multiplayer` folder to your project in the same location.
2. Go to `Project > Project Settings > Plugins` and enable the multiplayer addon.

### Setup

1. Create a player scene. Add a `Sync` node as a child of the player.
2. Create a game scene, make its root the `NetworkGame` node. Set its `player scene` field to your player scene.
3. Start multiple instances of the game at the same time using the "Debug Server" button in the top-right.
4. Continue building your game as normal, until you find things are out-of-sync. Then refer to the below.

### Synchronize a property

1. Add a `Sync` node to the scene as a **direct child** of the scene root.
2. In the `Sync`, add the property to `synced` or `unreliable_synced` for faster but potentially dropped updates.

### Respond to Events and Input

All objects exist on all clients, so their code executes simultaneously on all clients.
This can lead to the simulation going out of sync.
Thus, we usually designate a single "authority" or "network master" for each object that is being simulated.

1. In `Sync`, you can check `process only on master` to automatically run `_process`/`_physics_process`/`_input` only on the network master.
2. For events, such as collisions or timeouts, use `is_network_master()`.

```gdscript
func on_collided(other):
	if is_network_master() and other.is_in_group("projectile"):
		queue_free()
```

### Initialize a property with a value that should be the same everywhere

This applies to e.g. random numbers or values dependend on the number of players. If your value is constant you of course don't need to synchronize it.

1. Add a `Sync` node or reuse an existing one. Add the property name to the `initial` list.
2. Create a `_network_ready(is_source)` func.
3. if `is_source`, decide set the property.
4. if not `is_source`, you will have access to the same value that was decided on the source client (i.e., the client that first spawned this object)

```gdscript
var level_seed
func _network_ready(is_source):
	if is_source:
		level_seed = int(rand_range(0, 100))

	var r = RandomNumberGenerator.new()
	r.seed = level_seed
	...
```

### Use setters to synchronize derived state

To ensure that synchronizing a single property has the desired effects, create a setter that receives the new value and applies all changes.

```gdscript
var color setget set_color

func set_color(c):
	color = c
	$Material.override_color = c
```

### Removing a synced node

Make sure that only the network master of an object is removing a node. This can be done automatically via

```gdscript
$Sync.remove()
```

, which will only issues `queue_free` on the network master, or by using the `is_network_master` guard seen in "Respond to input" above.

### Call a function on all devices

First off, always try to use setters to synchronize state instead of functions. They make your program more solid in terms of players joining late and are easier to reason about.

If you still want to call a function on all devices,

1. Put `remotesync` in front of the function name
2. Use `rpc("funcname", arg1)`.

```gdscript
func shoot():
	...
	rpc("shake_camera", 30)

remotesync func shake_camera(amount):
	$Camera.start_shake(amount)
```

### Get all players

The idiomatic way to get all players is to add a "player" group to your player scene.
You can then use

```gdscript
get_tree().get_nodes_in_group("players")
```

Additionally, **only on the server** you can receive a signal that notifies you about players joining or leaving.
Check the NetworkGame signals tab and connect the signals to any node that needs to be notified, e.g. your main game scene.

### Configuration and Autoconnect

You can configure the IP address, the port, the maximum number of players in the inspector on the NetworkGame node. By default the game will run on `localhost:8877` and allow for up to 200 players. Both can be overridden by command line arguments.

Alternatively, you can disable `auto_connect` on the NetworkGame and use `connect_client` and `connect_server` directly.

### Exporting

The addon supports native platforms as well as exports for the web.
Exporting for a native platform is the same as usual.
To export for the web, you'll need two builds:

1. The export for the client. Configure this as usual for the `HTML5` platform.
2. The export for the server. This one needs to run on a native platform.
   You also need to **add the feature** `for_web` under the _Features_ tab in the _Custom_ input field.

## Examples

The example folder contains two small game demos.

### Pong

Set `res://example1/PongExample.tscn` as the main scene and launch the game.

Once a player joined, they are assigned a random color, and can move around using the arrow keys. Pressing Enter allows players to spawn blocks in the world. Their position will be synced as well. Several physics blocks are in the scene, they can be kicked around by any player. Holding the mouse button will let the players spawn physics based projectiles. They can also move the blocks, or "kill" other players.

### Enemies

Set `res://example2/ShooterExample.tscn` as the main scene and launch the game.

Move around using the arrow keys, hold the mouse to shoot projectiles. Pressing enter, will spawn enemies on the board. Each enemy, will randomly choose an existing player and move towards them. On being touched by an enemy, the player will loose health. Shooting enemies removes them.

### 3D Example

Set `res://example3/3DLevel.tscn` as the main scene and launch the game.

Players will simply choose a random color for themselves and move to the right of the screen.

## Advanced Usage of Godot Synchronization

**Synching throughout the game**

There are two cases to be distinguished.

First, if a utility function such as `move_and_slide` changes the property of interest, use `rset_config()` with `RPC_MODE_REMOTE` (which then applies the change only on the remotes, not on your machine where it already happened) as shown below:

```gdscript
func _ready():
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTE)

func _process(delta):
	# we're only doing this on the client that owns this player
	if is_network_master():
		# changes our position on our client but isn't synchronized
		move_and_slide(Vector2(20 * delta, 0))
		# now we're synchronizing it with everyone else! (because of RPC_MODE_REMOTE)
		rset("position", position)
```

Second, if you change the property directly, use `MultiplayerAPI.RPC_MODE_REMOTESYNC` (which applies the change on both your machine and the remotes):

```gdscript
func _ready():
	rset_config("position", MultiplayerAPI.RPC_MODE_REMOTESYNC)

func _process(delta):
	# we're only doing this on the client that owns this player
	if is_network_master():
		# change our position and let us and everyone else apply it (because of RPC_MODE_REMOTESYNC)
		rset("position", position + Vector2(20 * delta, 0))
```

## Deploying the Game

To run the game after exporting it, you will need to specify whether each instance acts as a host or a client. While in the Godot editor, the game will always run on `localhost` to make debugging your game easier.

```
# Start the host
./MyGameExport
# Start the host on a specified port and IP address
./MyGameExport --port=8888 --ip=127.0.0.1
# Join as a client
./MyGameExport --client
./MyGameExport --client --port=8888 --ip=127.0.0.1
```

Alternatively, You also have the option to start the game as a dedicated host, meaning this instance will not spawn a player.

```
# Start the dedicated host
./MyGameExport --dedicated
# Join as a client
./MyGameExport --client
```
