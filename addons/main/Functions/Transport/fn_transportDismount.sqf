/*
 * Function: FLO_fnc_transportDismount
 * Author: Frontline Operations Development Group
 * Description:
 *   Check and handle dismount for a transport group at waypoint.
 *   Called from both virtual waypoint advancement and active carrier sync.
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

params [
    ["_transportGroupId", "", [""]],
    ["_forceNow", false, [false]]
];

if (_transportGroupId == "") exitWith { false };

private _transData = [_transportGroupId] call FLO_fnc_transportGetTrackedGroup;

// Check if this is a transport
private _isTransport = [_transData] call FLO_fnc_virtualizationIsTransportCarrier;
if (!_isTransport) exitWith { false };

// Check dismount waypoint
private _dismountIdx = _transData get "dismountAtWaypoint";
if (_dismountIdx < 0) exitWith { false };

private _currentIdx = _transData get "currentWaypointIndex";
if (!_forceNow && {_currentIdx < _dismountIdx}) exitWith { false };

// Get attached groups before detaching
private _attachedIds = +([_transData] call FLO_fnc_virtualizationGetTransportPassengers);
private _insertMode = _transData get "transportInsertMode";
private _insertPos = _transData get "transportInsertPos";
private _realGroup = _transData get "realGroup";

// Detach all passengers
private _detached = if (_insertMode == "AIR_DROP" && {!isNull _realGroup}) then {
    private _transportVehicles = ([_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select { !isNull _x && {alive _x} };
    private _dropPos = if (_forceNow || {count _insertPos < 2}) then {
        private _leader = leader _realGroup;
        if (isNull _leader || {!alive _leader}) then {
            _transData get "position"
        } else {
            getPosATL _leader
        }
    } else {
        _insertPos
    };
    private _dropCount = 0;

    {
        if ([_x, _dropPos, _transportVehicles] call FLO_fnc_transportParadropActivePassengerGroup) then {
            _dropCount = _dropCount + 1;
        };
    } forEach _attachedIds;

    _dropCount
} else {
    [_transportGroupId] call FLO_fnc_transportDetachAll
};

// Clear dismount config
[_transportGroupId] call FLO_fnc_transportClearInsertState;

[_transportGroupId] call FLO_fnc_transportPoolRelease;

// Apply post-dismount waypoints to infantry
{
    [_x, "TRANSPORT_DISMOUNT"] call FLO_fnc_transportApplyPostDismountWaypoint;
} forEach _attachedIds;

["TRANSPORT", 3, format["Transport %1 dismounted %2 groups at waypoint %3", 
    _transportGroupId, _detached, _dismountIdx]] call FLO_fnc_log;

true
