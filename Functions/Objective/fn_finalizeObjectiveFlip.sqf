/*
    Function: FLO_fnc_finalizeObjectiveFlip
    
    Description:
    Finalizes the flipping of an objective to a new controlling side.
    Creates or updates markers and respawn points based on the capturing side.
    Also sets up counter-attack triggers when BLUFOR captures an objective.
    
    Parameters:
    _trigger - The trigger that activated the finalization [Object]
    _objectiveType - Type of objective ("outpost" or "city") [String]
    _capturingSide - Side capturing the objective ("west" or "east") [String]
    
    Returns:
    Boolean - True if objective was finalized successfully
    
    Example:
    [_trigger, "outpost", "west"] call FLO_fnc_finalizeObjectiveFlip;
*/

params [
    ["_trigger", objNull, [objNull]],
    ["_objectiveType", "outpost", [""]],
    ["_capturingSide", "west", [""]]
];

if (isNull _trigger) exitWith {
    diag_log "[FLO][Outpost] Error: Invalid trigger for objective finalization";
    false
};

private _position = getPos _trigger;

// Check if objective is in cooldown period - prevent infinite loop of captures
if (!isNil "FLO_Objective_Cooldowns") then {
    private _objectiveKey = format ["%1_%2", _objectiveType, _position];
    private _lastCaptureTime = FLO_Objective_Cooldowns getOrDefault [_objectiveKey, 0];
    
    if (time - _lastCaptureTime < 300) exitWith {
        diag_log format ["[FLO][Outpost] Objective at %1 is in cooldown period, cannot be flipped yet", _position];
        false
    };
    
    // Update the last capture time
    FLO_Objective_Cooldowns set [_objectiveKey, time];
} else {
    // Initialize the cooldown tracking system if it doesn't exist
    FLO_Objective_Cooldowns = createHashMap;
    private _objectiveKey = format ["%1_%2", _objectiveType, _position];
    FLO_Objective_Cooldowns set [_objectiveKey, time];
};

// Get current markers that might need to be deleted/updated
private _currentMarkerType = if (_capturingSide == "west") then {
    // If BLUFOR is capturing, we need to find OPFOR markers
    switch (_objectiveType) do {
        case "outpost": { "o_support" };
        case "city": { "o_installation" };
        default { "o_support" };
    }
} else {
    // If OPFOR is capturing, we need to find BLUFOR markers
    "b_installation"
};

// Find current marker
private _allCurrentMarkers = allMapMarkers select {markerType _x == _currentMarkerType};
private _currentMarker = [_allCurrentMarkers, _position] call FLO_fnc_findNearestMarker;

// Delete old triggers in the area
private _allTriggers = allMissionObjects "EmptyDetector";
private _nearbyTriggers = _allTriggers select {getPos _x distance _position < 20};
{
    deleteVehicle _x;
} forEach _nearbyTriggers;

// Check if marker was found
if (_currentMarker != "") then {
    // Delete the current marker
    deleteMarker _currentMarker;
};

// Create new marker based on capturing side
private _newMarkerName = format ["%1_%2", _objectiveType, str _position];
private _newMarker = createMarker [_newMarkerName, _position];

