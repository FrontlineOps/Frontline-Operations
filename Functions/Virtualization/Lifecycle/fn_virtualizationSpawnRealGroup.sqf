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

switch (true) do {
    case (_groupType isEqualTo "infantry"): {
        _realGroup = [_position, _side, _groupCfg, _unitCount, _pools get "groundInfantryUnits", _pools get "sideKey"] call FLO_fnc_virtualizationSpawnInfantryGroup;
    };

    case (_groupType in ["civilian", "civ_pedestrian", "civ_building"]): {
        _realGroup = [_groupId, _groupData, _position] call FLO_fnc_activateCivilian;
    };

    case (_groupType in ["motorized", "mechanized", "armor", "mobile_aa"]): {
        _realGroup = [_groupId, _position, _side, _unitCount, _groupType, _pools] call FLO_fnc_virtualizationSpawnGroundCombatGroup;
    };

    case (_comp isNotEqualTo []): {
        _realGroup = [_side, _groupType, _position, _comp] call FLO_fnc_virtualizationSpawnFromComposition;
    };

    case (_groupType in ["helicopter", "jet", "air"]): {
        _realGroup = [_position, _side, _unitCount, _groupType, _pools] call FLO_fnc_virtualizationSpawnAirGroup;
    };

    case (_groupType isEqualTo "artillery"): {
        _realGroup = [_groupId, _position, _side, _unitCount, _pools] call FLO_fnc_virtualizationSpawnArtilleryGroup;
    };

    case (_groupType isEqualTo "static_aa"): {
        _realGroup = [_groupId, _groupData, _position, _side, _unitCount, _pools] call FLO_fnc_virtualizationSpawnStaticAAGroup;
    };

    case (_groupType in ["civilianVehicle", "civ_car"]): {
        _realGroup = [_groupId, _groupData, _position] call FLO_fnc_activateCivilian;
    };

    default {
        throw format ["[VIRTUALIZATION] Unknown group type %1 for virtual group %2", _groupType, _groupId];
    };
};

_realGroup
