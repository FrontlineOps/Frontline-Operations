/*
 * Function: FLO_fnc_createVirtualGroupMarker
 * Author: Frontline Operations Development Group
 * Description:
 * Creates or updates a map marker for a virtual group (used for debugging).
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Group Data <HASHMAP> - HashMap containing group data
 *
 * Return Value:
 * Marker name <STRING>
 *
 * Example:
 * ["vgroup_1", _groupData] call FLO_fnc_createVirtualGroupMarker;
 */

params ["_groupId", "_groupData"];

private _marker = format["vgroup_%1", _groupId];

// Delete existing marker if it exists
if (getMarkerColor _marker != "") then {
    deleteMarker _marker;
};

// Extract data from the group
private _position = _groupData getOrDefault ["position", [0,0,0]];
private _groupType = _groupData getOrDefault ["groupType", "infantry"];
private _groupCfg = _groupData getOrDefault ["groupCfg", "unknown"];
private _objective = _groupData getOrDefault ["objective", ""];
private _state = _groupData getOrDefault ["state", "idle"];
private _isActive = _groupData getOrDefault ["isActive", false];

// Create marker
createMarker [_marker, _position];

// Set marker type based on group type
private _markerType = "o_inf";
switch (_groupType) do {
    case "infantry": { _markerType = "o_inf"; };
    case "motorized": { _markerType = "o_motor_inf"; };
    case "mechanized": { _markerType = "o_mech_inf"; };
    case "armor": { _markerType = "o_armor"; };
    case "air": { _markerType = "o_air"; };
    case "helicopter": { _markerType = "o_air"; };
    case "jet": { _markerType = "o_plane"; };
    case "artillery": { _markerType = "o_art"; };
    case "support": { _markerType = "o_support"; };
    default { _markerType = "o_unknown"; };
};

_marker setMarkerType _markerType;

// Set marker color based on state
private _markerColor = "ColorRed";
switch (_state) do {
    case "idle": { _markerColor = "ColorBlack"; };
    case "moving": { _markerColor = "ColorBlue"; };
    case "attacking": { _markerColor = "ColorRed"; };
    case "defending": { _markerColor = "ColorYellow"; };
    case "reinforcing": { _markerColor = "ColorGreen"; };
    default { _markerColor = "ColorBlack"; };
};

_marker setMarkerColor _markerColor;

// Set marker alpha (transparency) based on activation state
_marker setMarkerAlpha (if (_isActive) then {1} else {0.5});

// Set marker text to only include group ID
_marker setMarkerText _groupId;

// Return marker name
_marker 