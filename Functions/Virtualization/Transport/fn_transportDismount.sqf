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

private _transData = [_transportGroupId] call FLO_fnc_transportGetTrackedGroup;

// Check if this is a transport
private _isTransport = [_transData] call FLO_fnc_virtualizationIsTransportCarrier;
if (!_isTransport) exitWith { false };

// Check dismount waypoint
private _dismountIdx = _transData get "dismountAtWaypoint";
if (_dismountIdx < 0) exitWith { false };

private _currentIdx = _transData get "currentWaypointIndex";
if (_currentIdx < _dismountIdx) exitWith { false };

// Get attached groups before detaching
private _attachedIds = +([_transData] call FLO_fnc_virtualizationGetTransportPassengers);

// Detach all passengers
private _detached = [_transportGroupId] call FLO_fnc_transportDetachAll;

// Clear dismount config
_transData set ["dismountAtWaypoint", -1];
[_transData] call FLO_fnc_virtualizationClearExecutionState;
[_transData] call FLO_fnc_virtualizationClearMissionLock;

[_transportGroupId] call FLO_fnc_transportPoolRelease;

// Apply post-dismount waypoints to infantry
{
    private _infData = [_x] call FLO_fnc_transportGetTrackedGroup;
    private _postWp = _infData get "postDismountWaypoint";
    if (count _postWp > 0) then {
        _postWp params ["_targetPos", "_orderType"];

        private _waypoints = [
            [_targetPos, "MOVE", "COMBAT", "NORMAL", "WEDGE", "RED", 50]
        ];
        [_x, _waypoints, false, true, "TRANSPORT_DISMOUNT"] call FLO_fnc_updateVirtualGroupWaypoints;
        _infData set ["postDismountWaypoint", []];

        ["TRANSPORT", 3, format["Set post-dismount %1 waypoint for %2", _orderType, _x]] call FLO_fnc_log;
    };
} forEach _attachedIds;

["TRANSPORT", 3, format["Transport %1 dismounted %2 groups at waypoint %3", 
    _transportGroupId, _detached, _currentIdx]] call FLO_fnc_log;

true
