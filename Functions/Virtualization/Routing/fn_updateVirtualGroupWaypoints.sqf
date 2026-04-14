/*
 * Function: FLO_fnc_updateVirtualGroupWaypoints
 * Author: Frontline Operations Development Group
 * Description:
 * Updates the waypoints for a virtual group. If the group is active, updates its real waypoints.
 * If inactive, stores the waypoints for virtual movement processing.
 * Now supports pathfinding integration for road-based movement.
 *
 * Arguments:
 * 0: Group ID <STRING> - Unique identifier for the virtual group
 * 1: Waypoints <ARRAY> - Array of waypoint data in format:
 *   Each waypoint is an array: [position, type, behavior, speed, formation, combat mode, completion radius]
 * 2: (Optional) Use Road Pathfinding <BOOLEAN> - Whether to use road pathfinding (Default: false)
 * 3: (Optional) Allow Trails <BOOLEAN> - Whether to allow trails for pathfinding (Default: false)
 * 4: (Optional) Request Source <STRING> - Source tag for pathfinding telemetry (Default: "")
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * ["vgroup_1", [[getMarkerPos "marker_1", "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", 20]]] call FLO_fnc_updateVirtualGroupWaypoints;
 * ["vgroup_1", [[getMarkerPos "marker_1", "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", 20]], true] call FLO_fnc_updateVirtualGroupWaypoints;
 */

params [
    "_groupId",
    "_waypoints",
    ["_usePathfinding", false, [true]],
    ["_allowTrails", true, [true]],
    ["_requestSource", "", [""]]
];

// Get the group data
private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
// Get the current position of the group
private _currentPos = _groupData get "position";

private _groupType = _groupData get "groupType";
private _isNavalGroup = _groupType in ["boat", "naval", "submarine"];
private _sanitizedWaypoints = [_groupType, _waypoints] call FLO_fnc_virtualizationSanitizeWaypoints;

private _sourceTag = if (_requestSource != "") then { _requestSource } else { "VG_GENERIC" };
private _effectiveUsePathfinding = _usePathfinding;

if (count _sanitizedWaypoints == 0 || !_effectiveUsePathfinding) then {
    [_groupId, _groupData, _sanitizedWaypoints, _sourceTag] call FLO_fnc_virtualizationApplyDirectWaypointUpdate;
} else {
    [_groupId, _groupData, _currentPos, _sanitizedWaypoints, _allowTrails, _sourceTag, _isNavalGroup, _groupType] call FLO_fnc_virtualizationRequestPathRouteUpdate;
};

// Log the update
["VIRTUALIZATION", 3, format["Updated waypoints for virtual group %1", _groupId]] call FLO_fnc_log;

// Return success
true
