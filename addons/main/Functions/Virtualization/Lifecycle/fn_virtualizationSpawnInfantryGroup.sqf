/*
 * Function: FLO_fnc_virtualizationSpawnInfantryGroup
 */

params ["_groupId", "_position", "_side", "_groupCfg", "_unitCount", "_unitPool", "_sideKey"];

private _realGroup = grpNull;

if (_groupCfg isEqualType [] && {_groupCfg isNotEqualTo []}) then {
    private _selectedCfg = selectRandom _groupCfg;
    if (isClass _selectedCfg) then {
        _realGroup = [_position, _side, _selectedCfg] call BIS_fnc_spawnGroup;
    };
};

if (isNull _realGroup || {(units _realGroup) isEqualTo []}) then {
    [_unitPool, "units", _sideKey, "infantry"] call FLO_fnc_virtualizationRequirePoolEntries;
    if (!isNull _realGroup) then {
        deleteGroup _realGroup;
    };
    _realGroup = [_side, _groupId, "infantry"] call FLO_fnc_virtualizationCreateRealGroup;
    if (isNull _realGroup) exitWith { grpNull };

    private _spawnCount = [6, _unitCount] select (_unitCount > 0);
    private _spawnFailed = false;
    for "_i" from 1 to _spawnCount do {
        private _unitType = selectRandom _unitPool;
        private _spawnPos = [_position, 5, 20, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
        private _unit = _realGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];
        if (isNull _unit) exitWith {
            _spawnFailed = true;
        };
    };

    if (_spawnFailed) exitWith {
        { deleteVehicle _x; } forEach units _realGroup;
        deleteGroup _realGroup;
        _realGroup = grpNull;
    };
};

if (!isNull _realGroup && {(units _realGroup) isEqualTo []}) then {
    deleteGroup _realGroup;
    _realGroup = grpNull;
};

_realGroup
