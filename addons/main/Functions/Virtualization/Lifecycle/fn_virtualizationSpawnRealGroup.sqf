/*
 * Function: FLO_fnc_virtualizationSpawnRealGroup
 */

params ["_groupId", "_groupData", "_position", "_pools"];

private _groupType = _groupData get "groupType";
private _side = _groupData get "side";
private _groupCfg = _groupData get "groupCfg";
private _comp = _groupData get "comp";
private _unitCount = _groupData get "unitCount";
private _realGroup = grpNull;
private _archetype = [_groupType] call FLO_fnc_virtualizationGetArchetype;
private _spawnKind = _archetype get "spawnKind";

if ((_archetype get "compositionPreemptsSpawn") && {_comp isNotEqualTo []}) exitWith {
    [_groupId, _side, _groupType, _position, _comp, _groupData] call FLO_fnc_virtualizationSpawnFromComposition
};

switch (_spawnKind) do {
    case "INFANTRY": {
        _realGroup = [_groupId, _position, _side, _groupCfg, _unitCount, _pools get "groundInfantryUnits", _pools get "sideKey"] call FLO_fnc_virtualizationSpawnInfantryGroup;
    };

    case "CIVILIAN";
    case "CIVILIAN_VEHICLE": {
        _realGroup = [_groupId, _groupData, _position] call FLO_fnc_activateCivilian;
    };

    case "GROUND": {
        _realGroup = [_groupId, _position, _side, _unitCount, _groupType, _pools] call FLO_fnc_virtualizationSpawnGroundCombatGroup;
    };

    case "AIR": {
        _realGroup = [_groupId, _position, _side, _unitCount, _groupType, _pools, _groupData] call FLO_fnc_virtualizationSpawnAirGroup;
    };

    case "ARTILLERY": {
        _realGroup = [_groupId, _position, _side, _unitCount, _pools] call FLO_fnc_virtualizationSpawnArtilleryGroup;
    };

    case "STATIC_AA": {
        _realGroup = [_groupId, _groupData, _position, _side, _unitCount, _pools] call FLO_fnc_virtualizationSpawnStaticAAGroup;
    };

    default {
        throw format [
            "[VIRTUALIZATION] Archetype %1 requires a composition for virtual group %2",
            _groupType,
            _groupId
        ];
    };
};

_realGroup