if (_capturingSide == "west") then {
    // BLUFOR captured
    _newMarker setMarkerType "b_installation";
    _newMarker setMarkerColor "colorBLUFOR";
    _newMarker setMarkerSize [1.3, 1.3];
    
    // Create respawn position for BLUFOR
    private _respawnMarkerName = format ["respawn_west_%1", str _position];
    private _respawnMarker = createMarker [_respawnMarkerName, _position];
    _respawnMarker setMarkerType "respawn_inf";
    _respawnMarker setMarkerColor "colorBLUFOR";
    _respawnMarker setMarkerText "FOB";
    
    // Update objective count for mission completion if needed
    if (!isNil "FLO_oneMoreObjectiveCaptured" && !isNil "FLO_objectivesToCapture") then {
        FLO_oneMoreObjectiveCaptured = FLO_oneMoreObjectiveCaptured + 1;
        publicVariable "FLO_oneMoreObjectiveCaptured";
        
        // Check for mission completion
        if (FLO_oneMoreObjectiveCaptured >= FLO_objectivesToCapture) then {
            ["END1", true] call BIS_fnc_endMission;
        };
    };
    
    // Add to captured objectives list
    if (!isNil "FLO_capturedOutposts") then {
        FLO_capturedOutposts set [_newMarkerName, 1];
    };
    
    // Show notification
    ["TaskSucceeded", ["", format ["%1 Captured", _objectiveType]]] call BIS_fnc_showNotification;
    
    // Set up OPFOR counter-attack system
    // 1. Create the main capture trigger that detects when OPFOR enters the area
    private _captureTrigger = createTrigger ["EmptyDetector", _position, false];
    _captureTrigger setTriggerArea [120, 120, 0, false, 200];
    _captureTrigger setTriggerActivation ["EAST SEIZED", "PRESENT", true];
    _captureTrigger setTriggerTimeout [10, 10, 10, true];
    _captureTrigger setTriggerStatements [
        "this", 
        format [
            "[thisTrigger, '%1', 'east'] call FLO_fnc_flipObjective;",
            _objectiveType
        ],
        ""
    ];
    
    // 2. Create a separate delayed QRF trigger for counter-attacks
    [_position, _objectiveType] spawn {
        params ["_position", "_objectiveType"];
        
        // Wait before enabling QRF - this prevents immediate counter-attacks
        sleep 180;
        
        // Only proceed if the objective is still under BLUFOR control
        private _currentMarkers = allMapMarkers select {markerType _x == "b_installation"};
        private _objectiveStillBlufor = false;
        
        {
            if (getMarkerPos _x distance _position < 20 && markerColor _x == "colorBLUFOR") exitWith {
                _objectiveStillBlufor = true;
            };
        } forEach _currentMarkers;
        
        if (_objectiveStillBlufor) then {
            private _qrfTrigger = createTrigger ["EmptyDetector", _position, false];
            _qrfTrigger setTriggerArea [1000, 1000, 0, false, 200];
            _qrfTrigger setTriggerTimeout [30, 30, 30, true]; // Longer timeout
            _qrfTrigger setTriggerActivation ["WEST", "PRESENT", false];
            _qrfTrigger setTriggerStatements [
                "this && (({_x isKindOf 'Man'} count thisList > 0) or ({_x isKindOf 'LandVehicle'} count thisList > 0)) && {random 100 < 30}", // 30% chance to trigger
                format [
                    "
                    // Request QRF forces to attack the position
                    [thisTrigger, 500] call FLO_fnc_requestQRF;
                    [[EAST, 'HQ'], 'We are sending forces to attack %1'] remoteExec ['sideChat', 0];
                    ",
                    _objectiveType
                ],
                ""
            ];
        };
    };
    
} else {
    // OPFOR captured
    _newMarker setMarkerType (switch (_objectiveType) do {
        case "outpost": { "o_support" };
        case "city": { "o_installation" };
        default { "o_support" };
    });
    _newMarker setMarkerColor "colorOPFOR";
    _newMarker setMarkerSize [1.2, 1.2];
    
    // Notify players
    [playerSide, "HQ"] commandChat format ["All Forces Fall Back. We Lost the %1", toUpper _objectiveType];
    
    // Add trigger for BLUFOR to capture
    private _captureTrigger = createTrigger ["EmptyDetector", _position, false];
    _captureTrigger setTriggerArea [120, 120, 0, false, 200];
    _captureTrigger setTriggerActivation ["WEST SEIZED", "PRESENT", true];
    _captureTrigger setTriggerTimeout [10, 10, 10, true];
    _captureTrigger setTriggerStatements [
        "this", 
        format [
            "[thisTrigger, '%1', 'west'] call FLO_fnc_flipObjective;",
            _objectiveType
        ],
        ""
    ];
};

// Return success
true 