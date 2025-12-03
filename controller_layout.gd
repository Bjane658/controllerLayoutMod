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
    var sound_volume = interactables.get_node_or_null("SoundVolume")

    var controller_button = back_button.duplicate()
    controller_button.name = "ControllerSettingsButton"
    controller_button.text = "Controller Settings"
    controller_button.clip_text = true

    # Position at the end, after Sound Volume
    if back_button:
        controller_button.position = Vector2(back_button.position.x, 252.0)
        controller_button.size = back_button.size
    else:
        # Fallback to absolute positioning if BackButton not found
        controller_button.position = Vector2(243.0, 252.0)
        controller_button.size = Vector2(89.0, 8.0)

    # Set up focus navigation - controller settings is at the end
    if sound_volume:
        # SoundVolume points down to ControllerSettings
        sound_volume.focus_neighbor_bottom = sound_volume.get_path_to(controller_button)

        # ControllerSettings points up to SoundVolume (last item, no bottom neighbor)
        controller_button.focus_neighbor_top = controller_button.get_path_to(sound_volume)

    # Connect button signal
    controller_button.pressed.connect(_on_controller_settings_button_pressed)

    # Add button to the scene
    interactables.add_child(controller_button)
    print("Controller Settings button injected into pause menu at the end")

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
    if event is InputEventJoypadButton and event.pressed:        
        if event.button_index == JOY_BUTTON_BACK:
            toggle_settings_screen()
            
    if event is InputEventKey and event.pressed:
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
