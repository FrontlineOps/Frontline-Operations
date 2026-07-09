/*
 * Function: FLO_fnc_virtualizationSpawnFromComposition
 */

params ["_groupId", "_side", "_groupType", "_position", "_comp", "_groupData"];

private _spawnParkedHelicopters = _groupType == "helicopter"
    && { (_groupData get "waypoints") isEqualTo [] }
    && { (_groupData get "missionLock") == "" }
    && { (_groupData get "replacementState") == "" }
    && { !(_groupData get "engagementActive") }
    && { ([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) isEqualTo [] }
    && { (_groupData get "state") == "idle" || { _groupData get "transportRole" } };

private _realGroup = [_side, _groupId, _groupType] call FLO_fnc_virtualizationCreateRealGroup;
if (isNull _realGroup) exitWith { grpNull };

{
    private _spawnPos = if (_spawnParkedHelicopters && { _x isKindOf "Helicopter" }) then {
        [_position, _x, _forEachIndex, 600] call FLO_fnc_virtualizationResolveIdleHelicopterParkPos
    } else {
        _position
    };
    [_realGroup, _x, _spawnPos, _side, _groupType, _spawnParkedHelicopters] call FLO_fnc_activateSavedVirtualGroup;
} forEach _comp;

if ((units _realGroup) isEqualTo []) exitWith {
    deleteGroup _realGroup;
    grpNull
};

_realGroup
