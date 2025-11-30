extends Node

var input_handler: Node
var inputHandlerPath = ""
var controllerSettingScenePath = ""

var settingsScreen
var settings_instance = null

func _on_loaded():
    var dir_path = ProjectSettings.get_setting("global/mod_directory")
    #var dir_path = OS.get_executable_path().get_base_dir() + 
    #var dir_path = ProjectSettings.localize_path(ProjectSettings.get_setting("global/mod_directory"))
    #var dir_path = ProjectSettings.get_setting("global/mod_directory")
    inputHandlerPath = dir_path + "/controllerLayoutMod/input_handler.gd"
    controllerSettingScenePath = dir_path + "/controllerLayoutMod/controller_setting.tscn"
    print("Mod dir: " + dir_path)
    #print("input_handler dir: " + inputHandlerPath)


    print("Loaded controller layout mod, juhu")
   # print("Connected joypads: ", Input.get_connected_joypads())
    #print("Set invUp - events: ", InputMap.action_get_events("inv_up"))
    #var invUp = InputEventJoypadButton.new()
    #invUp.button_index = JOY_BUTTON_DPAD_UP
    #invUp.device = -1
    #InputMap.action_add_event("inv_up", invUp)
    #print("Set invUp")
    #print("Set invUp - events: ", InputMap.action_get_events("inv_up"))
    #var invDown = InputEventJoypadButton.new()
    #invDown.button_index = JOY_BUTTON_DPAD_DOWN
    #InputMap.action_add_event("inv_down", invDown)
    #print("Set invDown")


    settingsScreen = load(controllerSettingScenePath)

    
    # Wait for next frame, then add to scene tree
    call_deferred("_add_to_tree")

func _add_to_tree():
    Engine.get_main_loop().root.add_child(self)

    
func _input(event):
    print("_input triddggered within mod script")
    if event is InputEventJoypadButton and event.pressed:
        print("Joypad button pressed: ", event.button_index)
        
        if event.button_index == JOY_BUTTON_BACK:
            print("- button pressed!")
            toggle_settings_screen()
            
    if event is InputEventKey and event.pressed:
        print("InputEvent detected!")
        print("Keycode: ", event.physical_keycode)
        if event.physical_keycode == 79:
            toggle_settings_screen()
        

func toggle_settings_screen():
    if settings_instance == null:
        # Open the settings screen
        settings_instance = settingsScreen.instantiate()
        Engine.get_main_loop().root.add_child(settings_instance)
        print("Settings screen opened")
    else:
        # Close the settings screen
        settings_instance.queue_free()
        settings_instance = null
        print("Settings screen closed")
