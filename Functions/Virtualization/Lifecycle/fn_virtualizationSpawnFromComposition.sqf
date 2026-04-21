/*
 * Function: FLO_fnc_virtualizationSpawnFromComposition
 */

params ["_side", "_groupType", "_position", "_comp", "_groupData"];

private _spawnParkedHelicopters = _groupType == "helicopter"
    && { count (_groupData get "waypoints") == 0 }
    && { (_groupData get "missionLock") == "" }
    && { (_groupData get "replacementState") == "" }
    && { !(_groupData get "engagementActive") }
    && { count ([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) == 0 }
    && { (_groupData get "state") == "idle" || { _groupData get "transportRole" } };

private _realGroup = createGroup [_side, true];
{
    private _spawnPos = if (_spawnParkedHelicopters && { _x isKindOf "Helicopter" }) then {
        [_position, _x, _forEachIndex, 600] call FLO_fnc_virtualizationResolveIdleHelicopterParkPos
    } else {
        _position
    };
    [_realGroup, _x, _spawnPos, _side, _groupType, _spawnParkedHelicopters] call FLO_fnc_activateSavedVirtualGroup;
} forEach _comp;

_realGroup
