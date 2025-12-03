extends CanvasLayer

@onready var bindings_container = $Panel/VBoxContainer/ScrollContainer/MarginContainer/BindingsContainer
@onready var scroll_container = $Panel/VBoxContainer/ScrollContainer
var binding_row_scene
var setting_new_binding = false
var setting_new_binding_for
var setting_new_binding_row

# Define your actions and their display names
var actions = {
    "interact": "Interact",
    "cancel": "Cancel",
    "wait": "Wait",
    "move": "Move",
    "inv_up": "Inventory Up",
    "inv_down": "Inventory Down",
    "inv_left": "Inventory Left",
    "inv_right": "Inventory Right",
    "drop_item": "Drop Item",
    "notebook_left": "Notebook Left",
    "notebook_right": "Notebook Right",
    "swap_map": "Swap Map/Notebook"
}

var move_actions = {
    "move_up": "Move Up",
    "move_down": "Move Down",
    "move_left": "Move Left",
    "move_right": "Move Right",
}

var scroll_speed = 300.0

func _ready():
    get_tree().paused = true
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED

    var dir_path = ProjectSettings.localize_path(ProjectSettings.get_setting("global/mod_directory"))
    #var dir_path = ProjectSettings.get_setting("global/mod_directory")
    var binding_row_scene_path = ProjectSettings.localize_path(dir_path + "/controllerLayoutMod/binding_row.tscn")
    print("controller_settings.gd _ready() binding_row_scene_path " + binding_row_scene_path)
    binding_row_scene = load(binding_row_scene_path)
    populate_bindings()
    
    # Connect buttons
    $Panel/VBoxContainer/HBoxContainer/SaveButton.pressed.connect(_on_save_pressed)
    $Panel/VBoxContainer/HBoxContainer/CancelButton.pressed.connect(_on_cancel_pressed)

func _process(delta):
    # Get right stick vertical axis
    var right_stick_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
    
    # Apply scrolling if stick is moved beyond deadzone
    if abs(right_stick_y) > 0.2:  # Deadzone
        var scroll_amount = right_stick_y * scroll_speed * delta
        scroll_container.scroll_vertical += int(scroll_amount)


func populate_bindings():
    # Clear existing rows
    for child in bindings_container.get_children():
        child.queue_free()
    var isFirstRow = true
    # Create a row for each action
    for action in actions:
        var row = binding_row_scene.instantiate()
        bindings_container.add_child(row)
        
        
        # Set action name
        row.get_node("ActionLabel").text = actions[action]
        
        # Get current binding
        var current_binding = get_action_binding(action)
        row.get_node("BindingLabel").text = current_binding
        
        # Connect rebind button
        row.get_node("RebindButton").pressed.connect(_on_rebind_pressed.bind(action, row))
        if isFirstRow:
            row.get_node("RebindButton").grab_focus()
        isFirstRow = false

func get_action_binding(action: String) -> String:
    if action == "move":
        action = "move_up"
    var events = InputMap.action_get_events(action)
    if events.size() > 0:
        for event in events:
            if event is InputEventJoypadButton:
                return get_button_name(event.button_index)
            if event is InputEventJoypadMotion:
                return get_motion_name(event.axis, event.axis_value)
    return "Not bound"

func getJoyName(event):
    if event is InputEventJoypadButton:
         return get_button_name(event.button_index)
    if event is InputEventJoypadMotion:
         return get_motion_name(event.axis, event.axis_value)
    return "n/a"

func get_motion_name(axis_index: int, axis_value: float) -> String:
    if axis_index == 0 or axis_index == 1:
        return "L-Stick"
    if axis_index == 2 or axis_index == 3:
        return "R-Stick"
    if axis_index == 4:
        return "Left Trigger"
    if axis_index == 5:
        return "Right Trigger"
    return "Motion Axis: " + str(axis_index) + " Axis Value: " + str(axis_value)
            
    
