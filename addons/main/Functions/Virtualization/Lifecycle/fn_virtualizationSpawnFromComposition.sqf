/*
 * Function: FLO_fnc_virtualizationSpawnFromComposition
 */

params ["_groupId", "_side", "_groupType", "_position", "_comp", "_groupData"];

private _spawnParkedHelicopters = _groupType == "helicopter"
    && { (_groupData get "waypoints") isEqualTo [] }
    && { (_groupData get "missionLock") == "" }
    && { (_groupData get "replacementState") == "" }
    && { ([_groupData] call FLO_fnc_virtualizationGetTransportPassengers) isEqualTo [] }
    && { (_groupData get "state") == "idle" || { _groupData get "transportRole" } };

private _realGroup = [_side, _groupId, _groupType] call FLO_fnc_virtualizationCreateRealGroup;
if (isNull _realGroup) exitWith { grpNull };

private _spawnFailed = false;
{
    if (_spawnFailed) then { continue };
    private _spawnPos = if (_spawnParkedHelicopters && { _x isKindOf "Helicopter" }) then {
        [_position, _x, _forEachIndex, 600] call FLO_fnc_virtualizationResolveIdleHelicopterParkPos
    } else {
        _position
    };
    private _created = [_realGroup, _x, _spawnPos, _side, _groupType, _spawnParkedHelicopters] call FLO_fnc_activateSavedVirtualGroup;
    if (isNull _created) then {
        _spawnFailed = true;
    };
} forEach _comp;

if (_spawnFailed) exitWith {
    [_groupData, _realGroup, false] call FLO_fnc_virtualizationDeleteRealGroupAssets;
    grpNull
};

if ((units _realGroup) isEqualTo []) exitWith {
    deleteGroup _realGroup;
    grpNull
};

_realGroup
