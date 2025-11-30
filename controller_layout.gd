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
    set_optimized_controller_settings()


    settingsScreen = load(controllerSettingScenePath)

    
    # Wait for next frame, then add to scene tree
    call_deferred("_add_to_tree")

func _add_to_tree():
    Engine.get_main_loop().root.add_child(self)

func set_optimized_controller_settings():
    print("set optimized controller settings")
    remove_JoyEvents("inv_up", InputMap.action_get_events("inv_up"))
    var invUp = InputEventJoypadButton.new()
    invUp.button_index = JOY_BUTTON_DPAD_UP
    invUp.device = -1
    InputMap.action_add_event("inv_up", invUp)
    print("Set invUp")
    remove_JoyEvents("inv_down", InputMap.action_get_events("inv_down"))
    var invDown = InputEventJoypadButton.new()
    invDown.button_index = JOY_BUTTON_DPAD_DOWN
    InputMap.action_add_event("inv_down", invDown)
    print("Set invDown")
    remove_JoyEvents("inv_left", InputMap.action_get_events("inv_left"))
    var invLeft = InputEventJoypadButton.new()
    invLeft.button_index = JOY_BUTTON_DPAD_LEFT
    InputMap.action_add_event("inv_left", invLeft)
    print("Set invLeft")
    remove_JoyEvents("inv_right", InputMap.action_get_events("inv_right"))
    var invRight = InputEventJoypadButton.new()
    invRight.button_index = JOY_BUTTON_DPAD_RIGHT
    InputMap.action_add_event("inv_right", invRight)
    print("Set invRight")
    remove_JoyEvents("move_up", InputMap.action_get_events("move_up"))
    var movUp = InputEventJoypadMotion.new()
    movUp.axis = JOY_AXIS_LEFT_Y
    movUp.axis_value = -1.0
    InputMap.action_add_event("move_up", movUp)
    print("Set movUp")
    remove_JoyEvents("move_down", InputMap.action_get_events("move_down"))
    var movDown = InputEventJoypadMotion.new()
    movDown.axis = JOY_AXIS_LEFT_Y
    movDown.axis_value = 1.0
    InputMap.action_add_event("move_down", movDown)
    print("Set movDown")
    remove_JoyEvents("move_left", InputMap.action_get_events("move_left"))
    var movLeft = InputEventJoypadMotion.new()
    movLeft.axis = JOY_AXIS_LEFT_X
    movLeft.axis_value = -1.0
    InputMap.action_add_event("move_left", movLeft)
    print("Set movLeft")
    remove_JoyEvents("move_right", InputMap.action_get_events("move_right"))
    var movRight = InputEventJoypadMotion.new()
    movRight.axis = JOY_AXIS_LEFT_X
    movRight.axis_value = 1.0
    InputMap.action_add_event("move_right", movRight)
    print("Set movRight")
    remove_JoyEvents("notebook_left", InputMap.action_get_events("notebook_left"))
    var notebookLeft = InputEventJoypadMotion.new()
    notebookLeft.axis = JOY_AXIS_RIGHT_X
    notebookLeft.axis_value = -1.0
    InputMap.action_add_event("notebook_left", notebookLeft)
    print("Set notebook left")
    remove_JoyEvents("notebook_right", InputMap.action_get_events("notebook_right"))
    var notebookRight = InputEventJoypadMotion.new()
    notebookRight.axis = JOY_AXIS_RIGHT_X
    notebookRight.axis_value = 1.0
    InputMap.action_add_event("notebook_right", notebookRight)
    print("Set notebook right")

func remove_JoyEvents(action: String, events: Array):
    var filteredEvents = get_JoyEvents(events)
    for joyEvent in filteredEvents:
        InputMap.action_erase_event(action, joyEvent)

func get_JoyEvents(events: Array) -> Array:
    var filteredEvents = []
    for event in events:
        if event is InputEventJoypadButton:
            filteredEvents.append(event)
        if event is InputEventJoypadMotion:
            filteredEvents.append(event)
    return filteredEvents

func _input(event):
    if event is InputEventJoypadMotion:
        print("Motion: axis: " + str(event.axis) + " value: " + str(event.axis_value))
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
