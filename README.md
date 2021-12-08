# Godot Multiplayer Template

Enables a peer-to-peer connection between instances of a Godot game.

## How to Play

`Is there a way to test the game without exporting it??`  
In order to start the game, first export it. Start one game as the host, then other clients can join.

The host has the id `1`, and can be set as network authority for all objects, other than the individual players.

E.g. starting my game on Linux

```
# Start the host
./mygame.x86_64
# Start the host on a specified port and IP address
./mygame.x86_64 --port=8888 --ip=127.0.0.1


# Join as a client
./mygame.x86_64 --client
./mygame.x86_64 --client --port=8888 --ip=127.0.0.1

```

## Getting Started

Your main scene should inherit the `game/game.gd`. This script checks the provided command line arguments, and takes care of registering as a new client.
You can configure the IP address, the port, the maximum number of players and the starting level in the inspector. By default the game will run on `localhost:8877` and allow for up to 200 players.

Each object, that should be synced among the clients, needs a `Sync` node, found in `sync/sync.tscn`.
By default only the position of the object will be synced. You can sync other properties by adding them to the `synced_properties` array.

When using physics objects, such as RigidBodies, use the `SyncableRigidBody`. It extends the default RigidBody by implementing the `integrate_forces` function, allowing for more stable experience.

`ChangeScene.tscn` allows you to change the currently loaded scene on all clients.

## Example

The example folder contains two small game demos.

### Pong

Once a player joined, they are assigned a random color, and can move around using the arrow keys. Pressing Enter allows players to spawn blocks in the world. Their position will be synced to

### Enemies

# Notes:

Two Projectile.gd, one never used. They other never despawns unless it hits something.

Isn't everything an example?
