/*
    Function: FLO_fnc_flipObjective
    
    Description:
    Handles the initial phase of flipping objectives (outposts or cities) between BLUFOR and OPFOR control.
    This function marks an objective as "in progress" (gray marker) and sets up a timeout to finalize the capture.
    
    Parameters:
    _trigger - The trigger that activated the flip [Object]
    _objectiveType - Type of objective ("outpost" or "city") [String]
    _capturingSide - Side capturing the objective ("west" or "east") [String]
    
    Returns:
    Boolean - True if objective flip was initiated successfully
    
    Example:
    [_trigger, "outpost", "west"] call FLO_fnc_flipObjective;
*/

params [
    ["_trigger", objNull, [objNull]],
    ["_objectiveType", "outpost", [""]],
    ["_capturingSide", "west", [""]]
];

if (isNull _trigger) exitWith {
    diag_log "[FLO][Outpost] Error: Invalid trigger for objective flipping";
    false
};

private _position = getPos _trigger;

// Check if objective is in cooldown period
if (!isNil "FLO_Objective_Cooldowns") then {
    private _objectiveKey = format ["%1_%2", _objectiveType, _position];
    private _lastCaptureTime = FLO_Objective_Cooldowns getOrDefault [_objectiveKey, 0];
    
    if (time - _lastCaptureTime < 300) exitWith {
        diag_log format ["[FLO][Outpost] Objective at %1 is in cooldown period, cannot be flipped yet", _position];
        false
    };
};

// Get relevant marker types based on objective type
private _markerType = switch (_objectiveType) do {
    case "outpost": { "o_support" };
    case "city": { "o_installation" };
    default { "o_support" };
};

private _bluforMarkerType = "b_installation";

// Handle different capturing sides
if (_capturingSide == "west") then {
    // BLUFOR is capturing
    
    // Find nearest matching marker
    private _allMarkers = allMapMarkers select {markerType _x == _markerType};
    private _objectiveMarker = [_allMarkers, _position] call FLO_fnc_findNearestMarker;
    
    if (_objectiveMarker == "") exitWith {
        diag_log format ["[FLO][Outpost] Error: Could not find marker for %1 at %2", _objectiveType, _position];
        false
    };
    
    // Change marker color to neutral (in progress)
    _objectiveMarker setMarkerColor "ColorGrey";
    
    // Send radio message
    private _attackingAtGrid = mapGridPosition getMarkerPos _objectiveMarker;
    ["STR_FLO_UPDATE_TITLE", ["STR_FLO_UPDATE_F",_attackingAtGrid], "success"] call FLO_fnc_sendNotification;
    
    // Set timeout to finalize capture if still in control
    [_trigger, _objectiveType, _capturingSide] spawn {
        params ["_trigger", "_objectiveType", "_capturingSide"];
        sleep 120;
        
        if (!isNull _trigger && triggerActivated _trigger) then {
            [_trigger, _objectiveType, _capturingSide] call FLO_fnc_finalizeObjectiveFlip;
        };
    };
    
} else {
    // OPFOR is capturing
    
    // Find nearest matching marker
    private _allMarkers = allMapMarkers select {markerType _x == _bluforMarkerType};
    private _objectiveMarker = [_allMarkers, _position] call FLO_fnc_findNearestMarker;
    
    if (_objectiveMarker == "") exitWith {
        diag_log format ["[FLO][Outpost] Error: Could not find marker for %1 at %2", _objectiveType, _position];
        false
    };
    
    // Change marker color to neutral (in progress)
    _objectiveMarker setMarkerColor "ColorGrey";
    
    // Send radio message
    private _attackingAtGrid = mapGridPosition getMarkerPos _objectiveMarker;
    ["STR_FLO_UPDATE_TITLE", ["STR_FLO_UPDATE_E",_attackingAtGrid], "warning"] call FLO_fnc_sendNotification;
    
    // Set timeout to finalize capture if still in control
    [_trigger, _objectiveType, _capturingSide] spawn {
        params ["_trigger", "_objectiveType", "_capturingSide"];
        sleep 120;
        
        if (!isNull _trigger && triggerActivated _trigger) then {
            [_trigger, _objectiveType, _capturingSide] call FLO_fnc_finalizeObjectiveFlip;
        };
    };
};

// Return success
true 