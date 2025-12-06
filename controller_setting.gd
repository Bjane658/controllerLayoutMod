extends Control

@onready var bindings_container = $Panel/VBoxContainer/ScrollContainer/MarginContainer/BindingsContainer
@onready var scroll_container = $Panel/VBoxContainer/ScrollContainer
var binding_row_scene
var setting_new_binding = false
var setting_new_binding_for
var setting_new_binding_row

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

var old_action_events = {}

enum EventType { BUTTON, MOTION}
var sample = {
    "move_right": {
        "type": EventType.MOTION,
        "axis": JOY_AXIS_LEFT_X,
        "axis_value"  : 1.0
    },
    "inv_up": {
        "type": EventType.BUTTON,
        "button_index": JOY_BUTTON_DPAD_UP
    },
}

var move_bindings_template = { 
    "move_up": {
        "type": EventType.MOTION,
        "axis": "y",
        "axis_value"  : -1.0
    },
    "move_down": {
        "type": EventType.MOTION,
        "axis": "y",
        "axis_value"  : 1.0
    },
    "move_left": {
        "type": EventType.MOTION,
        "axis": "x",
        "axis_value"  : -1.0
    },
    "move_right": {
        "type": EventType.MOTION,
        "axis": "x",
        "axis_value"  : 1.0
    },  
}

var custom_action_bindings = {}

var saved_cancel_action_events

var scroll_speed = 300.0

func set_custom_action_bindings():
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

func print_custom_action_bindings():
    print(JSON.stringify(custom_action_bindings, "  "))

func fill_custom_move_bindings(axis):
    var stick = whichStickFromAxis(axis)
    for move_action in move_bindings_template:
        var newBinding = move_bindings_template[move_action]
        newBinding["axis"] = getAxisFromStick(stick, newBinding["axis"])
        custom_action_bindings.set(move_action, newBinding)
        
func getEventType(event):
    if event is InputEventJoypadMotion:
        return EventType.MOTION
    return EventType.BUTTON

func fill_custom_binding(action, event):
    if action == "move":
        fill_custom_move_bindings(event.axis)
        return
    var type = getEventType(event)
    var newBinding
    if event is InputEventJoypadMotion:
        newBinding = {"type": type, "axis": event.axis, "axis_value" : extrapolateAxisValue(event.axis_value)}
    if event is InputEventJoypadButton:
        newBinding = {"type": type, "button_index": event.button_index}
    custom_action_bindings.set(action, newBinding)

func get_action_joy_event(action: String):
    if action == "move":
        action = "move_up"
    var events = InputMap.action_get_events(action)
    var filtered = get_JoyEvents(events)
    if filtered.size() > 0:
        return filtered.get(0)
    return null

func _safe_current_action_events():
    for action in actions:
        var action_event = get_action_joy_event(action)
        print("_set_old_action_events: set key: " + action + " value: " + action_event.as_text())
        old_action_events.set(action, action_event)
        

func _ready():
    get_tree().paused = true
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    _safe_current_action_events()
    saved_cancel_action_events = InputMap.action_get_events("cancel")
    InputMap.action_erase_events("cancel")

    var dir_path = ProjectSettings.localize_path(ProjectSettings.get_setting("global/mod_directory"))
    var binding_row_scene_path = ProjectSettings.localize_path(dir_path + "/controllerLayoutMod/binding_row.tscn")
    binding_row_scene = load(binding_row_scene_path)
    populate_bindings()
    
    # Connect buttons
    $Panel/VBoxContainer/HBoxContainer/SaveButton.pressed.connect(_on_save_pressed)
    $Panel/VBoxContainer/HBoxContainer/CancelButton.pressed.connect(_on_cancel_pressed)

func _process(delta):
    var right_stick_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
    
    if abs(right_stick_y) > 0.2:
        var scroll_amount = right_stick_y * scroll_speed * delta
        scroll_container.scroll_vertical += int(scroll_amount)


func populate_bindings():
    for child in bindings_container.get_children():
        child.queue_free()
    var isFirstRow = true
    for action in actions:
        var row = binding_row_scene.instantiate()
        bindings_container.add_child(row)
        
        row.get_node("ActionLabel").text = actions[action]
        
        var current_binding = old_action_events.get(action)
        row.get_node("BindingLabel").text = get_action_event_name(current_binding)
        
        row.get_node("RebindButton").pressed.connect(_on_rebind_pressed.bind(action, row))
        if isFirstRow:
            row.get_node("RebindButton").grab_focus()
        isFirstRow = false

func get_action_event_name(event):
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

func whichStickFromAxis(axis):
    if axis == JOY_AXIS_LEFT_X or axis == JOY_AXIS_LEFT_Y:
        return "left"
    return "right"
    
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
  

func apply_changes():
    set_custom_action_bindings()          
  
func _input(event):
    if !setting_new_binding and event is InputEventJoypadButton and event.is_pressed():
        if event.button_index == JOY_BUTTON_BACK:
            _on_cancel_pressed()
    if setting_new_binding and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
        if event is InputEventJoypadMotion and abs(event.axis_value) < 0.5:
            return
        print("Rebind: " + event.as_text())
        setting_new_binding_row.get_node("BindingLabel").text = getJoyName(event)
        fill_custom_binding(setting_new_binding_for, event)
        print_custom_action_bindings()
        setting_new_binding = false
        setting_new_binding_for = ""
        setting_new_binding_row = null

func _on_save_pressed():
    apply_changes()
    print("Settings saved")
    _exit_scene()
    

func _on_cancel_pressed():
    print("Settings cancelled")
    _exit_scene()
    
func _exit_scene():
    _reset_cancel_action_events()
    get_tree().paused = false
    queue_free()
    
func _reset_cancel_action_events():
    for event in saved_cancel_action_events:
        InputMap.action_add_event("cancel", event)
