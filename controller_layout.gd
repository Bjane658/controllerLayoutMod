extends Node

var input_handler: Node
var inputHandlerPath = ""
var controllerSettingScenePath = ""

var settingsScreen
var settings_instance = null

enum EventType { BUTTON, MOTION}

var custom_action_bindings = {
    "move_up": {
        "type": EventType.MOTION,
        "axis": JOY_AXIS_LEFT_Y,
        "axis_value"  : -1.0
    },
    "move_down": {
        "type": EventType.MOTION,
        "axis": JOY_AXIS_LEFT_Y,
        "axis_value"  : 1.0
    },
    "move_left": {
        "type": EventType.MOTION,
        "axis": JOY_AXIS_LEFT_X,
        "axis_value"  : -1.0
    },
    "move_right": {
        "type": EventType.MOTION,
        "axis": JOY_AXIS_LEFT_X,
        "axis_value"  : 1.0
    },
    "inv_up": {
        "type": EventType.BUTTON,
        "button_index": JOY_BUTTON_DPAD_UP
    },
    "inv_down": {
        "type": EventType.BUTTON,
        "button_index": JOY_BUTTON_DPAD_DOWN
    },
    "inv_left": {
        "type": EventType.BUTTON,
        "button_index": JOY_BUTTON_DPAD_LEFT  
    },
    "inv_right": {
        "type": EventType.BUTTON,
        "button_index": JOY_BUTTON_DPAD_RIGHT  
    },
    "notebook_left": {
        "type": EventType.MOTION,
        "axis": JOY_AXIS_RIGHT_X,
        "axis_value"  : -1.0
    },
    "notebook_right": {
        "type": EventType.MOTION,
        "axis": JOY_AXIS_RIGHT_X,
        "axis_value"  : 1.0
    }
}

func _on_loaded():
    var dir_path = ProjectSettings.localize_path(ProjectSettings.get_setting("global/mod_directory"))
    print("on_loaded() mod base path " + dir_path)
    inputHandlerPath = ProjectSettings.localize_path(dir_path + "/controllerLayoutMod/input_handler.gd")
    controllerSettingScenePath = ProjectSettings.localize_path(dir_path + "/controllerLayoutMod/controller_setting.tscn")
    print("Mod dir: " + dir_path)
    print("controllerSettingsPath: " + controllerSettingScenePath)

    #set_optimized_controller_settings()


    settingsScreen = load(controllerSettingScenePath)

    
    # Wait for next frame, then add to scene tree
    call_deferred("_add_to_tree")

func _add_to_tree():
    name = "ControllerLayoutMod"
    Engine.get_main_loop().root.add_child(self)
    call_deferred("_inject_pause_menu_button")

func _inject_pause_menu_button():
    var pause_menu = get_tree().root.get_node_or_null("/root/PauseMenu")
    if !pause_menu:
        print("PauseMenu not found, retrying...")
        await get_tree().create_timer(0.5).timeout
        _inject_pause_menu_button()
        return

    var interactables = pause_menu.get_node_or_null("Interactables")
    if !interactables:
        print("Interactables container not found")
        return

    # Check if button already exists
    if interactables.get_node_or_null("ControllerSettingsButton"):
        print("Controller Settings button already exists")
        return

    # Get references to buttons for positioning and focus navigation
    var back_button = interactables.get_node_or_null("BackButton")
    var quit_button = interactables.get_node_or_null("QuitButton")
    
    var controller_button = back_button.duplicate()
    controller_button.name = "ControllerSettingsButton"
    controller_button.text = "Controller Settings"

    # Position between Back and Quit to Menu buttons
   # if back_button:
   #     controller_button.position = Vector2(back_button.position.x, 106.0)
   #     controller_button.size = back_button.size
   # else:
        # Fallback to absolute positioning if BackButton not found
   #     controller_button.position = Vector2(243.0, 106.0)
  #      controller_button.size = Vector2(89.0, 8.0)

    # Set up focus navigation - controller settings is between back and quit
   # if back_button and quit_button:
        # BackButton points down to ControllerSettings
   #     back_button.focus_neighbor_bottom = back_button.get_path_to(controller_button)

        # ControllerSettings points up to BackButton and down to QuitButton
   #     controller_button.focus_neighbor_top = controller_button.get_path_to(back_button)
   #     controller_button.focus_neighbor_bottom = controller_button.get_path_to(quit_button)

        # QuitButton points up to ControllerSettings
    #    quit_button.focus_neighbor_top = quit_button.get_path_to(controller_button)

    # Connect button signal
    controller_button.pressed.connect(_on_controller_settings_button_pressed)

    # Copy theme and style from other buttons
    #if quit_button and quit_button.theme:
    #    controller_button.theme = quit_button.theme
    #    var focus_style = quit_button.get_theme_stylebox("focus")
    #    if focus_style:
    #        controller_button.add_theme_stylebox_override("focus", focus_style)

    # Add button to the scene
    interactables.add_child(controller_button)
    print("Controller Settings button injected into pause menu between Back and Quit to Menu")

func _on_controller_settings_button_pressed():
    toggle_settings_screen()

func set_optimized_controller_settings():
    for action in custom_action_bindings:
        print("Set binding for: " + action)
        var event
        if custom_action_bindings[action]['type'] == EventType.BUTTON:
            event = InputEventJoypadButton.new()
            event.button_index = custom_action_bindings[action]['button_index']
    
        if custom_action_bindings[action]['type'] == EventType.MOTION:
            event = InputEventJoypadMotion.new()
            event.axis = custom_action_bindings[action]['axis']
            event.axis_value = custom_action_bindings[action]['axis_value']
        if custom_action_bindings[action]['type'] != EventType.MOTION && custom_action_bindings[action]['type'] != EventType.BUTTON:
            print("custom action has no valid event type (BUTTION, MOTION)")
            return
        remove_JoyEvents(action, InputMap.action_get_events(action))
        InputMap.action_add_event(action, event)


func set_optimized_controller_settings_manual():
    print("set optimized controller settings")
    remove_JoyEvents("inv_up", InputMap.action_get_events("inv_up"))
    var invUp = InputEventJoypadButton.new()
    invUp.button_index = JOY_BUTTON_DPAD_UP
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
