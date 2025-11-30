extends Node

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
    set_optimized_controller_settings()
    
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
