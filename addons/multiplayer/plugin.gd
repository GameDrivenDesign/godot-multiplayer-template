tool
extends EditorPlugin

var button
var last_selected_option = 0

const OPTIONS = [
	"Debug Server",
	"Debug Client",
	"Debug Server (2 clients)"
]

func launch(id):
	if id == 0:
		get_editor_interface().play_main_scene()
		OS.execute(OS.get_executable_path(), ["--position", "1800,100", "--client"], false)
	elif id == 1:
		OS.execute(OS.get_executable_path(), ["--position", "1800,100"], false)
		OS.set_environment("USE_CLIENT", "true")
		get_editor_interface().play_main_scene()
		OS.set_environment("USE_CLIENT", "false")
	elif id == 2:
		get_editor_interface().play_main_scene()
		OS.execute(OS.get_executable_path(), ["--position", "100,100", "--client"], false)
		OS.execute(OS.get_executable_path(), ["--position", "800,100", "--client"], false)
	last_selected_option = id
	update_text()

func find_editor_run_button(node: Node):
	for n in node.get_children():
		if n.get_class() == 'EditorRunNative':
			return n
		else:
			var result = find_editor_run_button(n)
			if result != null:
				return result
	return null

func _input(event):
	if event is InputEventKey and event.shift and event.control and event.scancode == KEY_D and event.pressed:
		launch(last_selected_option)

func _enter_tree():
	if not Engine.editor_hint:
		return
	
	var base = get_editor_interface().get_base_control()
	var container = find_editor_run_button(base).get_parent().get_parent()
	
	button = MenuButton.new()
	update_text()
	container.add_child(button)
	for option in OPTIONS:
		button.get_popup().add_item(option)
	
	button.get_popup().connect("id_pressed", self, "launch")
	button.icon = base.get_icon("MainPlay", "EditorIcons")
	
	add_custom_type("Sync", "Node", preload("helper/Sync.gd"), base.get_icon("Reload", "EditorIcons"))
	add_custom_type("NetworkGame", "Node", preload("helper/Game.gd"), base.get_icon("MainPlay", "EditorIcons"))

func update_text():
	button.text = OPTIONS[last_selected_option] + " (Ctrl+Shift+D)"

func _exit_tree():
	disable_plugin()

func disable_plugin():
	if button:
		button.queue_free()
