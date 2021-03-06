extends Node

const SETTINGS_PATH = "res://settings.ini"
var   config := ConfigFile.new()

var match_settings :=  {
	"map":"",     # Map scene path
	"matchtime":0,# In minutes
	"matchtype":0 # For the future, currently unused
}

func _ready():
	set_network_master(1)
	load_settings()
	Net.connect("on_peer_connect", self, "_on_peer_connect")

func _physics_process(_delta):
	if Input.is_action_just_pressed("reload_settings"):
		load_settings()

func load_settings():
	# If settings.ini doesn't exist, create one
	var directory = Directory.new()
	if !directory.file_exists(SETTINGS_PATH):
		print("Created new settings.ini")
		config.save(SETTINGS_PATH)
	
	# Load the settings.ini file
	var err = config.load(SETTINGS_PATH)
	if err != OK:
		push_warning("Error loading settings: %s" % err)
	
	# Map all the keys into actions
	if config.has_section("actions"):
		for action_name in config.get_section_keys("actions"):
			_add_action(action_name)
	
	# Set video settings
	Engine.target_fps = get_value("target_fps", 144)
	OS.vsync_enabled  = get_value("vsync", false)
	OS.window_fullscreen = get_value("fullscreen", true)

func _add_action(action:String):
	# Binds a button to an action 
	
	# Clear the action if there's already something
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
	
	var inputs = config.get_value("actions", action)
	
	# Handles an array of inputs e.g forwards = ["W", "UpArrow"]
	if   typeof(inputs) == TYPE_ARRAY:
		for key in inputs:
			_add_key_to_action(action, key)
	
	# Handles an input e.g forwards = "W"
	elif typeof(inputs) == TYPE_STRING:
		_add_key_to_action(action, inputs)

func _add_key_to_action(action:String, key:String):
	# Adds a key to a given action
	
	var action_button     := InputEventKey.new()
	action_button.scancode = OS.find_scancode_from_string(key) #read the scancode from the ini
	InputMap.action_add_event(action, action_button)
	print("Added action %s with button %s" % [action, key])

remote func set_matchsettings(dict:Dictionary):
	match_settings = dict
	Net.emit_signal("on_connection_ready")

# Signals #
func _on_peer_connect(id:int):
	if Net.is_host():
		rpc_id(id, "set_matchsettings", match_settings)

# Setters / Getters #
func set_resolution(resolution:Vector2):
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_IGNORE, resolution) # Loads the resolution

func get_value(key:String, default = null):
	# Returns a value with the key, if key doesn't exist returns the default value
	# and creates the key with the value and saves it 
	
	if config.has_section_key("settings", key):  # if the key did exist
		return config.get_value("settings", key, default)
	config.set_value("settings", key, default)
	print("Added new entry %s to settings.ini" % key)
	return default

func set_value(key:String, value):
	config.set_value("settings", key, value)

func _exit_tree():
	config.save(SETTINGS_PATH)
