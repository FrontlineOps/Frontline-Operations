/*
 * Function: FLO_fnc_createVirtualWaypointMarkers
 * Author: Frontline Operations Development Group
 * Description:
 * Creates map markers to visualize waypoints for a virtual group when in debug mode.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Waypoints <ARRAY> - Array of waypoint data
 * 2: Current Waypoint Index <NUMBER> - Index of the current active waypoint
 *
 * Return Value:
 * None
 *
 * Example:
 * ["vgroup_1", _waypoints, 0] call FLO_fnc_createVirtualWaypointMarkers;
 */

params [
    "_groupId",
    "_waypoints",
    ["_currentWaypointIndex", 0, [0]]
];

// Remove existing waypoint markers for this group
private _waypointMarkerPrefix = format["vwp_%1_", _groupId];
{
    if ((_x find _waypointMarkerPrefix) == 0) then {
        deleteMarker _x;
    };
} forEach allMapMarkers;

// Get group position for drawing path
private _groupData = (FLO_virtualGroups get "_groups") getOrDefault [_groupId, createHashMap];
if (_groupData isEqualTo createHashMap) exitWith {
    ["VIRTUALIZATION", 2, format["Cannot create waypoint markers - virtual group %1 not found", _groupId]] call FLO_fnc_log;
};

private _groupPos = _groupData getOrDefault ["position", [0,0,0]];
private _isActive = _groupData getOrDefault ["isActive", false];
private _groupColor = if (_isActive) then {"ColorRed"} else {"ColorBlue"};

// Create markers for each waypoint
{
    private _wpIndex = _forEachIndex;
    private _wpPos = _x select 0;
    private _wpType = _x select 1;
    
    // Create waypoint marker
    private _wpMarker = format["%1%2", _waypointMarkerPrefix, _wpIndex];
    createMarker [_wpMarker, _wpPos];
    
    // Format marker based on waypoint type
    _wpMarker setMarkerType "mil_dot";
    _wpMarker setMarkerSize [0.5, 0.5];
    
    // Current waypoint has different color
    if (_wpIndex == _currentWaypointIndex) then {
        _wpMarker setMarkerColor "ColorGreen";
    } else {
        _wpMarker setMarkerColor _groupColor;
    };
    
    // Add waypoint number as text
    _wpMarker setMarkerText format["%1 - WP%2", _groupId, _wpIndex];
    
    // Create a line from previous point to this waypoint
    private _lineStart = if (_wpIndex == 0) then {_groupPos} else {(_waypoints select (_wpIndex - 1)) select 0};
    private _lineName = format["%1line%2", _waypointMarkerPrefix, _wpIndex];
    
    // Create line marker
    createMarker [_lineName, [0,0,0]];
    _lineName setMarkerShape "RECTANGLE";
    _lineName setMarkerColor _groupColor;
    
    // Calculate line position and direction
    private _distance = _lineStart distance _wpPos;
    private _direction = [_lineStart, _wpPos] call BIS_fnc_dirTo;
    private _midPoint = [
        (_lineStart select 0) + ((_wpPos select 0) - (_lineStart select 0)) / 2,
        (_lineStart select 1) + ((_wpPos select 1) - (_lineStart select 1)) / 2
    ];
    
    // Set marker position, size, and direction
    _lineName setMarkerPos _midPoint;
    _lineName setMarkerSize [0.5, _distance / 2];
    _lineName setMarkerDir _direction;
    
    // Set line alpha
    _lineName setMarkerAlpha 0.7;
    
} forEach _waypoints; 