func get_button_name(button_index: int) -> String:
    match button_index:
        JOY_BUTTON_A: return "A Button"
        JOY_BUTTON_B: return "B Button"
        JOY_BUTTON_X: return "X Button"
        JOY_BUTTON_Y: return "Y Button"
        JOY_BUTTON_DPAD_UP: return "D-Pad Up"
        JOY_BUTTON_DPAD_DOWN: return "D-Pad Down"
        JOY_BUTTON_DPAD_LEFT: return "D-Pad Left"
        JOY_BUTTON_DPAD_RIGHT: return "D-Pad Right"
        JOY_BUTTON_START: return "Start"
        JOY_BUTTON_BACK: return "Back/Select"
        JOY_BUTTON_LEFT_SHOULDER: return "Left Bumper"
        JOY_BUTTON_RIGHT_SHOULDER: return "Right Bumper"
        _: return "Button " + str(button_index)

func _on_rebind_pressed(action: String, row):
    print("Rebinding action: ", action)
    row.get_node("BindingLabel").text = "Press a button..."
    setting_new_binding = true
    setting_new_binding_for = action
    setting_new_binding_row = row
    print("setting_new_binding_for: " + action)
    

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

func extrapolateAxisValue(axis_value):
    if axis_value < 0:
        return -1.0
    return 1.0
    
func updateAxisValue(event: InputEventJoypadMotion, axis: int, axis_value: float):
    event.set_axis(axis)
    event.set_axis_value(axis_value)
    return event

func whichStick(event: InputEventJoypadMotion):
    if event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y:
        return "left"
    return "right"
    
func getAxisFromStick(stick, axis: String):
    if stick == "left":
        if axis == "x":
            return JOY_AXIS_LEFT_X
        return JOY_AXIS_LEFT_Y
    if axis == "x":
        return JOY_AXIS_RIGHT_X
    return JOY_AXIS_RIGHT_Y

func addMoveActionEvent(event: InputEventJoypadMotion, moveAction: String):
    print("adding move action event: " + str(event.axis) + " " + str(event.axis_value) + " " + moveAction)
    var stick = whichStick(event)
    match moveAction:
        "move_up": InputMap.action_add_event(moveAction, updateAxisValue(event,getAxisFromStick(stick, "y"), -1.0))
        "move_down": InputMap.action_add_event(moveAction, updateAxisValue(event,getAxisFromStick(stick, "x"), 1.0))
        "move_left": InputMap.action_add_event(moveAction, updateAxisValue(event,getAxisFromStick(stick, "y"), -1.0))
        "move_right": InputMap.action_add_event(moveAction, updateAxisValue(event,getAxisFromStick(stick, "x"), 1.0))
            
func bindMoveActions(event: InputEventJoypadMotion):
    for moveAction in move_actions:
        var moveActionEvents = InputMap.action_get_events(moveAction)
        remove_JoyEvents(moveAction, moveActionEvents)
        addMoveActionEvent(event, moveAction)
        var newMoveActionEvents = InputMap.action_get_events(moveAction)
        for newMoveActionEvent in newMoveActionEvents:
            if newMoveActionEvent is InputEventJoypadMotion:
                print("New move action event for " + moveAction + "axis: " + str(newMoveActionEvent.axis) + " value: " + str(newMoveActionEvent.axis_value))
        
    
func _input(event):
    if setting_new_binding and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
        if setting_new_binding_for == "move":
            print("rebind move")
            bindMoveActions(event)
        else:
            print("rebind other than move")
            var actionEvents = InputMap.action_get_events(setting_new_binding_for)
            remove_JoyEvents(setting_new_binding_for, actionEvents)
            if event is InputEventJoypadMotion:
                event.axis_value = extrapolateAxisValue(event.axis_value)
            InputMap.action_add_event(setting_new_binding_for, event)
            print("Sett new input for " + setting_new_binding_for)
            setting_new_binding_row.get_node("BindingLabel").text = getJoyName(event)
        setting_new_binding = false
        setting_new_binding_for = ""
        setting_new_binding_row = null

func _on_save_pressed():
    print("Settings saved")
    var pause_menu = get_tree().root.get_node_or_null("/root/PauseMenu")
    if !pause_menu or !pause_menu.visible:
        get_tree().paused = false
    queue_free()

func _on_cancel_pressed():
    print("Settings cancelled")
    var pause_menu = get_tree().root.get_node_or_null("/root/PauseMenu")
    if !pause_menu or !pause_menu.visible:
        get_tree().paused = false
    queue_free()
