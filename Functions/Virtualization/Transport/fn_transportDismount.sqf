/*
 * Function: FLO_fnc_transportDismount
 * Author: Frontline Operations Development Group
 * Description:
 *   Check and handle dismount for a transport group at waypoint.
 *   Called from fn_virtualizationAdvanceWaypoint.
 *
 * Arguments:
 *   0: Transport Group ID <STRING>
 *
 * Return Value:
 *   Dismount occurred <BOOLEAN>
 *
 * Example:
 *   [_groupId] call FLO_fnc_transportDismount;
 */

params [["_transportGroupId", "", [""]]];

if (_transportGroupId == "") exitWith { false };

if (isNil "FLO_virtualGroups") exitWith { false };

private _groups = FLO_virtualGroups get "_groups";
private _transData = _groups getOrDefault [_transportGroupId, nil];

if (isNil "_transData") exitWith { false };

// Check if this is a transport
private _isTransport = _transData getOrDefault ["isTransport", false];
if (!_isTransport) exitWith { false };

// Check dismount waypoint
private _dismountIdx = _transData getOrDefault ["dismountAtWaypoint", -1];
if (_dismountIdx < 0) exitWith { false };

private _currentIdx = _transData getOrDefault ["currentWaypointIndex", 0];
if (_currentIdx < _dismountIdx) exitWith { false };

// Get attached groups before detaching
private _attachedIds = +(_transData getOrDefault ["attachedGroups", []]);

// Detach all passengers
private _detached = [_transportGroupId] call FLO_fnc_transportDetachAll;

// Clear dismount config
_transData set ["dismountAtWaypoint", -1];
_transData set ["currentOrder", ""];

// Release transport back to pool
if (!isNil "FLO_TransportPool") then {
    [_transportGroupId] call FLO_fnc_transportPoolRelease;
};

// Apply post-dismount waypoints to infantry
{
    private _infData = _groups getOrDefault [_x, nil];
    if (!isNil "_infData") then {
        private _postWp = _infData getOrDefault ["postDismountWaypoint", []];
        if (count _postWp > 0) then {
            _postWp params ["_targetPos", "_orderType"];
            
            // Set infantry waypoints after dismount
            private _waypoints = [
                [_targetPos, "MOVE", "COMBAT", "NORMAL", "WEDGE", "RED", 50]
            ];
            [_x, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
            _infData set ["postDismountWaypoint", []];
            
            ["TRANSPORT", 3, format["Set post-dismount %1 waypoint for %2", _orderType, _x]] call FLO_fnc_log;
        };
    };
} forEach _attachedIds;

["TRANSPORT", 3, format["Transport %1 dismounted %2 groups at waypoint %3", 
    _transportGroupId, _detached, _currentIdx]] call FLO_fnc_log;

true
