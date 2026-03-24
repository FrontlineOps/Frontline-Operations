/*
 * Function: FLO_fnc_transportDetachAll
 * Author: Frontline Operations Development Group
 * Description:
 *   Detach all infantry groups from a transport.
 *   Distributes groups in radial pattern to prevent stacking.
 *
 * Arguments:
 *   0: Transport Group ID <STRING>
 *
 * Return Value:
 *   Number of groups detached <NUMBER>
 *
 * Example:
 *   ["vgroup_456"] call FLO_fnc_transportDetachAll;
 */

params [["_transportGroupId", "", [""]]];

if (_transportGroupId == "") exitWith { 0 };

private _transData = [_transportGroupId] call FLO_fnc_transportGetTrackedGroup;

private _attached = [_transData] call FLO_fnc_virtualizationGetTransportPassengers;
private _count = count _attached;

if (_count == 0) exitWith { 0 };

private _detached = 0;
{
    private _dir = (360 / _count) * _forEachIndex;
    if ([_x, _dir] call FLO_fnc_transportDetach) then {
        _detached = _detached + 1;
    };
} forEach +_attached;

["TRANSPORT", 3, format["Detached %1 groups from transport %2", _detached, _transportGroupId]] call FLO_fnc_log;

_detached
