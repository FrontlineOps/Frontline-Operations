/*
 * Function: FLO_fnc_virtualizationDebugUpdateMarker
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates or updates a debug marker for a single virtual group.
 *   Called by the debug PFH - lightweight and non-blocking.
 *   Tracks marker names in FLO_VirtDebug for O(1) cleanup.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_groupId, _groupData] call FLO_fnc_virtualizationDebugUpdateMarker;
 */

params ["_groupId", "_groupData"];

if (isNil "FLO_VirtDebug") exitWith {};
if !(FLO_VirtDebug get "enabled") exitWith {};

// Extract group data
private _position = _groupData getOrDefault ["position", [0,0,0]];
private _groupType = _groupData getOrDefault ["groupType", "infantry"];
private _state = _groupData getOrDefault ["state", "idle"];
private _isActive = _groupData getOrDefault ["isActive", false];
private _onMission = _groupData getOrDefault ["onMission", false];

// Skip invalid positions
if ((_position select 0) < 100 && (_position select 1) < 100) exitWith {};

// Marker name
private _markerName = format["vdbg_%1", _groupId];

// Check if marker exists
private _markerNames = FLO_VirtDebug get "markerNames";
private _existingMarker = _markerNames getOrDefault [_groupId, ""];

if (_existingMarker == "") then {
    // Create new marker
    createMarkerLocal [_markerName, _position];
    _markerNames set [_groupId, _markerName];
} else {
    // Update existing marker position
    _markerName setMarkerPosLocal _position;
};

// Set marker type based on group type
private _markerType = switch (_groupType) do {
    case "infantry": { "o_inf" };
    case "motorized": { "o_motor_inf" };
    case "mechanized": { "o_mech_inf" };
    case "armor": { "o_armor" };
    case "air";
    case "helicopter": { "o_air" };
    case "jet": { "o_plane" };
    case "artillery": { "o_art" };
    case "support": { "o_support" };
    case "civilian": { "mil_dot" };
    case "civilianVehicle": { "c_car" };
    default { "o_unknown" };
};
_markerName setMarkerTypeLocal _markerType;

// Set marker color based on state and mission status
private _markerColor = if (_onMission) then {
    "ColorOrange"  // On mission - orange
} else {
    switch (_state) do {
        case "idle": { "ColorBlack" };
        case "moving": { "ColorBlue" };
        case "attacking": { "ColorRed" };
        case "defending": { "ColorYellow" };
        case "reinforcing": { "ColorGreen" };
        case "reserved": { "ColorPink" };
        default {
            if (_groupType in ["civilian", "civilianVehicle"]) then {
                "ColorWhite"
            } else {
                "ColorBlack"
            };
        };
    };
};
_markerName setMarkerColorLocal _markerColor;

// Set alpha based on activation state
_markerName setMarkerAlphaLocal (if (_isActive) then { 1 } else { 0.5 });

// Set marker text - show key info
private _unitCount = _groupData getOrDefault ["unitCount", 0];
private _text = if (_isActive) then {
    format ["%1 [A]", _groupId]
} else {
    format ["%1 (%2)", _groupId, _unitCount]
};
_markerName setMarkerTextLocal _text;

// Update waypoint markers if group has waypoints
private _waypoints = _groupData getOrDefault ["waypoints", []];
private _currentWpIdx = _groupData getOrDefault ["currentWaypointIndex", 0];

private _wpMarkers = FLO_VirtDebug get "wpMarkerNames";
private _existingWpMarkers = _wpMarkers getOrDefault [_groupId, []];

// Clean old waypoint markers if count changed
if (count _existingWpMarkers != count _waypoints) then {
    { deleteMarkerLocal _x; } forEach _existingWpMarkers;
    _existingWpMarkers = [];
};

// Create/update waypoint markers
{
    _x params [["_wpPos", [0,0,0]], ["_wpType", "MOVE"]];
    
    if ((_wpPos select 0) > 100 || (_wpPos select 1) > 100) then {
        private _wpMarkerName = format["vdbg_wp_%1_%2", _groupId, _forEachIndex];
        
        if (_forEachIndex >= count _existingWpMarkers) then {
            // Create new waypoint marker
            createMarkerLocal [_wpMarkerName, _wpPos];
            _existingWpMarkers pushBack _wpMarkerName;
        } else {
            // Update position
            _wpMarkerName setMarkerPosLocal _wpPos;
        };
        
        _wpMarkerName setMarkerTypeLocal "waypoint";
        _wpMarkerName setMarkerSizeLocal [0.5, 0.5];
        
        // Highlight current waypoint
        if (_forEachIndex == _currentWpIdx) then {
            _wpMarkerName setMarkerColorLocal "ColorGreen";
        } else {
            _wpMarkerName setMarkerColorLocal "ColorGrey";
        };
        
        _wpMarkerName setMarkerTextLocal format["%1", _wpType];
    };
} forEach _waypoints;

// Store updated waypoint marker list
_wpMarkers set [_groupId, _existingWpMarkers];

